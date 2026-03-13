import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:flutter/foundation.dart';

import 'app_logger.dart';

enum AppCheckRefreshStatus {
  cachedTokenAvailable,
  forcedRefreshSucceeded,
  forcedRefreshSkippedByCooldown,
  throttled,
  failed,
}

extension AppCheckRefreshStatusX on AppCheckRefreshStatus {
  bool get hasUsableToken =>
      this == AppCheckRefreshStatus.cachedTokenAvailable ||
      this == AppCheckRefreshStatus.forcedRefreshSucceeded;
}

class AppCheckRefreshException implements Exception {
  final AppCheckRefreshStatus status;
  final String operationLabel;

  const AppCheckRefreshException({
    required this.status,
    required this.operationLabel,
  });

  String get message {
    if (kDebugMode) {
      return 'Falha na validacao de seguranca do app neste build de '
          'desenvolvimento. Cadastre o token de debug do App Check no '
          'Firebase Console e reabra o app.';
    }

    return 'Falha na validacao de seguranca do app. Feche e abra o app e '
        'tente novamente.';
  }

  String get debugMessage => 'app-check-auth-context-failure:${status.name}';

  @override
  String toString() =>
      'AppCheckRefreshException(operation: $operationLabel, '
      'status: ${status.name})';
}

/// Coordinates App Check refresh attempts across features to avoid hot-looping.
class AppCheckRefreshCoordinator {
  AppCheckRefreshCoordinator._();

  static final Map<int, Future<AppCheckRefreshStatus>> _inFlightRefreshes =
      <int, Future<AppCheckRefreshStatus>>{};
  static final Map<int, DateTime> _nextForcedRefreshAt = <int, DateTime>{};

  static Future<AppCheckRefreshStatus> ensureValidToken(
    app_check.FirebaseAppCheck appCheck, {
    required String operationLabel,
    Duration forcedRefreshCooldown = const Duration(minutes: 2),
    Duration throttledBackoff = const Duration(minutes: 10),
  }) {
    final appCheckKey = identityHashCode(appCheck);
    final inFlight = _inFlightRefreshes[appCheckKey];
    if (inFlight != null) return inFlight;

    final refreshFuture = _ensureValidTokenInternal(
      appCheck,
      appCheckKey: appCheckKey,
      operationLabel: operationLabel,
      forcedRefreshCooldown: forcedRefreshCooldown,
      throttledBackoff: throttledBackoff,
    );

    final trackedFuture = refreshFuture.whenComplete(() {
      _inFlightRefreshes.remove(appCheckKey);
    });

    _inFlightRefreshes[appCheckKey] = trackedFuture;
    return trackedFuture;
  }

  static Future<void> ensureValidTokenOrThrow(
    app_check.FirebaseAppCheck appCheck, {
    required String operationLabel,
    Duration forcedRefreshCooldown = const Duration(minutes: 2),
    Duration throttledBackoff = const Duration(minutes: 10),
  }) async {
    final status = await ensureValidToken(
      appCheck,
      operationLabel: operationLabel,
      forcedRefreshCooldown: forcedRefreshCooldown,
      throttledBackoff: throttledBackoff,
    );

    if (status.hasUsableToken) return;

    throw AppCheckRefreshException(
      status: status,
      operationLabel: operationLabel,
    );
  }

  static Future<AppCheckRefreshStatus> _ensureValidTokenInternal(
    app_check.FirebaseAppCheck appCheck, {
    required int appCheckKey,
    required String operationLabel,
    required Duration forcedRefreshCooldown,
    required Duration throttledBackoff,
  }) async {
    try {
      final cachedToken = await appCheck.getToken();
      if (_isValidToken(cachedToken)) {
        return AppCheckRefreshStatus.cachedTokenAvailable;
      }
    } catch (error, stackTrace) {
      if (_isThrottled(error)) {
        _scheduleNextForcedRefreshAfter(appCheckKey, throttledBackoff);
        AppLogger.info(
          'App Check throttled while reading cached token for $operationLabel. '
          'Skipping forced refresh temporarily.',
        );
        return AppCheckRefreshStatus.throttled;
      }

      AppLogger.warning(
        'Falha ao ler token em cache do App Check para $operationLabel',
        error,
        stackTrace,
        false,
      );
    }

    if (!_canAttemptForcedRefresh(appCheckKey)) {
      AppLogger.info(
        'App Check forced refresh skipped due to cooldown for $operationLabel.',
      );
      return AppCheckRefreshStatus.forcedRefreshSkippedByCooldown;
    }

    try {
      final refreshedToken = await appCheck.getToken(true);
      if (_isValidToken(refreshedToken)) {
        _scheduleNextForcedRefreshAfter(appCheckKey, forcedRefreshCooldown);
        return AppCheckRefreshStatus.forcedRefreshSucceeded;
      }

      _scheduleNextForcedRefreshAfter(appCheckKey, const Duration(seconds: 30));
      AppLogger.warning(
        'App Check forced refresh returned an empty token for $operationLabel.',
        null,
        null,
        false,
      );
      return AppCheckRefreshStatus.failed;
    } catch (error, stackTrace) {
      if (_isThrottled(error)) {
        _scheduleNextForcedRefreshAfter(appCheckKey, throttledBackoff);
        AppLogger.info(
          'App Check forced refresh throttled for $operationLabel. '
          'Backing off retry attempts.',
        );
        return AppCheckRefreshStatus.throttled;
      }

      _scheduleNextForcedRefreshAfter(appCheckKey, forcedRefreshCooldown);
      AppLogger.warning(
        'Falha ao atualizar token do App Check para $operationLabel',
        error,
        stackTrace,
        false,
      );
      return AppCheckRefreshStatus.failed;
    }
  }

  static bool _isValidToken(String? token) {
    return token != null && token.trim().isNotEmpty;
  }

  static bool _isThrottled(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('too many attempts') ||
        message.contains('too-many-requests');
  }

  static bool _canAttemptForcedRefresh(int appCheckKey) {
    final nextAttemptAt = _nextForcedRefreshAt[appCheckKey];
    if (nextAttemptAt == null) return true;
    return !DateTime.now().isBefore(nextAttemptAt);
  }

  static void _scheduleNextForcedRefreshAfter(int appCheckKey, Duration delay) {
    _nextForcedRefreshAt[appCheckKey] = DateTime.now().add(delay);
  }
}
