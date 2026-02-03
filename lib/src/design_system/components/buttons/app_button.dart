import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';
import '../interactions/app_animated_press.dart';

enum AppButtonVariant { primary, secondary, outline, ghost }

enum AppButtonSize { small, medium, large }

/// Botão padrão do sistema Mube.
///
/// Suporta variantes (primary, secondary, outline, ghost) e tamanhos.
/// Inclui suporte nativo para estado de loading e ícones.
///
/// Exemplo:
/// ```dart
/// AppButton.primary(
///   text: 'Salvar',
///   onPressed: _save,
///   isLoading: _isSaving,
/// )
/// ```
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  /// Botão com cor de destaque (Brand Primary).
  ///
  /// Use para a ação principal da tela.
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.primary;

  /// Botão com fundo cinza escuro.
  ///
  /// Use para ações secundárias ou "Cancelar".
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.secondary;

  /// Botão transparente com borda.
  ///
  /// Alternativa ao secundário para menor ênfase visual.
  const AppButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.outline;

  /// Botão apenas texto, sem background ou borda.
  ///
  /// Use para links ou ações terciárias.
  const AppButton.ghost({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : variant = AppButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final height = _getHeight();
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    final Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: AppSpacing.s8),
        ],
        Text(text, style: textStyle),
      ],
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            disabledBackgroundColor: AppColors.primaryDisabled,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height / 2),
            ),
            padding: padding,
          ),
          child: buttonContent,
        );
        break;
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceHighlight,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height / 2),
            ),
            padding: padding,
          ),
          child: buttonContent,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.surfaceHighlight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height / 2),
            ),
            padding: padding,
          ),
          child: buttonContent,
        );
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          child: buttonContent,
        );
        break;
    }

    final resultWidget = SizedBox(height: height, child: button);

    if (isFullWidth) {
      return AppAnimatedPress(
        onPressed: isLoading ? null : onPressed,
        child: SizedBox(height: height, width: double.infinity, child: button),
      );
    }

    return AppAnimatedPress(
      onPressed: isLoading ? null : onPressed,
      child: resultWidget,
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 32;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.s12);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.s24);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.s32);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: _getTextColor(),
        );
      case AppButtonSize.medium:
        return AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: _getTextColor(),
        );
      case AppButtonSize.large:
        return AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: _getTextColor(),
        );
    }
  }

  Color _getTextColor() {
    if (onPressed == null) return AppColors.textDisabled;
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.textPrimary;
      case AppButtonVariant.secondary:
        return AppColors.textPrimary;
      case AppButtonVariant.outline:
        return AppColors.textPrimary;
      case AppButtonVariant.ghost:
        return AppColors.textSecondary;
    }
  }

  Color _getLoadingColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.textPrimary;
      default:
        return AppColors.brandPrimary;
    }
  }
}
