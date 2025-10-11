import 'dart:async';

import 'package:stack/stack.dart';

/// An event representing a change to a value.
abstract class ValueEvent<T> {
  ValueEvent(this.source);
  final Object? source;

  Object get id;
}

/// An event that is fired when the value is fetched (from an external source). Value must reflect the most up-to-date
/// state of the value.
class ValueFetchEvent<T> extends ValueEvent<T> {
  ValueFetchEvent(super.source, this.id, this.value);

  @override
  final Object id;
  final T value;
}

/// An event that is fired when the value is created.
class ValueCreateEvent<T> extends ValueEvent<T> {
  ValueCreateEvent(super.source, this.id, this.value);

  @override
  final Object id;
  final T value;
}

/// An event that is fired when the value is updated.
class ValueUpdateEvent<T> extends ValueEvent<T> {
  ValueUpdateEvent(super.source, this.id, this.value);

  @override
  final Object id;
  final T value;
}

/// An event that is fired when the value is deleted.
class ValueDeleteEvent<T> extends ValueEvent<T> {
  ValueDeleteEvent(super.source, this.id, this.value);

  @override
  final Object id;
  final T? value;
}

/// A value dispatcher ties together [ValueEvent] events with [ValueSource]/[ValueProxy]s or other systems that need to
/// respond to global changes to a value.
///
/// This is used to, for example, sync together multiple value sources that represent the same underlying data.
abstract class ValueDispatcher<T> with Disposable {
  ValueDispatcher();

  late final _eventStreamController = $streamControllerBroadcast<ValueEvent<T>>();
  Stream<ValueEvent<T>> get eventStream => _eventStreamController.stream;
  Stream<ValueEvent<T>> eventStreamForValue(T value) => eventStream.where((event) => event.id == identify(value));
  Stream<ValueEvent<T>> eventStreamForId(Object id) => eventStream.where((event) => event.id == id);
  Stream<ValueEvent<T>> eventStreamIgnoringSource(Object source) => eventStream.where((e) => e.source != source);

  /// Returns an identifier for the given value.
  Object identify(T value);

  /// Creates a proxy for a given value.
  ValueProxy<T> createProxy(T value);

  ValueProxy<T>? fork(String id) {
    final value = this[id];
    if (value != null) return createProxy(value);
    return null;
  }

  final _proxies = <Object, List<ValueProxy<T>>>{};

  void bind(ValueProxy<T> proxy) {
    final id = proxy.id;
    final list = _proxies[id] ??= [];
    list.add(proxy);
  }

  void unbind(ValueProxy<T> proxy) {
    final id = proxy.id;
    final list = _proxies[id];
    assert(list != null && list.contains(proxy), 'Trying to unbind a proxy that is not bound');

    list!.remove(proxy);
    if (list.isEmpty) _proxies.remove(id);
  }

  T? operator [](Object id) {
    final list = _proxies[id];
    return list?.first.value;
  }

  /// Dispatches the given event to all listeners.
  void dispatch(ValueEvent<T> event) {
    _eventStreamController.add(event);
  }

  void dispatchFetch(Object? source, T value) => dispatch(ValueFetchEvent<T>(source, identify(value), value));
  void dispatchCreate(Object? source, T value) => dispatch(ValueCreateEvent<T>(source, identify(value), value));
  void dispatchUpdate(Object? source, T value) => dispatch(ValueUpdateEvent<T>(source, identify(value), value));
  void dispatchDelete(Object? source, T value) => dispatchDeleteId(source, identify(value), value);
  void dispatchDeleteId(Object? source, Object id, [T? value]) => dispatch(ValueDeleteEvent<T>(source, id, value));

  // -------------------------------------------------------------------
  // Mutations
  // -------------------------------------------------------------------
  final _mutationCompleters = <(Object, Object), Completer>{};
  void _dispatchMutationResult<TReturn>(TReturn value) {
    if (value is T) {
      dispatchUpdate(this, value);
    } else if (value is List<T>) {
      for (final v in value) dispatchUpdate(this, v);
    } else {
      stackLogger.warning('Automatically dispatching mutation result of type $TReturn failed: cannot unwrap into $T');
    }
  }

  /// A mutation is a function that can be called to "modify" something.
  ///
  /// The return result of a mutation will be propagated automatically to the dispatcher if the return type is either
  /// [T] or [List<T>], and [automaticallyDispatchUpdates] is set to `true`.
  ///
  /// Optimistic (or eager) updates are also supported by passing `optimisticUpdate`. Since optimistic updates only
  /// work on data that exists locally, you can try to get the data by using `this[]`. If there's no local data, it's
  /// safe to return `null` - this will ignore the optimistic update.
  ///
  /// [disallowConcurrent] is set to `true` by default and will block calls to this mutation with the same [operationId]
  /// and [args] if there's already an ongoing mutation (it'll return the same `Future` instance). If set to `false`,
  /// multiple mutations with the same args can be executed simultaneously.
  /// 
  /// The way to implement mutations in your dispatchers is something like this:
  /// 
  /// ```dart
  /// Future<Post> like(String postId) {
  ///   return $mutation(
  ///     #like,
  ///     (postId),
  ///     () async {
  ///       final newPost = await myApi.likePost(postId);
  ///       return newPost;
  ///     },
  ///     optimisticUpdate: () {
  ///       final existingPost = this[postId];
  ///       if (existingPost != null) return (existingPost, existingPost.copyWith(isLiked: true));
  ///       return null;
  ///     }
  ///   );
  /// }
  /// ```
  Future<TReturn> $mutation<TReturn>(
    Object operationId,
    Object args,
    Future<TReturn> Function() mutate, {
    (TReturn oldValue, TReturn newValue)? Function()? optimisticUpdate,
    bool disallowConcurrent = true,
    bool automaticallyDispatchUpdates = true,
  }) async {
    final mutationKey = (operationId, args);
    void maybeDispatchMutationResult(TReturn value) {
      if (automaticallyDispatchUpdates) _dispatchMutationResult(value);
    }

    // First, if we disallowed concurrent executions, check if we have a pending completer
    if (disallowConcurrent) {
      final completer = _mutationCompleters[mutationKey];
      if (completer != null) return completer.future as Future<TReturn>;
    }

    // If all good, continue with the mutation. We'll set up the completer - if we disallowed concurrent execution.
    // Otherwise, there's no need for a completer.
    final Completer<TReturn>? completer;
    if (disallowConcurrent) {
      completer = Completer<TReturn>();
      _mutationCompleters[mutationKey] = completer;
    }
    else {
      completer = null;
    }

    // A value for optimistic updates that we will revert to in case of an error.
    // We will execute the optimistic update first. If it fails, we'll "swallow" the error, and continue with the
    // regular mutation.
    TReturn? revertValue;

    if (optimisticUpdate != null) {
      try {
        final optimisticResult = optimisticUpdate();
        if (optimisticResult != null) {
          revertValue = optimisticResult.$1;
          maybeDispatchMutationResult(optimisticResult.$2);
        }
      } catch (e) {
        stackLogger.warning('Optimistic update for $operationId failed with: $e. Ignoring.');
      }
    }

    // After optimistic updates, proceed with regular mutation.
    try {
      final result = await mutate();

      completer?.complete(result);
      maybeDispatchMutationResult(result);

      return result;
    } catch (e, stackTrace) {
      completer?.completeError(e, stackTrace);
      if (revertValue != null) {
        maybeDispatchMutationResult(revertValue);
      }

      rethrow;
    } finally {
      _mutationCompleters.remove(mutationKey);
    }
  }
}
