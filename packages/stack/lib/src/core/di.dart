import 'package:get_it/get_it.dart';
import 'package:stack/src/core/value_dispatcher.dart';

final di = GetIt.instance;

extension StackDiExtensions on GetIt {
  ValueDispatcher<T> dispatcherFor<T>() => get<ValueDispatcher<T>>();
  ValueDispatcher<T>? maybeDispatcherFor<T>() => isRegistered<ValueDispatcher<T>>() ? get<ValueDispatcher<T>>() : null;
}
