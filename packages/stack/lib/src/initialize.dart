import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

final belowNavigatorKey = GlobalKey();
BuildContext get belowNavigatorContext => belowNavigatorKey.currentContext!;

Future<void> stackInitialize({
  required ErrorDecoderFn errorDecoder,
  required ErrorHandlerFn errorHandler,
}) async {
  SignalsObserver.instance = LoggerSignalsObserver();
  globalErrorDecoder = errorDecoder;
  globalErrorHandler = errorHandler;

  if (kDebugMode) {
    Logger.root.level = Level.FINER;
    Logger.root.onRecord.listen(logColorized);
  } else {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });
  }
}
