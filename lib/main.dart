import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/services/analytics_service.dart';
import 'src/core/services/image_cache_config.dart';
import 'src/core/services/remote_config_service.dart';
import 'src/design_system/components/feedback/error_boundary.dart';
import 'src/utils/app_logger.dart';

const Color _bootstrapBackgroundColor = Color(0xFF0A0A0A);

void main() {
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      ImageCacheConfig.configureFlutterImageCache();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AppLogger.recordFlutterError(details, fatal: true);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.fatal('Platform Dispatcher Error', error, stack);
        return true;
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return ErrorBoundary.buildErrorWidget(details);
      };

      runApp(const _BootstrapHost());
    },
    (error, stack) {
      AppLogger.error('Erro nao tratado no Zone Guarded', error, stack);
    },
  );
}

class _BootstrapHost extends StatefulWidget {
  const _BootstrapHost();

  @override
  State<_BootstrapHost> createState() => _BootstrapHostState();
}

class _BootstrapHostState extends State<_BootstrapHost> {
  Object? _bootstrapError;
  bool _firebaseReady = false;
  bool _nativeSplashRemoved = false;
  bool _deferredServicesScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nativeSplashRemoved) return;
      _nativeSplashRemoved = true;
      FlutterNativeSplash.remove();
    });
    unawaited(_bootstrapFirebase());
  }

  Future<void> _bootstrapFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      if (!mounted) return;
      setState(() {
        _firebaseReady = true;
        _bootstrapError = null;
      });

      await AppLogger.initialize();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_deferredServicesScheduled) return;
        _deferredServicesScheduled = true;
        unawaited(_initializeDeferredServices());
      });
    } catch (error, stack) {
      AppLogger.error('Erro ao inicializar Firebase', error, stack);
      if (!mounted) return;
      setState(() {
        _bootstrapError = error;
        _firebaseReady = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseReady) {
      return const ProviderScope(child: MubeApp());
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _bootstrapBackgroundColor,
        child: SizedBox.expand(
          child: _bootstrapError == null
              ? const SizedBox.shrink()
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Erro ao iniciar o app.\n${_bootstrapError.runtimeType}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

Future<void> _initializeDeferredServices() async {
  try {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await AnalyticsService.initialize();

    await Future<void>.delayed(const Duration(milliseconds: 700));
    await RemoteConfigService.initialize();

    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _preloadFonts();
    AppLogger.info('Services initialized');
  } catch (e, stack) {
    AppLogger.error('Erro ao inicializar servicos em background', e, stack);
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
