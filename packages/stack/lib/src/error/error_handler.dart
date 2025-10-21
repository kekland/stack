import 'package:stack/stack.dart';

typedef ErrorHandlerFn = void Function(DecodedError error);

late final ErrorHandlerFn globalErrorHandler;

void handleError(Object exception, StackTrace? stackTrace) {
  final decoded = DecodedError.decode(exception, stackTrace);
  globalErrorHandler(decoded);
}
