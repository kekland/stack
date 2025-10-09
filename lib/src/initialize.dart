import 'package:flutter/foundation.dart';
import 'package:stack/stack.dart';

Future<void> stackInitialize() async {
  SignalsObserver.instance = LoggerSignalsObserver();

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
