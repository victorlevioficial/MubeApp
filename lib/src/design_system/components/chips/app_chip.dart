import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_typography.dart';

/// Variantes do chip
enum AppChipVariant { skill, genre, filter, action }

/// Chip componente do Design System Mube.
///
/// Suporta múltiplas variantes:
/// - [skill]: Chips de habilidades com borda
/// - [genre]: Chips de gêneros com fundo destacado
/// - [filter]: Chips de filtro selecionáveis
/// - [action]: Chips de ação clicáveis
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

  /// Chip de ação
  const AppChip.action({super.key, required this.label, this.onTap, this.icon})
    : variant = AppChipVariant.action,
      isSelected = false,
      onDeleted = null;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppChipVariant.skill:
        return _buildSkillChip();
      case AppChipVariant.genre:
        return _buildGenreChip();
      case AppChipVariant.filter:
        return _buildFilterChip();
      case AppChipVariant.action:
        return _buildActionChip();
    }
  }

  Widget _buildSkillChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: AppRadius.circular(AppRadius.r20),
        border: Border.all(color: AppColors.surfaceHighlight, width: 1.2),
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGenreChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.circular(AppRadius.r20),
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterChip() {
    return GestureDetector(
      onTap: onTap,
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
            if (onDeleted != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDeleted,
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

  Widget _buildActionChip() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: AppRadius.circular(AppRadius.r20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
