import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Utilitário centralizado para logs da aplicação.
///
/// Use esta classe em vez de `print()` para garantir que:
/// 1. Os logs possam ser desativados em produção automaticamente.
/// 2. Tenhamos rastreabilidade (nome do logger).
/// 3. Possamos futuramente integrar com serviços como Crashlytics/Sentry facilmente.
class AppLogger {
  const AppLogger._();

  /// Log de debug simples (informativo)
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'MubeApp ℹ️',
        error: error,
        stackTrace: stackTrace,
        level: 800, // INFO
      );
    }
  }

  /// Log de erro (algo deu errado)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // Em produção, aqui poderíamos enviar para o Crashlytics
    if (kDebugMode) {
      developer.log(
        message,
        name: 'MubeApp 🚨',
        error: error,
        stackTrace: stackTrace,
        level: 1000, // SEVERE
      );
    }
  }

  /// Log de warning (atenção)
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
  }
}
