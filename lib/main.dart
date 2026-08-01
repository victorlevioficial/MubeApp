import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/services/favorite_integration_effects.dart';
import 'src/core/services/image_cache_config.dart';
import 'src/core/services/performance/app_performance_monitoring.dart';
import 'src/design_system/components/feedback/error_boundary.dart';
import 'src/design_system/foundations/tokens/app_spacing.dart';
import 'src/features/favorites/domain/favorite_effects.dart';
import 'src/features/splash/providers/app_bootstrap_provider.dart';
import 'src/utils/app_logger.dart';
import 'src/utils/app_performance_tracker.dart';

const Color _bootstrapBackgroundColor = Color(0xFF0A0A0A);
const int _firestoreCacheSizeBytes = 100 * 1024 * 1024;

void main() {
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      // Poppins/Inter ship bundled in assets/google_fonts; never hit the
      // network for fonts (offline-first + consistent first paint).
      GoogleFonts.config.allowRuntimeFetching = false;
      LicenseRegistry.addLicense(() async* {
        for (final licenseAsset in const [
          'google_fonts/OFL_Poppins.txt',
          'google_fonts/OFL_Inter.txt',
        ]) {
          final license = await rootBundle.loadString(licenseAsset);
          yield LicenseEntryWithLineBreaks(const ['google_fonts'], license);
        }
      });
      // Android 15+ targeting SDK 35 renders edge-to-edge by default; enabling
      // it explicitly keeps the contract consistent on older versions too.
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      ImageCacheConfig.configureFlutterImageCache();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        final isFatal = AppLogger.shouldTreatFlutterErrorAsFatal(details);
        AppLogger.recordFlutterError(details, fatal: isFatal);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.setCustomKey(
          'platform_dispatcher_error_type',
          error.runtimeType.toString(),
        );
        AppLogger.fatal('Platform Dispatcher Error', error, stack);
        return true;
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return ErrorBoundary.buildErrorWidget(details);
      };

      runApp(const _BootstrapHost());
    },
    (error, stack) {
      AppLogger.setCustomKey('zone_error_type', error.runtimeType.toString());
      AppLogger.setCustomKey('zone_error_message', error.toString());
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
  bool _isBootstrapping = false;
  bool _nativeSplashRemoved = false;
  bool _postBootstrapServicesScheduled = false;

  @override
  void initState() {
    super.initState();
    AppPerformanceTracker.mark('bootstrap_host.init_state');
    unawaited(_bootstrapFirebase());
  }

  void _removeNativeSplashIfNeeded() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    AppPerformanceTracker.mark('bootstrap.native_splash_removed');
    FlutterNativeSplash.remove();
  }

  Future<void> _bootstrapFirebase() async {
    if (_isBootstrapping) return;
    _isBootstrapping = true;
    if (_bootstrapError != null && mounted) {
      setState(() => _bootstrapError = null);
    }

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
        cacheSizeBytes: _firestoreCacheSizeBytes,
      );
      AppPerformanceTracker.mark('firebase.firestore.settings_applied');

      if (!mounted) return;
      setState(() {
        _firebaseReady = true;
        _bootstrapError = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _postBootstrapServicesScheduled) return;
        _postBootstrapServicesScheduled = true;
        unawaited(_initializePostBootstrapServices());
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
    } finally {
      _isBootstrapping = false;
    }
  }

  Future<void> _initializePostBootstrapServices() async {
    final postBootstrapStopwatch = AppPerformanceTracker.startSpan(
      'bootstrap.post_frame_services',
    );

    try {
      final appLoggerInitStopwatch = AppPerformanceTracker.startSpan(
        'bootstrap.app_logger_initialize',
      );
      await AppLogger.initialize();
      AppPerformanceTracker.finishSpan(
        'bootstrap.app_logger_initialize',
        appLoggerInitStopwatch,
      );

      final appCheckInitStopwatch = AppPerformanceTracker.startSpan(
        'firebase.app_check.initialize',
      );
      try {
        await ensureAppCheckActivated(app_check.FirebaseAppCheck.instance);
        AppPerformanceTracker.finishSpan(
          'firebase.app_check.initialize',
          appCheckInitStopwatch,
        );
      } catch (error, stack) {
        AppLogger.warning(
          'Falha ao ativar App Check no bootstrap principal do app',
          error,
          stack,
          false,
        );
        AppPerformanceTracker.finishSpan(
          'firebase.app_check.initialize',
          appCheckInitStopwatch,
          data: {'status': 'error', 'error_type': error.runtimeType.toString()},
        );
      }

      await AppPerformanceMonitoring.initialize();

      AppPerformanceTracker.finishSpan(
        'bootstrap.post_frame_services',
        postBootstrapStopwatch,
      );
    } catch (error, stack) {
      AppLogger.warning(
        'Falha ao inicializar servicos pos-bootstrap',
        error,
        stack,
        false,
      );
      AppPerformanceTracker.finishSpan(
        'bootstrap.post_frame_services',
        postBootstrapStopwatch,
        data: {'status': 'error', 'error_type': error.runtimeType.toString()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseReady) {
      return ProviderScope(
        overrides: [
          favoriteEffectsProvider.overrideWith(
            (ref) => FavoriteIntegrationEffects(ref),
          ),
        ],
        child: MubeApp(onInitialRouteReady: _removeNativeSplashIfNeeded),
      );
    }

    return Material(
      color: _bootstrapBackgroundColor,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: _bootstrapError == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                )
              : Center(
                  child: Padding(
                    padding: AppSpacing.h24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Erro ao iniciar o app.\n${_bootstrapError.runtimeType}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        FilledButton(
                          key: const ValueKey('bootstrap_retry_button'),
                          onPressed: _bootstrapFirebase,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
