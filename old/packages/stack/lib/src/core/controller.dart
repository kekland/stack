import '../../stack.dart';

abstract class Controller with Disposable {
  Controller([Logger? logger]): logger = logger ?? Logger($name);

  final Logger logger;

  String get $name;
}
