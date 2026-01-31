import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import 'failures.dart';

/// Maps exceptions to typed [Failure] objects.
///
/// Use this in repository catch blocks to convert exceptions
/// into user-friendly failures with proper categorization.
///
/// Example:
/// ```dart
/// catch (e) {
///   return Left(mapExceptionToFailure(e));
/// }
/// ```
Failure mapExceptionToFailure(Object error, [StackTrace? stackTrace]) {
  // Network errors
  if (error is SocketException) {
    return NetworkFailure.noConnection();
  }
  if (error is TimeoutException) {
    return NetworkFailure.timeout();
  }

  // Firebase errors
  if (error is FirebaseException) {
    return _mapFirebaseException(error);
  }

  // Format/parsing errors
  if (error is FormatException) {
    return ValidationFailure(
      message: 'Dados em formato inválido.',
      debugMessage: error.message,
      originalError: error,
    );
  }

  // Type errors (usually parsing issues)
  if (error is TypeError) {
    return ValidationFailure(
      message: 'Erro ao processar dados.',
      debugMessage: error.toString(),
      originalError: error,
    );
  }

  // Fallback to unknown failure
  return UnknownFailure(
    message: 'Algo deu errado. Tente novamente.',
    debugMessage: error.toString(),
    originalError: error,
  );
}

/// Maps Firebase-specific exceptions to typed Failures.
Failure _mapFirebaseException(FirebaseException e) {
  return switch (e.code) {
    // Permission errors
    'permission-denied' => PermissionFailure.firestore(),
    'unauthenticated' => AuthFailure.sessionExpired(),

    // Not found
    'not-found' => const ServerFailure(
      message: 'Recurso não encontrado.',
      debugMessage: 'not-found',
    ),

    // Network/availability errors
    'unavailable' => NetworkFailure.serverError(),
    'deadline-exceeded' => NetworkFailure.timeout(),

    // Rate limiting
    'resource-exhausted' => const ServerFailure(
      message: 'Muitas requisições. Aguarde um momento.',
      debugMessage: 'resource-exhausted',
    ),

    // Storage errors
    'object-not-found' => const StorageFailure(
      message: 'Arquivo não encontrado.',
      debugMessage: 'object-not-found',
    ),
    'unauthorized' => PermissionFailure.gallery(),
    'quota-exceeded' => StorageFailure.quotaExceeded(),

    // Auth errors (redirect to AuthFailure)
    'user-not-found' => AuthFailure.userNotFound(),
    'wrong-password' => AuthFailure.wrongPassword(),
    'email-already-in-use' => AuthFailure.emailAlreadyInUse(),
    'invalid-email' => AuthFailure.invalidEmail(),
    'weak-password' => AuthFailure.weakPassword(),
    'user-disabled' => AuthFailure.userDisabled(),
    'too-many-requests' => AuthFailure.tooManyRequests(),

    // Default fallback
    _ => ServerFailure(
      message: e.message ?? 'Erro no servidor.',
      debugMessage: e.code,
      originalError: e,
    ),
  };
}
