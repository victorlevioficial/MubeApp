import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'failures.dart';

/// Centralized error handler that converts exceptions to user-friendly Failures.
///
/// Usage:
/// ```dart
/// try {
///   await someOperation();
/// } catch (e) {
///   final failure = ErrorHandler.handle(e);
///   showSnackbar(failure.message);
/// }
/// ```
class ErrorHandler {
  /// Converts any exception to an appropriate Failure.
  static Failure handle(Object error, [StackTrace? stackTrace]) {
    // Log error for debugging
    _logError(error, stackTrace);

    // Firebase Auth errors
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }

    // Firebase Storage errors
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }

    // Socket/Network errors
    if (error is SocketException) {
      return NetworkFailure.noConnection();
    }

    // HTTP timeout
    if (error is HttpException) {
      return NetworkFailure.serverError();
    }

    // Format exceptions (validation)
    if (error is FormatException) {
      return ValidationFailure(
        message: 'Formato inválido.',
        debugMessage: error.message,
        originalError: error,
      );
    }

    // Already a Failure, just return it
    if (error is Failure) {
      return error;
    }

    // Unknown error
    return UnknownFailure(debugMessage: error.toString(), originalError: error);
  }

  /// Handles Firebase Auth specific errors.
  static Failure _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
        return AuthFailure.wrongPassword();
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse();
      case 'invalid-email':
        return AuthFailure.invalidEmail();
      case 'weak-password':
        return AuthFailure.weakPassword();
      case 'user-disabled':
        return AuthFailure.userDisabled();
      case 'too-many-requests':
        return AuthFailure.tooManyRequests();
      case 'expired-action-code':
      case 'invalid-action-code':
        return AuthFailure.sessionExpired();
      default:
        return AuthFailure(
          message: 'Erro de autenticação. Tente novamente.',
          debugMessage: error.code,
          originalError: error,
        );
    }
  }

  /// Handles Firebase (Storage, Firestore, etc.) errors.
  static Failure _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      // Storage errors
      case 'storage/unauthorized':
        return StorageFailure(
          message: 'Sem permissão para acessar este arquivo.',
          debugMessage: error.code,
          originalError: error,
        );
      case 'storage/canceled':
        return StorageFailure(
          message: 'Upload cancelado.',
          debugMessage: error.code,
          originalError: error,
        );
      case 'storage/quota-exceeded':
        return StorageFailure.quotaExceeded();
      case 'storage/retry-limit-exceeded':
        return NetworkFailure.timeout();

      // Generic Firebase errors
      case 'permission-denied':
        return StorageFailure(
          message: 'Sem permissão para esta operação.',
          debugMessage: error.code,
          originalError: error,
        );
      case 'unavailable':
        return NetworkFailure.serverError();
      default:
        return UnknownFailure(
          debugMessage: '${error.plugin}: ${error.code}',
          originalError: error,
        );
    }
  }

  /// Logs error for debugging (only in debug mode).
  static void _logError(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('ErrorHandler: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }
}
