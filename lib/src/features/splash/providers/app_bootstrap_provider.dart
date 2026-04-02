import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/app_performance_tracker.dart';
import '../../onboarding/providers/notification_permission_prompt_provider.dart';

const String _appCheckDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
  defaultValue: '',
);
const String _debugBuildMarker = 'chat-batch-retry-fix-20260314-privacy';
Future<void>? _appCheckActivationInFlight;
bool _appCheckActivationCompleted = false;
StreamSubscription<String?>? _appCheckTokenSubscription;
String? _lastLoggedAppCheckToken;

enum AppBootstrapState { idle, running, ready }

typedef AppCheckBootstrapper = Future<void> Function();

final appCheckBootstrapperProvider = Provider<AppCheckBootstrapper>((ref) {
  final appCheck = ref.watch(firebaseAppCheckProvider);
  return () => ensureAppCheckActivated(appCheck);
});

class AppBootstrapNotifier extends Notifier<AppBootstrapState> {
  bool _isStarting = false;
  Future<void>? _appCheckActivation;

  @override
  AppBootstrapState build() {
    return AppBootstrapState.idle;
  }

  Future<void> start() async {
    if (_isStarting || state == AppBootstrapState.ready) {
      return;
    }

    final bootstrapStopwatch = AppPerformanceTracker.startSpan(
      'app.bootstrap.start',
    );
    var bootstrapStatus = 'done';
    _isStarting = true;
    state = AppBootstrapState.running;

    try {
      unawaited(_ensureAppCheckActivation());
      unawaited(_warmNotificationPermissionPromptState());
    } catch (error, stack) {
      bootstrapStatus = 'error';
      AppLogger.warning(
        'Falha ao concluir bootstrap inicial do app',
        error,
        stack,
      );
    } finally {
      AppPerformanceTracker.finishSpan(
        'app.bootstrap.start',
        bootstrapStopwatch,
        data: {'status': bootstrapStatus},
      );
      state = AppBootstrapState.ready;
      _isStarting = false;
    }
  }

  Future<void> _ensureAppCheckActivation() {
    final inFlight = _appCheckActivation;
    if (inFlight != null) return inFlight;

    final activation =
        () async {
          final appCheckStopwatch = AppPerformanceTracker.startSpan(
            'app.bootstrap.app_check',
          );
          var appCheckStatus = 'done';
          try {
            await ref
                .read(appCheckBootstrapperProvider)()
                .timeout(const Duration(seconds: 8));
          } catch (error, stack) {
            appCheckStatus = error is TimeoutException ? 'timeout' : 'error';
            AppLogger.warning(
              'Falha ao inicializar App Check',
              error,
              stack,
              false,
            );
          } finally {
            AppPerformanceTracker.finishSpan(
              'app.bootstrap.app_check',
              appCheckStopwatch,
              data: {'status': appCheckStatus},
            );
          }
        }().whenComplete(() {
          _appCheckActivation = null;
        });

    _appCheckActivation = activation;
    return activation;
  }

  Future<void> _warmNotificationPermissionPromptState() async {
    try {
      await ref.read(notificationPermissionPromptProvider.future);
    } catch (error, stack) {
      AppLogger.warning(
        'Falha ao aquecer estado da permissão de notificações',
        error,
        stack,
      );
    }
  }
}

final appBootstrapProvider =
    NotifierProvider<AppBootstrapNotifier, AppBootstrapState>(
      AppBootstrapNotifier.new,
    );

@visibleForTesting
void resetAppCheckActivationState() {
  _appCheckActivationInFlight = null;
  _appCheckActivationCompleted = false;
  unawaited(_appCheckTokenSubscription?.cancel());
  _appCheckTokenSubscription = null;
  _lastLoggedAppCheckToken = null;
}

Future<void> ensureAppCheckActivated(app_check.FirebaseAppCheck appCheck) {
  if (_appCheckActivationCompleted) {
    return Future<void>.value();
  }

  final inFlight = _appCheckActivationInFlight;
  if (inFlight != null) return inFlight;

  final activation = initializeAppCheck(appCheck)
      .then((_) {
        _appCheckActivationCompleted = true;
      })
      .whenComplete(() {
        _appCheckActivationInFlight = null;
      });

  _appCheckActivationInFlight = activation;
  return activation;
}

Future<void> initializeAppCheck(app_check.FirebaseAppCheck appCheck) async {
  if (kReleaseMode) {
    await appCheck.activate(
      providerAndroid: const app_check.AndroidPlayIntegrityProvider(),
      providerApple:
          const app_check.AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    await appCheck.setTokenAutoRefreshEnabled(true);
    return;
  }

  final hasExplicitDebugToken = _appCheckDebugToken.trim().isNotEmpty;
  await appCheck.activate(
    providerAndroid: hasExplicitDebugToken
        ? const app_check.AndroidDebugProvider(debugToken: _appCheckDebugToken)
        : const app_check.AndroidDebugProvider(),
    providerApple: hasExplicitDebugToken
        ? const app_check.AppleDebugProvider(debugToken: _appCheckDebugToken)
        : const app_check.AppleDebugProvider(),
  );
  await appCheck.setTokenAutoRefreshEnabled(true);
  _ensureDebugTokenLoggingAttached(appCheck);

  if (hasExplicitDebugToken) {
    AppLogger.warning(
      'App Check debug provider ativado em desenvolvimento. '
      'Build marker: $_debugBuildMarker. '
      'Token configurado para Android/iOS: $_appCheckDebugToken. '
      'Cadastre este token em Firebase Console > App Check > '
      'app Android/iOS > Manage debug tokens.',
      null,
      null,
      false,
    );
  } else {
    AppLogger.warning(
      'App Check debug provider ativado em desenvolvimento. '
      'Build marker: $_debugBuildMarker. '
      'Nenhum token explicito foi configurado via APP_CHECK_DEBUG_TOKEN. '
      'O token gerado pelo SDK sera logado assim que ficar disponivel; '
      'cadastre-o em Firebase Console > App Check > '
      'app Android/iOS > Manage debug tokens.',
      null,
      null,
      false,
    );
  }

  await _warmDebugTokenLogging(appCheck);
}

void _ensureDebugTokenLoggingAttached(app_check.FirebaseAppCheck appCheck) {
  if (_appCheckTokenSubscription != null) return;

  _appCheckTokenSubscription = appCheck.onTokenChange.listen((token) {
    _logDebugTokenIfNeeded(token, source: 'onTokenChange');
  });
}

Future<void> _warmDebugTokenLogging(app_check.FirebaseAppCheck appCheck) async {
  try {
    final token = await appCheck.getToken();
    _logDebugTokenIfNeeded(token, source: 'warmup');
  } catch (error, stack) {
    AppLogger.warning(
      'Falha ao aquecer token do App Check em desenvolvimento.',
      error,
      stack,
      false,
    );
  }
}

void _logDebugTokenIfNeeded(String? token, {required String source}) {
  final trimmedToken = token?.trim();
  if (trimmedToken == null || trimmedToken.isEmpty) return;
  if (trimmedToken == _lastLoggedAppCheckToken) return;

  _lastLoggedAppCheckToken = trimmedToken;
  AppLogger.warning(
    'App Check debug token capturado via $source. '
    'Build marker: $_debugBuildMarker. '
    'Token: $trimmedToken. '
    'Cadastre-o em Firebase Console > App Check > '
    'app Android/iOS > Manage debug tokens.',
    null,
    null,
    false,
  );
}
