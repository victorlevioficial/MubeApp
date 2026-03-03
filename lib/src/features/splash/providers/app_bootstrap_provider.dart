import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_logger.dart';
import '../../onboarding/providers/notification_permission_prompt_provider.dart';

const String _appCheckDebugToken = String.fromEnvironment(
  'APP_CHECK_DEBUG_TOKEN',
  defaultValue: '11111111-2222-4333-8444-555555555555',
);

enum AppBootstrapState { idle, running, ready }

typedef AppCheckBootstrapper = Future<void> Function();

final appCheckBootstrapperProvider = Provider<AppCheckBootstrapper>((ref) {
  return initializeAppCheck;
});

class AppBootstrapNotifier extends Notifier<AppBootstrapState> {
  bool _isStarting = false;

  @override
  AppBootstrapState build() => AppBootstrapState.idle;

  Future<void> start() async {
    if (_isStarting || state == AppBootstrapState.ready) {
      return;
    }

    _isStarting = true;
    state = AppBootstrapState.running;

    try {
      await ref.read(appCheckBootstrapperProvider)();
      unawaited(_warmNotificationPermissionPromptState());
    } catch (error, stack) {
      AppLogger.warning(
        'Falha ao concluir bootstrap inicial do app',
        error,
        stack,
      );
    } finally {
      state = AppBootstrapState.ready;
      _isStarting = false;
    }
  }

  Future<void> _warmNotificationPermissionPromptState() async {
    try {
      await ref.read(notificationPermissionPromptProvider.future);
    } catch (error, stack) {
      AppLogger.warning(
        'Falha ao aquecer estado da permissao de notificacoes',
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

Future<void> initializeAppCheck() async {
  try {
    if (kReleaseMode) {
      await app_check.FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider: app_check.AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider: app_check.AppleProvider.appAttestWithDeviceCheckFallback,
      );
      return;
    }

    await app_check.FirebaseAppCheck.instance.activate(
      providerAndroid: const app_check.AndroidDebugProvider(),
      providerApple: const app_check.AppleDebugProvider(
        debugToken: _appCheckDebugToken,
      ),
    );
    AppLogger.info(
      'App Check debug provider ativado em desenvolvimento. '
      'Token iOS atual: $_appCheckDebugToken. '
      'Cadastre este token em Firebase Console > App Check > app iOS > Manage debug tokens.',
    );
  } catch (error, stack) {
    AppLogger.warning('Falha ao inicializar App Check', error, stack);
  }
}
