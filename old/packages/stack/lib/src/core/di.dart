import 'package:get_it/get_it.dart';
import 'value_dispatcher.dart';

final di = DiContainer();

class DiContainer {
  GetIt get i => GetIt.instance;

  T get<T extends Object>() => i.get<T>();
  T call<T extends Object>() => get<T>();
}

extension StackDiExtensions on GetIt {
  ValueDispatcher<T> dispatcherFor<T>() => get<ValueDispatcher<T>>();
  ValueDispatcher<T>? maybeDispatcherFor<T>() => isRegistered<ValueDispatcher<T>>() ? get<ValueDispatcher<T>>() : null;
}
