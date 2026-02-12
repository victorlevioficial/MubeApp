import 'dart:async';
import 'dart:ui'; // For PlatformDispatcher

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/services/analytics_service.dart';
import 'src/core/services/push_notification_service.dart';
import 'src/core/services/remote_config_service.dart';
import 'src/design_system/components/feedback/error_boundary.dart';
import 'src/utils/app_logger.dart';

const bool _enableDebugAppCheck = bool.fromEnvironment(
  'ENABLE_APP_CHECK_DEBUG',
  defaultValue: false,
);

void main() {
  runZonedGuarded(
    () async {
      final WidgetsBinding widgetsBinding =
          WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // 1. Configure global error handlers.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'Flutter Framework Error',
          details.exception,
          details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error('Platform Dispatcher Error', error, stack);
        return true;
      };

      // 2. Replace the "Red Screen of Death".
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return ErrorBoundary.buildErrorWidget(details);
      };

      var firebaseReady = false;
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;

        AppLogger.info('Build mode: ${kReleaseMode ? 'release' : 'dev'}');

        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e, stack) {
        AppLogger.error('Erro ao inicializar Firebase', e, stack);
      }

      runApp(const ProviderScope(child: MubeApp()));
      FlutterNativeSplash.remove();

      if (firebaseReady) {
        widgetsBinding.addPostFrameCallback((_) {
          unawaited(_initializeDeferredServices());
        });
      }
    },
    (error, stack) {
      AppLogger.error('Erro nao tratado no Zone Guarded', error, stack);
    },
  );
}

Future<void> _initializeDeferredServices() async {
  try {
    await _initializeAppCheck();
    await AppLogger.initialize();
    await AnalyticsService.initialize();
    await RemoteConfigService.initialize();

    // Delay permission prompt to avoid contention with first frames.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await PushNotificationService().init();

    await _preloadFonts();
    AppLogger.info('Services initialized');
  } catch (e, stack) {
    AppLogger.error('Erro ao inicializar servicos em background', e, stack);
  }
}

Future<void> _initializeAppCheck() async {
  try {
    if (kReleaseMode) {
      await app_check.FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider: app_check.AndroidProvider.playIntegrity,
        // ignore: deprecated_member_use
        appleProvider: app_check.AppleProvider.deviceCheck,
      );
      return;
    }

    if (!_enableDebugAppCheck) {
      AppLogger.info(
        'App Check desativado em debug. Ative com --dart-define=ENABLE_APP_CHECK_DEBUG=true',
      );
      return;
    }

    await app_check.FirebaseAppCheck.instance.activate(
      // ignore: deprecated_member_use
      androidProvider: app_check.AndroidProvider.debug,
    );
    AppLogger.info('App Check debug provider ativado em desenvolvimento');
  } catch (e, stack) {
    AppLogger.warning('Falha ao inicializar App Check', e, stack);
  }
}

Future<void> _preloadFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(fontWeight: FontWeight.w500),
      GoogleFonts.poppins(fontWeight: FontWeight.w600),
      GoogleFonts.poppins(fontWeight: FontWeight.w700),
      GoogleFonts.inter(fontWeight: FontWeight.w400),
      GoogleFonts.inter(fontWeight: FontWeight.w500),
      GoogleFonts.inter(fontWeight: FontWeight.w600),
      GoogleFonts.inter(fontWeight: FontWeight.w700),
    ]);
  } catch (e) {
    AppLogger.warning('Erro ao carregar fontes: $e');
  }
}
