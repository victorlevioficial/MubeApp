import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Variantes do chip
enum AppChipVariant { skill, genre, filter }

/// Chip componente do Design System Mube.
///
/// Suporta múltiplas variantes:
/// - [skill]: Chips de habilidades com fundo surface2
/// - [genre]: Chips de gêneros com surfaceHighlight
/// - [filter]: Chips de filtro selecionáveis
///
/// Uso:
/// ```dart
/// AppChip.skill(label: 'Guitarra')
/// AppChip.filter(label: 'Perto de mim', isSelected: true, onTap: () {})
/// ```
class AppChip extends StatelessWidget {
  final String label;
  final AppChipVariant variant;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onDeleted;
  final IconData? icon;

  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.skill,
    this.onTap,
    this.isSelected = false,
    this.onDeleted,
    this.icon,
  });

  /// Chip de habilidade (skill)
  const AppChip.skill({
    super.key,
    required this.label,
    this.onTap,
    this.onDeleted,
  }) : variant = AppChipVariant.skill,
       isSelected = false,
       icon = null;

  /// Chip de gênero
  const AppChip.genre({
    super.key,
    required this.label,
    this.onTap,
    this.onDeleted,
  }) : variant = AppChipVariant.genre,
       isSelected = false,
       icon = null;

  /// Chip de filtro selecionável
  const AppChip.filter({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.onDeleted,
    this.icon,
  }) : variant = AppChipVariant.filter;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppChipVariant.skill:
        return _buildSkillChip();
      case AppChipVariant.genre:
        return _buildGenreChip();
      case AppChipVariant.filter:
        return _buildFilterChip();
    }
  }

  Widget _buildSkillChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildGenreChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFilterChip() {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceHighlight,
          borderRadius: AppRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.s8),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isSelected
                    ? AppTypography.buttonPrimary.fontWeight
                    : AppTypography.labelMedium.fontWeight,
              ),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: AppSpacing.s8),
              GestureDetector(
                onTap: onDeleted,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
