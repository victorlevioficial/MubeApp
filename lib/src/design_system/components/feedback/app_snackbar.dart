import 'package:flutter/material.dart';

import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Semantic snackbar types for consistent styling.
enum SnackBarType { success, error, info, warning }

/// A themed snackbar system for consistent user feedback.
class AppSnackBar {
  // Private constructor to prevent instantiation
  const AppSnackBar._();

  static const Color _successColor = AppColors.success;
  static const Color _errorColor = AppColors.error;
  static const Color _infoColor = AppColors.info;
  static const Color _warningColor = AppColors.warning;

  static void success(BuildContext context, String message) {
    _show(context, message, SnackBarType.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, SnackBarType.error);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, SnackBarType.info);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, SnackBarType.warning);
  }

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

  static void _show(BuildContext _, String message, SnackBarType type) {
    final messenger = scaffoldMessengerKey.currentState;
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
                style: AppTypography.bodyMedium.copyWith(
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

abstract final class AppMessages {
  static const String loginSuccess = 'Login realizado com sucesso!';
  static const String loginError = 'Email ou senha incorretos';
  static const String registerSuccess = 'Conta criada com sucesso!';
  static const String registerError = 'Erro ao criar conta';
  static const String logoutSuccess = 'Você saiu da sua conta';
  static const String sessionExpired = 'Sessão expirada. Faça login novamente';
  static const String emailVerification = 'Verifique seu email para confirmar';
  static const String profileUpdateSuccess = 'Perfil atualizado com sucesso!';
  static const String profileUpdateError = 'Erro ao atualizar perfil';
  static const String profileIncomplete = 'Por favor, complete seu cadastro';
  static const String fieldRequired = 'Por favor, preencha todos os campos';
  static const String invalidEmail = 'Email inválido';
  static const String passwordMismatch = 'As senhas não coincidem';
  static const String passwordTooShort =
      'A senha deve ter no mínimo 6 caracteres';
  static const String networkError = 'Erro de conexão. Verifique sua internet';
  static const String serverError = 'Erro no servidor. Tente novamente';
  static const String unknownError = 'Ocorreu um erro inesperado';
}
