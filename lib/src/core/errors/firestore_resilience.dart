import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/app_logger.dart';
import 'failure_mapper.dart';

typedef FirestoreFinalErrorMapper = Object Function(FirebaseException error);

class FirestoreResilience {
  const FirestoreResilience(this._scope);

  static const int _maxRetryAttempts = 3;

  final String _scope;

  bool _isTransientFirestoreError(FirebaseException error) {
    final code = error.code.toLowerCase();
    return code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'aborted';
  }

  Duration _retryDelayForAttempt(int attempt) {
    return Duration(milliseconds: 350 * attempt);
  }

  Object _defaultFinalError(FirebaseException error) {
    return Exception(mapExceptionToFailure(error).message);
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
          AppLogger.error(
            '$_scope Firestore request failed: $operationLabel',
            error,
            stackTrace,
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

    throw Exception('Nao foi possivel concluir a operacao agora.');
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
          AppLogger.error(
            '$_scope Firestore stream failed: $operationLabel',
            error,
            stackTrace,
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
