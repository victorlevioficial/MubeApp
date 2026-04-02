import 'error_handler.dart';
import 'failures.dart';

String resolveErrorMessage(Object error) {
  final failure = ErrorHandler.handle(error);
  if (failure is! UnknownFailure) {
    return failure.message;
  }

  final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
  final rawMessageLower = rawMessage.toLowerCase();

  if (rawMessageLower == 'not_found' ||
      rawMessageLower == 'not-found' ||
      rawMessageLower.contains('[firebase_functions/not-found]') ||
      rawMessageLower.contains('firebase_functions/not-found')) {
    return 'Servico solicitado indisponivel no servidor. Atualize o aplicativo e tente novamente.';
  }

  if (rawMessage.isNotEmpty && rawMessage != 'Exception') {
    return rawMessage;
  }

  return failure.message;
}
