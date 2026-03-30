import 'package:flutter/widgets.dart';

typedef ErrorDecoderFn = DecodedError? Function(Object exception, StackTrace? stackTrace);
typedef ErrorHandlerFn = void Function(DecodedError error);

late final ErrorDecoderFn globalErrorDecoder;
late final ErrorHandlerFn globalErrorHandler;

void handleError(Object exception, StackTrace? stackTrace) {
  final decoded = DecodedError.decode(exception, stackTrace);
  globalErrorHandler(decoded);
}

abstract class DecodedError {
  DecodedError({
    required this.exception,
    required this.stackTrace,
  });

  static DecodedError decode(Object exception, StackTrace? stackTrace) {
    final decoded = globalErrorDecoder(exception, stackTrace);
    return decoded ?? UnknownDecodedError(exception: exception, stackTrace: stackTrace);
  }

  final Object exception;
  final StackTrace? stackTrace;

  String get developerMessage;
  String resolveTitle(BuildContext context);
  String resolveSubtitle(BuildContext context);
}

class UnknownDecodedError extends DecodedError {
  UnknownDecodedError({
    required super.exception,
    required super.stackTrace,
  });

  @override
  String get developerMessage => 'An unknown error occurred: $exception';

  @override
  String resolveTitle(BuildContext context) => 'Unknown error';

  @override
  String resolveSubtitle(BuildContext context) => exception.toString();
}
