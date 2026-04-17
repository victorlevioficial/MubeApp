import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Indicador de loading do Design System Mube.
///
/// Componente consolidado que substitui o loader legado AppLoading.
///
/// Uso:
/// ```dart
/// AppLoadingIndicator() // Padrão
/// AppLoadingIndicator.small() // Pequeno (16px)
/// AppLoadingIndicator.medium() // Médio (32px)
/// AppLoadingIndicator.large() // Grande (48px)
/// AppLoadingIndicator.withMessage('Carregando...') // Com mensagem
/// ```
class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;
  final String? message;
  final String? semanticLabel;
  final String? semanticHint;

  const AppLoadingIndicator({
    super.key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 2.5,
    this.message,
    this.semanticLabel,
    this.semanticHint,
  });

  /// Loading pequeno para botões inline
  const AppLoadingIndicator.small({super.key, this.color})
    : size = 16,
      strokeWidth = 2,
      message = null,
      semanticLabel = null,
      semanticHint = null;

  /// Loading médio para áreas de conteúdo
  const AppLoadingIndicator.medium({super.key, this.color, this.message})
    : size = 32,
      strokeWidth = 3,
      semanticLabel = null,
      semanticHint = null;

  /// Loading grande para overlays em tela cheia
  const AppLoadingIndicator.large({super.key, this.color, this.message})
    : size = 48,
      strokeWidth = 4,
      semanticLabel = null,
      semanticHint = null;

  /// Loading com mensagem
  const AppLoadingIndicator.withMessage(String msg, {super.key, this.color})
    : size = 32,
      strokeWidth = 3,
      message = msg,
      semanticLabel = null,
      semanticHint = null;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppColors.primary;
    final resolvedLabel = semanticLabel ??
        message ??
        'Carregando';

    return Semantics(
      liveRegion: true,
      label: resolvedLabel,
      hint: semanticHint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.s16),
            ExcludeSemantics(
              child: Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Overlay de loading para bloquear interações durante operações.
class AppLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.child,
    this.isLoading = false,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Semantics(
            liveRegion: true,
            label: message ?? 'Carregando',
            child: Container(
              color: AppColors.background.withValues(alpha: 0.7),
              child: Center(
                child: AppLoadingIndicator.medium(message: message),
              ),
            ),
          ),
      ],
    );
  }
}
