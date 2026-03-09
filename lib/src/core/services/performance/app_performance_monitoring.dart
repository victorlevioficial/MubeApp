import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/app_logger.dart';
import '../../../utils/app_performance_tracker.dart';

/// Centralizes Firebase Performance Monitoring bootstrap rules.
final class AppPerformanceMonitoring {
  AppPerformanceMonitoring._();

  static const bool _enableInDebug = bool.fromEnvironment(
    'MUBE_ENABLE_PERFORMANCE_MONITORING_IN_DEBUG',
    defaultValue: false,
  );

  static bool get _isSupportedPlatform {
    if (kIsWeb) return true;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  static bool get _shouldCollect =>
      kReleaseMode || kProfileMode || (kDebugMode && _enableInDebug);

  static Future<void> initialize() async {
    if (!_isSupportedPlatform) {
      AppPerformanceTracker.mark(
        'firebase.performance.initialize.skipped',
        data: {'reason': 'unsupported_platform'},
      );
      return;
    }

    final stopwatch = AppPerformanceTracker.startSpan(
      'firebase.performance.initialize',
      data: {'collection_enabled': _shouldCollect},
    );

    try {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        _shouldCollect,
      );
      AppPerformanceTracker.finishSpan(
        'firebase.performance.initialize',
        stopwatch,
        data: {'status': 'ok', 'collection_enabled': _shouldCollect},
      );
      AppLogger.info(
        _shouldCollect
            ? 'Firebase Performance Monitoring enabled'
            : 'Firebase Performance Monitoring disabled for this build',
      );
    } catch (error, stackTrace) {
      AppPerformanceTracker.finishSpan(
        'firebase.performance.initialize',
        stopwatch,
        data: {'status': 'error', 'error_type': error.runtimeType.toString()},
      );
      AppLogger.warning(
        'Firebase Performance Monitoring initialization failed',
        error,
        stackTrace,
        false,
      );
    }
  }
}
