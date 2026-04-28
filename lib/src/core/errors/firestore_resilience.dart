import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/app_logger.dart';
import 'failure_mapper.dart';

typedef FirestoreFinalErrorMapper = Object Function(FirebaseException error);

bool isTransientFirestoreCode(String code) {
  final normalizedCode = code.toLowerCase();
  return normalizedCode == 'unavailable' ||
      normalizedCode == 'deadline-exceeded' ||
      normalizedCode == 'aborted';
}

bool isExpectedAuthContextFirestoreCode(String code) {
  final normalizedCode = code.toLowerCase();
  return normalizedCode == 'permission-denied' ||
      normalizedCode == 'unauthenticated';
}

bool isNonRecoverableFirestoreCode(String code) {
  final normalizedCode = code.toLowerCase();
  return isExpectedAuthContextFirestoreCode(normalizedCode) ||
      normalizedCode == 'invalid-argument' ||
      normalizedCode == 'failed-precondition' ||
      normalizedCode == 'not-found' ||
      normalizedCode == 'already-exists';
}

class RecoverableFirestoreException implements Exception {
  const RecoverableFirestoreException({
    required this.message,
    this.code,
    this.originalError,
  });

  final String message;
  final String? code;
  final Object? originalError;

  @override
  String toString() => message;
}

Object recoverableFirestoreFinalError(FirebaseException error) {
  if (isNonRecoverableFirestoreCode(error.code)) {
    return Exception(mapExceptionToFailure(error).message);
  }
  return RecoverableFirestoreException(
    message: mapExceptionToFailure(error).message,
    code: error.code,
    originalError: error,
  );
}

bool isRecoverableFirestoreError(Object error) {
  if (error is RecoverableFirestoreException) {
    return true;
  }

  if (error is FirebaseException) {
    if (isNonRecoverableFirestoreCode(error.code)) {
      return false;
    }
    return isTransientFirestoreCode(error.code);
  }

  return false;
}

class FirestoreResilience {
  const FirestoreResilience(this._scope);

  static const int _maxRetryAttempts = 3;

  final String _scope;

  bool _isTransientFirestoreError(FirebaseException error) {
    return isTransientFirestoreCode(error.code);
  }

  Duration _retryDelayForAttempt(int attempt) {
    return Duration(milliseconds: 350 * attempt);
  }

  Object _defaultFinalError(FirebaseException error) {
    return Exception(mapExceptionToFailure(error).message);
  }

  void _logFinalFirestoreError({
    required String kind,
    required String operationLabel,
    required FirebaseException error,
    required StackTrace stackTrace,
  }) {
    final message = '$_scope Firestore $kind failed: $operationLabel';
    if (isExpectedAuthContextFirestoreCode(error.code)) {
      AppLogger.warning('$message (${error.code})', error, stackTrace, false);
      return;
    }

    AppLogger.error(message, error, stackTrace);
  }

  Future<T> run<T>(
    Future<T> Function() request, {
    required String operationLabel,
    FirestoreFinalErrorMapper? onFinalError,
  }) async {
    for (var attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        return await request();
      } on FirebaseException catch (error, stackTrace) {
        final shouldRetry =
            _isTransientFirestoreError(error) && attempt < _maxRetryAttempts;
        if (!shouldRetry) {
          _logFinalFirestoreError(
            kind: 'request',
            operationLabel: operationLabel,
            error: error,
            stackTrace: stackTrace,
          );
          throw (onFinalError ?? _defaultFinalError)(error);
        }

        final delay = _retryDelayForAttempt(attempt);
        AppLogger.warning(
          '$_scope Firestore request transient failure on '
          '$operationLabel (${error.code}). Retrying in '
          '${delay.inMilliseconds}ms.',
          error,
          stackTrace,
          false,
        );
        await Future<void>.delayed(delay);
      }
    }

    throw Exception('Não foi possível concluir a operação agora.');
  }

  Stream<T> watch<T>(
    Stream<T> Function() createStream, {
    required String operationLabel,
    FirestoreFinalErrorMapper? onFinalError,
  }) async* {
    var attempt = 0;

    while (true) {
      try {
        await for (final value in createStream()) {
          yield value;
        }
        return;
      } on FirebaseException catch (error, stackTrace) {
        final shouldRetry =
            _isTransientFirestoreError(error) &&
            attempt < (_maxRetryAttempts - 1);
        if (!shouldRetry) {
          _logFinalFirestoreError(
            kind: 'stream',
            operationLabel: operationLabel,
            error: error,
            stackTrace: stackTrace,
          );
          throw (onFinalError ?? _defaultFinalError)(error);
        }

        attempt += 1;
        final delay = _retryDelayForAttempt(attempt);
        AppLogger.warning(
          '$_scope Firestore stream transient failure on '
          '$operationLabel (${error.code}). Retrying in '
          '${delay.inMilliseconds}ms.',
          error,
          stackTrace,
          false,
        );
        await Future<void>.delayed(delay);
      }
    }
  }
}
