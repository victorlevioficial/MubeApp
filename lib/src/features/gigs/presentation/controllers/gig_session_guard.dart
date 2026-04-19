import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../utils/app_logger.dart';
import '../../../auth/data/auth_repository.dart';

class GigSessionGuard {
  const GigSessionGuard._();

  static const String _appCheckFailureMessage =
      'Falha na validação de segurança do app. Feche e abra o app e tente novamente.';

  static Future<T> run<T>(
    Ref ref, {
    required String operationLabel,
    required Future<T> Function() action,
  }) async {
    final authRepository = ref.read(authRepositoryProvider);

    final precheckFailure = await _ensureSecurityContext(
      authRepository,
      operationLabel: operationLabel,
    );
    if (precheckFailure != null) {
      await _finalizeFailure(
        authRepository,
        precheckFailure,
        operationLabel: operationLabel,
      );
      throw precheckFailure;
    }

    try {
      return await action();
    } catch (error, stackTrace) {
      if (!isRecoverableSecurityContextError(error)) {
        rethrow;
      }

      AppLogger.warning(
        'Gig action security context failure on $operationLabel. '
        'Refreshing session and retrying once.',
        error,
        stackTrace,
        false,
      );

      final refreshFailure = await _refreshSecurityContext(
        authRepository,
        operationLabel: operationLabel,
      );
      if (refreshFailure != null) {
        await _finalizeFailure(
          authRepository,
          refreshFailure,
          operationLabel: operationLabel,
        );
        throw refreshFailure;
      }

      try {
        return await action();
      } catch (retryError, retryStackTrace) {
        if (!isRecoverableSecurityContextError(retryError)) {
          rethrow;
        }

        final mappedFailure = mapSecurityContextFailure(retryError);
        AppLogger.error(
          'Gig action security context failure persisted after refresh: '
          '$operationLabel',
          retryError,
          retryStackTrace,
        );
        await _finalizeFailure(
          authRepository,
          mappedFailure,
          operationLabel: operationLabel,
        );
        throw mappedFailure;
      }
    }
  }

  static bool isRecoverableSecurityContextError(Object error) {
    if (error is Failure) {
      return _isSessionFailureText(
        [error.message, error.debugMessage ?? ''].join(' '),
      );
    }

    final code = _normalizedErrorCode(error);
    if (code == 'unauthenticated') return true;

    return _messageMentionsAppCheck(error) &&
        (code == 'permission-denied' || code == 'failed-precondition');
  }

  static Failure mapSecurityContextFailure(Object error) {
    if (error is Failure) {
      return error;
    }

    if (_messageMentionsAppCheck(error)) {
      return ServerFailure(
        message: _appCheckFailureMessage,
        debugMessage: 'app-check-auth-context-failure',
        originalError: error,
      );
    }

    return AuthFailure(
      message: 'Sua sessão expirou. Faça login novamente.',
      debugMessage: 'firestore-unauthenticated',
      originalError: error,
    );
  }

  static Future<Failure?> _ensureSecurityContext(
    AuthRepository authRepository, {
    required String operationLabel,
  }) async {
    final currentUser = authRepository.currentUser;
    if (currentUser == null) {
      AppLogger.warning(
        'Gig action precheck: no FirebaseAuth user for $operationLabel. '
        'Refreshing security context.',
      );
      return _refreshSecurityContext(
        authRepository,
        operationLabel: operationLabel,
      );
    }

    try {
      final idToken = await currentUser.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        return null;
      }

      AppLogger.warning(
        'Gig action precheck: empty FirebaseAuth token for $operationLabel. '
        'Refreshing security context.',
      );
      return _refreshSecurityContext(
        authRepository,
        operationLabel: operationLabel,
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Gig action precheck: failed to read FirebaseAuth token for '
        '$operationLabel. Refreshing security context.',
        error,
        stackTrace,
        false,
      );
      return _refreshSecurityContext(
        authRepository,
        operationLabel: operationLabel,
      );
    }
  }

  static Future<Failure?> _refreshSecurityContext(
    AuthRepository authRepository, {
    required String operationLabel,
  }) async {
    final refreshResult = await authRepository.refreshSecurityContext();
    if (refreshResult.isRight()) {
      AppLogger.info(
        'Gig security context refresh succeeded ($operationLabel).',
      );
      return null;
    }

    final failure = refreshResult.fold(
      (failure) => failure,
      (_) => throw StateError('Expected refresh security context failure'),
    );
    AppLogger.warning(
      'Gig security context refresh failed ($operationLabel): '
      '${failure.message} ${failure.debugMessage ?? ''}',
    );
    return failure;
  }

  static Future<void> _finalizeFailure(
    AuthRepository authRepository,
    Failure failure, {
    required String operationLabel,
  }) async {
    if (!_shouldForceSignOut(failure)) {
      return;
    }

    AppLogger.warning(
      'Signing out after gig security context failure ($operationLabel): '
      '${failure.debugMessage ?? failure.message}',
    );
    await authRepository.signOut();
  }

  static bool _shouldForceSignOut(Failure failure) {
    final normalized = [
      failure.message,
      failure.debugMessage ?? '',
    ].join(' ').toLowerCase();

    return normalized.contains('session-expired') ||
        normalized.contains('sessão expirou') ||
        normalized.contains('sessao expirou') ||
        normalized.contains('user-token-expired') ||
        normalized.contains('invalid-user-token') ||
        normalized.contains('user-disabled') ||
        normalized.contains('unauthenticated');
  }

  static bool _messageMentionsAppCheck(Object error) {
    return _normalizedErrorMessage(error).contains('app check');
  }

  static bool _isSessionFailureText(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('session-expired') ||
        normalized.contains('sessão expirou') ||
        normalized.contains('sessao expirou') ||
        normalized.contains('user-token-expired') ||
        normalized.contains('invalid-user-token') ||
        normalized.contains('user-disabled') ||
        normalized.contains('unauthenticated') ||
        normalized.contains('valid authentication credentials');
  }

  static String _normalizedErrorCode(Object error) {
    if (error is FirebaseException) {
      return error.code.toLowerCase();
    }

    if (error is PlatformException) {
      final normalizedMessage = _normalizedErrorMessage(error);
      if (_isSessionFailureText(normalizedMessage)) {
        return 'unauthenticated';
      }
      if (normalizedMessage.contains('permission-denied') ||
          normalizedMessage.contains('permission denied')) {
        return 'permission-denied';
      }
      if (normalizedMessage.contains('failed-precondition') ||
          normalizedMessage.contains('failed precondition')) {
        return 'failed-precondition';
      }
      return error.code.toLowerCase();
    }

    return '';
  }

  static String _normalizedErrorMessage(Object error) {
    if (error is FirebaseException) {
      return [
        error.message ?? '',
        error.code,
        error.plugin,
      ].join(' ').toLowerCase();
    }

    if (error is PlatformException) {
      return [
        error.message ?? '',
        error.details?.toString() ?? '',
        error.code,
        error.toString(),
      ].join(' ').toLowerCase();
    }

    return error.toString().toLowerCase();
  }
}
