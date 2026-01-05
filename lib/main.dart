import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/utils/app_logger.dart';

void main() {
  runZonedGuarded(
    () async {
      final WidgetsBinding widgetsBinding =
          WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e, stack) {
        AppLogger.error(
          'Erro ao inicializar Firebase',
          error: e,
          stackTrace: stack,
        );
        // Remove splash to show error
        FlutterNativeSplash.remove();
      }

      // Pre-load Fonts to prevent FOUT (Flash of Unstyled Text) globally
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

      runApp(const ProviderScope(child: MubeApp()));
    },
    (error, stack) {
      AppLogger.error(
        'Erro não tratado no app',
        error: error,
        stackTrace: stack,
      );
    },
  );
}
