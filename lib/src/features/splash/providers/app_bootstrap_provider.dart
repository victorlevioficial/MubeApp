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
const String _appCheckWebRecaptchaV3SiteKey = String.fromEnvironment(
  'APP_CHECK_WEB_RECAPTCHA_V3_SITE_KEY',
  defaultValue: '',
);
const String _appCheckWebRecaptchaEnterpriseSiteKey = String.fromEnvironment(
  'APP_CHECK_WEB_RECAPTCHA_ENTERPRISE_SITE_KEY',
  defaultValue: '',
);
const String _debugBuildMarker = 'chat-batch-retry-fix-20260314-privacy';
Future<void>? _appCheckActivationInFlight;
bool _appCheckActivationCompleted = false;
StreamSubscription<String?>? _appCheckTokenSubscription;
String? _lastLoggedAppCheckToken;

enum AppBootstrapState { idle, running, ready }

@visibleForTesting
enum AppCheckWebProviderKind { reCaptchaV3, reCaptchaEnterprise }

@visibleForTesting
class AppCheckWebProviderConfig {
  const AppCheckWebProviderConfig({required this.kind, required this.siteKey});

  final AppCheckWebProviderKind kind;
  final String siteKey;
}

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
      await Future.wait([
        _ensureAppCheckActivation(),
        _warmNotificationPermissionPromptState(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.warning(
            'Bootstrap excedeu timeout de 10s. Prosseguindo sem bloquear UI.',
          );
          return const <void>[];
        },
      );
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
  if (kIsWeb) {
    await _activateWebAppCheck(appCheck);
    return;
  }

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
  // Em debug, desabilita auto-refresh pra evitar rate limit: o SDK tentaria
  // renovar por conta em loop quando o token debug falha, estourando "Too
  // many attempts". AppCheckRefreshCoordinator faz refresh sob demanda com
  // backoff — mais confiável em dev.
  await appCheck.setTokenAutoRefreshEnabled(false);
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

@visibleForTesting
AppCheckWebProviderConfig? resolveAppCheckWebProviderConfig({
  String recaptchaV3SiteKey = _appCheckWebRecaptchaV3SiteKey,
  String recaptchaEnterpriseSiteKey = _appCheckWebRecaptchaEnterpriseSiteKey,
}) {
  final enterpriseSiteKey = recaptchaEnterpriseSiteKey.trim();
  if (enterpriseSiteKey.isNotEmpty) {
    return AppCheckWebProviderConfig(
      kind: AppCheckWebProviderKind.reCaptchaEnterprise,
      siteKey: enterpriseSiteKey,
    );
  }

  final v3SiteKey = recaptchaV3SiteKey.trim();
  if (v3SiteKey.isNotEmpty) {
    return AppCheckWebProviderConfig(
      kind: AppCheckWebProviderKind.reCaptchaV3,
      siteKey: v3SiteKey,
    );
  }

  return null;
}

Future<void> _activateWebAppCheck(app_check.FirebaseAppCheck appCheck) async {
  final providerConfig = resolveAppCheckWebProviderConfig();
  if (providerConfig == null) {
    AppLogger.warning(
      'App Check web nao foi ativado porque nenhum site key de reCAPTCHA '
      'foi configurado. Use APP_CHECK_WEB_RECAPTCHA_V3_SITE_KEY ou '
      'APP_CHECK_WEB_RECAPTCHA_ENTERPRISE_SITE_KEY via --dart-define.',
      null,
      null,
      false,
    );
    return;
  }

  switch (providerConfig.kind) {
    case AppCheckWebProviderKind.reCaptchaEnterprise:
      await appCheck.activate(
        providerWeb: app_check.ReCaptchaEnterpriseProvider(
          providerConfig.siteKey,
        ),
      );
    case AppCheckWebProviderKind.reCaptchaV3:
      await appCheck.activate(
        providerWeb: app_check.ReCaptchaV3Provider(providerConfig.siteKey),
      );
  }
  await appCheck.setTokenAutoRefreshEnabled(true);
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
