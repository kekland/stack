import 'dart:async';

import 'package:stack/stack.dart';

ValueMutation<T, TArg> mutation<T, TArg>(
  FutureOr<T> Function(TArg) mutate, {
  (T oldValue, T newValue)? Function(TArg)? optimisticUpdate,
}) {
  return ValueMutation<T, TArg>(
    mutate,
    optimisticUpdate: optimisticUpdate,
  );
}

class ValueMutation<T, TArg> {
  ValueMutation(this.mutate, {this.optimisticUpdate}) {
    _dispatcher = di.maybeDispatcherFor<T>();
  }

  final FutureOr<T> Function(TArg) mutate;
  final (T oldValue, T newValue)? Function(TArg)? optimisticUpdate;
  late final ValueDispatcher<T>? _dispatcher;

  final _executing = <TArg, Completer<T>>{};

  Future<T> call(TArg arg) async {
    if (_executing.containsKey(arg)) return _executing[arg]!.future;

    final completer = Completer<T>();
    _executing[arg] = completer;

    T? revertValue;

    try {
      if (optimisticUpdate != null) {
        final optimisticResult = optimisticUpdate!(arg);

        if (optimisticResult != null) {
          _dispatcher?.dispatchUpdate(null, optimisticResult.$2);
          revertValue = optimisticResult.$1;
        }
      }

      final result = await mutate(arg);
      completer.complete(result);

      _dispatcher?.dispatchUpdate(null, result);
      return result;
    } catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
      if (revertValue != null) _dispatcher?.dispatchUpdate(null, revertValue);

      rethrow;
    } finally {
      _executing.remove(arg);
    }
  }
}
