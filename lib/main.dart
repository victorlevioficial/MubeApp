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
import 'src/core/services/image_cache_config.dart';
import 'src/design_system/components/feedback/error_boundary.dart';
import 'src/utils/app_logger.dart';
import 'src/utils/app_performance_tracker.dart';

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
    AppPerformanceTracker.mark('bootstrap_host.init_state');
    unawaited(_bootstrapFirebase());
  }

  void _removeNativeSplashIfNeeded() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    FlutterNativeSplash.remove();
  }

  Future<void> _bootstrapFirebase() async {
    final bootstrapStopwatch = AppPerformanceTracker.startSpan(
      'bootstrap.firebase',
    );
    try {
      final firebaseInitStopwatch = AppPerformanceTracker.startSpan(
        'firebase.initialize_app',
      );
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppPerformanceTracker.finishSpan(
        'firebase.initialize_app',
        firebaseInitStopwatch,
      );

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      AppPerformanceTracker.mark('firebase.firestore.settings_applied');

      if (!mounted) return;
      setState(() {
        _firebaseReady = true;
        _bootstrapError = null;
      });

      final appLoggerInitStopwatch = AppPerformanceTracker.startSpan(
        'bootstrap.app_logger_initialize',
      );
      await AppLogger.initialize();
      AppPerformanceTracker.finishSpan(
        'bootstrap.app_logger_initialize',
        appLoggerInitStopwatch,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_deferredServicesScheduled) return;
        _deferredServicesScheduled = true;
        unawaited(_initializeDeferredServices());
      });
      AppPerformanceTracker.finishSpan(
        'bootstrap.firebase',
        bootstrapStopwatch,
      );
    } catch (error, stack) {
      AppLogger.error('Erro ao inicializar Firebase', error, stack);
      AppPerformanceTracker.finishSpan(
        'bootstrap.firebase',
        bootstrapStopwatch,
        data: {'status': 'error', 'error_type': error.runtimeType.toString()},
      );
      if (!mounted) return;
      setState(() {
        _bootstrapError = error;
        _firebaseReady = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _removeNativeSplashIfNeeded();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseReady) {
      return ProviderScope(
        child: MubeApp(onInitialRouteReady: _removeNativeSplashIfNeeded),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _bootstrapBackgroundColor,
        child: SizedBox.expand(
          child: _bootstrapError == null
              ? const _BootstrapLaunchView()
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

class _BootstrapLaunchView extends StatelessWidget {
  const _BootstrapLaunchView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}

Future<void> _initializeDeferredServices() async {
  final deferredServicesStopwatch = AppPerformanceTracker.startSpan(
    'bootstrap.deferred_services',
  );
  try {
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    final fontWarmupStopwatch = AppPerformanceTracker.startSpan(
      'bootstrap.font_preload',
    );
    await _preloadFonts();
    AppPerformanceTracker.finishSpan(
      'bootstrap.font_preload',
      fontWarmupStopwatch,
    );
    AppLogger.info('Services initialized');
    AppPerformanceTracker.finishSpan(
      'bootstrap.deferred_services',
      deferredServicesStopwatch,
    );
  } catch (e, stack) {
    AppLogger.error('Erro ao inicializar servicos em background', e, stack);
    AppPerformanceTracker.finishSpan(
      'bootstrap.deferred_services',
      deferredServicesStopwatch,
      data: {'status': 'error', 'error_type': e.runtimeType.toString()},
    );
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
