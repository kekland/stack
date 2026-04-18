import 'package:flutter/foundation.dart';
import 'package:stack/stack.dart';

/// A service is a long-lived object that is located in the dependency injection container.
abstract class Service with Disposable, MethodExtension {
  Service({required this.logger});

  @override
  final Logger logger;

  @mustCallSuper
  Future<void> initialize() async {
    logger.fine('Initialized');
    await Future.microtask(() => di.i.signalReady(this));
  }

  @override
  void handleMethodError(Object exception, StackTrace? stackTrace) {
    handleError(exception, stackTrace);
  }
}
