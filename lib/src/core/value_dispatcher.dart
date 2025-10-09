import 'package:stack/src/core/value_proxy.dart';
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
}
