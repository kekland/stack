import 'package:get_it/get_it.dart';

final di = DiContainer();

class DiContainer {
  GetIt get i => GetIt.instance;

  T get<T extends Object>() => i.get<T>();
  T call<T extends Object>() => get<T>();
}
