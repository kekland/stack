import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

abstract class Service with Disposable {
  Service({required this.logger});

  final Logger logger;

  @mustCallSuper
  Future<void> initialize() async {
    await Future.microtask(() => di.signalReady(this));
  }

  Future<T> method<T>(Future<T> Function() fn) => serviceMethodAsync(logger, fn);
  T methodSync<T>(T Function() fn) => serviceMethodSync(logger, fn);
}

/// A global error handler for service errors.
void Function(Object e, StackTrace stackTrace)? serviceErrorHandler;

T serviceMethodSync<T>(Logger logger, T Function() call) {
  return logger.wrap(() {
    try {
      return call();
    } catch (e, stackTrace) {
      serviceErrorHandler?.call(e, stackTrace);
      rethrow;
    }
  }, level: 2);
}

Future<T> serviceMethodAsync<T>(Logger logger, Future<T> Function() call) async {
  return logger.wrapAsync(() async {
    try {
      return await call();
    } catch (e, stackTrace) {
      serviceErrorHandler?.call(e, stackTrace);
      rethrow;
    }
  }, level: 2);
}
