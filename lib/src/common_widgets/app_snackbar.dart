import 'package:flutter/material.dart';

import '../app.dart' show scaffoldMessengerKey;
import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_radius.dart';
import '../design_system/foundations/app_spacing.dart';

/// Semantic snackbar types for consistent styling.
enum SnackBarType { success, error, info, warning }

/// A themed snackbar system for consistent user feedback.
///
/// Provides semantic methods for different message types:
/// - [success] - Green, for successful operations
/// - [error] - Red, for errors and failures
/// - [info] - Blue, for informational messages
/// - [warning] - Orange, for warnings
///
/// Example:
/// ```dart
/// AppSnackBar.success(context, 'Perfil atualizado!');
/// AppSnackBar.error(context, 'Falha ao salvar');
/// ```
class AppSnackBar {
  // Private constructor to prevent instantiation
  const AppSnackBar._();

  // ---------------------------------------------------------------------------
  // Semantic Colors - Using Design System
  // ---------------------------------------------------------------------------
  static const Color _successColor = AppColors.success;
  static const Color _errorColor = AppColors.error;
  static const Color _infoColor = AppColors.info;
  static const Color _warningColor = AppColors.warning;

  // ---------------------------------------------------------------------------
  // Public API - Semantic Methods
  // ---------------------------------------------------------------------------

  /// Shows a success snackbar (green).
  static void success(BuildContext context, String message) {
    _show(context, message, SnackBarType.success);
  }

  /// Shows an error snackbar (red).
  static void error(BuildContext context, String message) {
    _show(context, message, SnackBarType.error);
  }

  /// Shows an info snackbar (blue).
  static void info(BuildContext context, String message) {
    _show(context, message, SnackBarType.info);
  }

  /// Shows a warning snackbar (orange).
  static void warning(BuildContext context, String message) {
    _show(context, message, SnackBarType.warning);
  }

  /// Legacy method for backward compatibility.
  /// Use [success] or [error] instead for new code.
  static void show(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    _show(
      context,
      message,
      isError ? SnackBarType.error : SnackBarType.success,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal Implementation
  // ---------------------------------------------------------------------------

  static void _show(BuildContext context, String message, SnackBarType type) {
    // Use global messenger key if available (persists across navigation)
    // Fall back to context-based messenger for compatibility
    final messenger =
        scaffoldMessengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);

    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final (color, icon) = _getStyle(type);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all12,
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
        ),
        margin: AppSpacing.all16,
        elevation: 4,
        duration: _getDuration(type),
      ),
    );
  }

  static (Color, IconData) _getStyle(SnackBarType type) {
    return switch (type) {
      SnackBarType.success => (_successColor, Icons.check_circle_outline),
      SnackBarType.error => (_errorColor, Icons.error_outline),
      SnackBarType.info => (_infoColor, Icons.info_outline),
      SnackBarType.warning => (_warningColor, Icons.warning_amber_outlined),
    };
  }

  static Duration _getDuration(SnackBarType type) {
    return switch (type) {
      SnackBarType.error => const Duration(seconds: 5),
      SnackBarType.warning => const Duration(seconds: 4),
      _ => const Duration(seconds: 3),
    };
  }
}

// ---------------------------------------------------------------------------
// Predefined Messages
// ---------------------------------------------------------------------------

/// Centralized message constants for consistency.
abstract final class AppMessages {
  // Auth
  static const String loginSuccess = 'Login realizado com sucesso!';
  static const String loginError = 'Email ou senha incorretos';
  static const String registerSuccess = 'Conta criada com sucesso!';
  static const String registerError = 'Erro ao criar conta';
  static const String logoutSuccess = 'Você saiu da sua conta';
  static const String sessionExpired = 'Sessão expirada. Faça login novamente';
  static const String emailVerification = 'Verifique seu email para confirmar';

  // Profile
  static const String profileUpdateSuccess = 'Perfil atualizado com sucesso!';
  static const String profileUpdateError = 'Erro ao atualizar perfil';
  static const String profileIncomplete = 'Por favor, complete seu cadastro';

  // Validation
  static const String fieldRequired = 'Por favor, preencha todos os campos';
  static const String invalidEmail = 'Email inválido';
  static const String passwordMismatch = 'As senhas não coincidem';
  static const String passwordTooShort =
      'A senha deve ter no mínimo 6 caracteres';

  // Network
  static const String networkError = 'Erro de conexão. Verifique sua internet';
  static const String serverError = 'Erro no servidor. Tente novamente';
  static const String unknownError = 'Ocorreu um erro inesperado';
}
