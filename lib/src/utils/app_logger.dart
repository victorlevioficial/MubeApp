import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Utilitário centralizado para logs da aplicação.
///
/// Use esta classe em vez de `print()` para garantir que:
/// 1. Os logs sejam enviados ao Crashlytics em produção
/// 2. Tenhamos rastreabilidade (nome do logger) em debug
/// 3. Erros críticos sejam automaticamente reportados
class AppLogger {
  const AppLogger._();

  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static const bool _enableVerboseDebugLogs = bool.fromEnvironment(
    'MUBE_VERBOSE_LOGS',
    defaultValue: false,
  );

  static bool _isCrashlyticsEnabled = false;
  static bool _debugConsoleMirroringEnabled = true;
  static const List<String> _nonFatalFlutterErrorPatterns = <String>[
    'a renderflex overflowed',
    'a renderviewport overflowed',
    'was given an infinite size during layout',
    'renderbox was not laid out',
    'cannot hit test a render box that has never been laid out',
    'vertical viewport was given unbounded',
    'horizontal viewport was given unbounded',
    'viewport was given unbounded',
  ];
  static const List<String> _handledImageFlutterErrorContextPatterns = <String>[
    'image failed to precache',
    'image resource service',
    'cachednetworkimageprovider',
    'networkimage',
  ];
  static const List<String> _handledImageFlutterErrorCausePatterns = <String>[
    'invalid statuscode: 404',
    'httpexception',
    'clientexception',
    'socketexception',
    'connection closed while receiving data',
    'failed host lookup',
    'networkimageloadexception',
  ];

  static bool get verboseLoggingEnabled =>
      kDebugMode && _enableVerboseDebugLogs;

  @visibleForTesting
  static void setDebugConsoleMirroringEnabled(bool enabled) {
    _debugConsoleMirroringEnabled = enabled;
  }

  static void _mirrorToFlutterConsole(
    String loggerName,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode || !_debugConsoleMirroringEnabled) return;

    final buffer = StringBuffer('[$loggerName] $message');
    if (error != null) {
      buffer.write(' | error=$error');
    }

