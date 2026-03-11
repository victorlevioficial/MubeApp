import '../../../core/errors/error_handler.dart';
import '../../../core/errors/failures.dart';

String resolveGigErrorMessage(Object error) {
  final failure = ErrorHandler.handle(error);
  if (failure is! UnknownFailure) {
    return failure.message;
  }

  final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
  if (rawMessage.isNotEmpty && rawMessage != 'Exception') {
    return rawMessage;
  }

  return failure.message;
}
