import 'package:flutter/material.dart';
import '../../foundations/app_colors.dart';
import '../../foundations/app_typography.dart';

enum AppChipVariant { skill, genre, filter }

class AppChip extends StatelessWidget {
  final String label;
  final AppChipVariant variant;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onDeleted;

  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.skill,
    this.onTap,
    this.isSelected = false,
    this.onDeleted,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
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
    // Filter chips (like "Perto de mim") often have toggle state
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: AppColors.surfaceHighlight),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
