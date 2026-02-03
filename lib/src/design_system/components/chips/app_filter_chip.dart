import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_typography.dart';

/// Chip de filtro selecionável do Design System.
///
/// Use [AppChip.filter] para novos componentes.
class AppFilterChip extends StatelessWidget {
  /// Texto exibido no chip.
  final String label;

  /// Se o chip está selecionado (ativo).
  final bool isSelected;

  /// Callback simples de toque (opcional se usar onSelected).
  final VoidCallback? onTap;

  /// Callback que retorna o novo estado booleano.
  final ValueChanged<bool>? onSelected;

  /// Callback para remover o chip (exibe ícone 'X').
  final VoidCallback? onRemove;

  /// Ícone opcional à esquerda do texto.
  final IconData? icon;

  const AppFilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onSelected,
    this.onRemove,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        onSelected?.call(!isSelected);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : AppColors.surface,
          borderRadius: AppRadius.circular(AppRadius.r24),
          border: isSelected
              ? null
              : Border.all(color: AppColors.surfaceHighlight, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
