import 'package:flutter/foundation.dart';

/// Simple logger for the app.
///
/// Uses debugPrint in debug mode, no-op in release mode.
/// This avoids the `avoid_print` lint warning.
class AppLogger {
  static const String _tag = 'MubeApp';

  /// Logs a debug message (only in debug mode).
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] $message');
    }
  }

  /// Logs an info message.
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] ℹ️ $message');
    }
  }

  /// Logs a warning message.
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] ⚠️ $message');
    }
  }

  /// Logs an error message.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (kDebugMode) {
      debugPrint('[${tag ?? _tag}] ❌ $message');
      if (error != null) {
        debugPrint('[${tag ?? _tag}] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[${tag ?? _tag}] StackTrace: $stackTrace');
      }
    }
  }
}
