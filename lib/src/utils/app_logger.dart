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

  static bool get verboseLoggingEnabled =>
      kDebugMode && _enableVerboseDebugLogs;

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
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'MubeApp 🚨',
        error: error,
        stackTrace: stackTrace,
        level: 1000, // SEVERE
      );
    }

    if (_isCrashlyticsEnabled) {
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

  /// Log de erro do framework Flutter
  static void recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) {
    if (kDebugMode) {
      developer.log(
        'Flutter Framework Error',
        name: fatal ? 'MubeApp 💥 FATAL' : 'MubeApp 🚨',
        error: details.exception,
        stackTrace: details.stack,
        level: fatal ? 1200 : 1000,
      );
    }

    if (_isCrashlyticsEnabled) {
      if (fatal) {
        _crashlytics.recordFlutterFatalError(details);
      } else {
        _crashlytics.recordFlutterError(details);
      }
    }
  }

  /// Log de debug (desenvolvimento)
  /// Apenas em modo debug, não envia ao Crashlytics
  static void debug(String message) {
    if (verboseLoggingEnabled) {
      developer.log(
        message,
        name: 'MubeApp 🐛',
        level: 500, // FINE
      );
    }
  }

  /// Log de warning (atenção)
  /// Em produção, envia como log não-crítico ao Crashlytics
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'MubeApp ⚠️',
        error: error,
        stackTrace: stackTrace,
        level: 900, // WARNING
      );
    }

    if (_isCrashlyticsEnabled) {
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