    debugPrintSynchronously(buffer.toString());
    if (stackTrace != null) {
      debugPrintSynchronously(stackTrace.toString());
    }
  }

  /// Inicializa o Crashlytics. Deve ser chamado no main() antes de usar o app.
  static Future<void> initialize() async {
    if (kReleaseMode) {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      _isCrashlyticsEnabled = true;
      AppLogger.info('🔥 Crashlytics inicializado');
    } else {
      AppLogger.info('🔧 Crashlytics desabilitado fora do release');
    }
  }

  /// Log de debug simples (informativo)
  /// Em produção, não envia ao Crashlytics (apenas logs de erro/warning)
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (verboseLoggingEnabled) {
      _mirrorToFlutterConsole(
        'MubeApp INFO',
        message,
        error: error,
        stackTrace: stackTrace,
      );
      developer.log(
        message,
        name: 'MubeApp ℹ️',
        error: error,
        stackTrace: stackTrace,
        level: 800, // INFO
      );
    }
    // INFO logs não são enviados ao Crashlytics em produção
  }

  /// Log de erro (algo deu errado)
  /// Em produção, envia automaticamente ao Crashlytics
  /// Passe `false` no último argumento para não abrir issue para erro esperado.
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    bool reportToCrashlytics = true,
  ]) {
    if (kDebugMode) {
      _mirrorToFlutterConsole(
        'MubeApp ERROR',
        message,
        error: error,
        stackTrace: stackTrace,
      );
      developer.log(
        message,
        name: 'MubeApp 🚨',
        error: error,
        stackTrace: stackTrace,
        level: 1000, // SEVERE
      );
    }

    if (_isCrashlyticsEnabled && reportToCrashlytics) {
      _crashlytics.log('[ERROR] $message');
      if (error != null) {
        _crashlytics.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: false,
        );
      }
    }
  }

  /// Log de erro fatal (crash)
  /// Use apenas para erros que impedem o funcionamento do app
  static void fatal(String message, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      _mirrorToFlutterConsole(
        'MubeApp FATAL',
        message,
        error: error,
        stackTrace: stackTrace,
      );
      developer.log(
        message,
        name: 'MubeApp 💥 FATAL',
        error: error,
        stackTrace: stackTrace,
        level: 1200, // FATAL
      );
    }

    if (_isCrashlyticsEnabled) {
      _crashlytics.log('[FATAL] $message');
      _crashlytics.recordError(error, stackTrace, reason: message, fatal: true);
    }
  }

  @visibleForTesting
  static bool isHandledImageFlutterError(FlutterErrorDetails details) {
    final normalized = [
      details.exceptionAsString(),
      details.context?.toDescription() ?? '',
      details.library ?? '',
      details.stack?.toString() ?? '',
    ].join(' ').toLowerCase();

    final matchesCause = _handledImageFlutterErrorCausePatterns.any(
      (pattern) => normalized.contains(pattern),
    );
    if (!matchesCause) return false;

    // If the cause is an HTTP 404 specifically, treat it as handled regardless
    // of context — these are always missing-resource errors (deleted Storage
    // files, expired URLs) and should never be reported as crashes.
    if (normalized.contains('invalid statuscode: 404') ||
        normalized.contains('404') && normalized.contains('httpexception')) {
      return true;
    }

    return _handledImageFlutterErrorContextPatterns.any(
      (pattern) => normalized.contains(pattern),
    );
  }

  @visibleForTesting
  static bool shouldReportFlutterError(FlutterErrorDetails details) {
    return !isHandledImageFlutterError(details);
  }

  static void logHandledImageError({
    required String source,
    required String url,
    required Object error,
    StackTrace? stackTrace,
  }) {
    warning(
      'Handled image load failure | source=$source | url=$url',
      error,
      stackTrace,
      false,
    );
  }

  /// Log de erro do framework Flutter
  static bool shouldTreatFlutterErrorAsFatal(FlutterErrorDetails details) {
    if (isHandledImageFlutterError(details)) {
      return false;
    }

    final normalized = [
      details.exceptionAsString(),
      details.context?.toDescription() ?? '',
      details.library ?? '',
    ].join(' ').toLowerCase();

    for (final pattern in _nonFatalFlutterErrorPatterns) {
      if (normalized.contains(pattern)) {
        return false;
      }
    }

    return true;
  }

  /// Log de erro do framework Flutter
  static void recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) {
    if (kDebugMode) {
      _mirrorToFlutterConsole(
        fatal ? 'MubeApp FATAL' : 'MubeApp ERROR',
        'Flutter Framework Error',
        error: details.exception,
        stackTrace: details.stack,
      );
      developer.log(
        'Flutter Framework Error',
        name: fatal ? 'MubeApp 💥 FATAL' : 'MubeApp 🚨',
        error: details.exception,
        stackTrace: details.stack,
        level: fatal ? 1200 : 1000,
      );
    }

    if (!_isCrashlyticsEnabled || !shouldReportFlutterError(details)) {
      return;
    }

    _crashlytics.setCustomKey(
      'flutter_error_type',
      details.exception.runtimeType.toString(),
    );
    _crashlytics.setCustomKey('flutter_error_fatal', fatal);
    _crashlytics.setCustomKey(
      'flutter_error_context',
      details.context?.toDescription() ?? 'unknown',
    );
    if (fatal) {
      _crashlytics.recordFlutterFatalError(details);
    } else {
      _crashlytics.recordFlutterError(details);
    }
  }

  /// Log de debug (desenvolvimento)
  /// Apenas em modo debug, não envia ao Crashlytics
  static void debug(String message) {
    if (verboseLoggingEnabled) {
      _mirrorToFlutterConsole('MubeApp DEBUG', message);
      developer.log(
        message,
        name: 'MubeApp 🐛',
        level: 500, // FINE
      );
    }
  }

  /// Log de warning (atenção)
  /// Em produção, envia como log não-crítico ao Crashlytics
  /// Passe `false` no último argumento para não abrir issue para erro esperado.
  static void warning(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    bool reportToCrashlytics = true,
  ]) {
    if (kDebugMode) {
      _mirrorToFlutterConsole(
        'MubeApp WARNING',
        message,
        error: error,
        stackTrace: stackTrace,
      );
      developer.log(
        message,
        name: 'MubeApp ⚠️',
        error: error,
        stackTrace: stackTrace,
        level: 900, // WARNING
      );
    }

    if (_isCrashlyticsEnabled && reportToCrashlytics) {
      _crashlytics.log('[WARNING] $message');
      if (error != null) {
        _crashlytics.recordError(
          error,
          stackTrace,
          reason: message,
          fatal: false,
        );
      }
    }
  }

  /// Define o user ID no Crashlytics para rastreamento
  static void setUserIdentifier(String userId) {
    if (_isCrashlyticsEnabled) {
      _crashlytics.setUserIdentifier(userId);
    }
  }

  /// Adiciona uma chave customizada ao contexto do Crashlytics
  static void setCustomKey(String key, dynamic value) {
    if (_isCrashlyticsEnabled) {
      _crashlytics.setCustomKey(key, value.toString());
    }
  }

  /// Limpa o user ID (logout)
  static void clearUserIdentifier() {
    if (_isCrashlyticsEnabled) {
      _crashlytics.setUserIdentifier('');
    }
  }
}
