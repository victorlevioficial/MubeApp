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
// import 'src/cleaning_script.dart'; // Script de limpeza temporário - REMOVIDO
import 'src/app.dart';
import 'src/core/services/push_notification_service.dart';
import 'src/design_system/components/feedback/error_boundary.dart';
import 'src/utils/app_logger.dart';

void main() {
  runZonedGuarded(
    () async {
      final WidgetsBinding widgetsBinding =
          WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // 1. Configure Global Error Handlers for pure Dart errors & Platform errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details); // Calls ErrorWidget.builder
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

      // 2. Replace the "Red Screen of Death"
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return ErrorBoundary.buildErrorWidget(details);
      };

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Enable Firestore offline persistence for better caching
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

        // Initialize App Check
        await app_check.FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: kDebugMode
              ? app_check.AndroidProvider.debug
              : app_check.AndroidProvider.playIntegrity,
          // ignore: deprecated_member_use
          appleProvider: kDebugMode
              ? app_check.AppleProvider.debug
              : app_check.AppleProvider.deviceCheck,
        );

        // === SCRIPT DE LIMPEZA CONCLUÍDO E REMOVIDO ===
        AppLogger.info('✅ Database cleanup passed.');

        // Initialize misc services in background to not block UI
        await Future.wait([
          PushNotificationService().init(),
          _preloadFonts(),
        ]).then((_) => AppLogger.info('Services initialized'));
      } catch (e, stack) {
        AppLogger.error('Erro ao inicializar Firebase', e, stack);
      } finally {
        // Always remove splash even if error occurs
        FlutterNativeSplash.remove();
      }

      runApp(const ProviderScope(child: MubeApp()));
    },
    (error, stack) {
      AppLogger.error('Erro não tratado no Zone Guarded', error, stack);
    },
  );
}

Future<void> _preloadFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.inter(fontWeight: FontWeight.w400),
      GoogleFonts.inter(fontWeight: FontWeight.w500),
      GoogleFonts.inter(fontWeight: FontWeight.w600),
      GoogleFonts.inter(fontWeight: FontWeight.w700),
    ]);
  } catch (e) {
    AppLogger.warning('Erro ao carregar fontes: $e');
  }
}
