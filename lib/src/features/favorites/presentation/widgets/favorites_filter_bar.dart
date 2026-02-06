import 'package:flutter/material.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

class FavoritesFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const FavoritesFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final List<String> _filters = const [
    'Todos',
    'Músicos',
    'Bandas',
    'Estúdios',
    'Perto de mim',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.s40,
      child: ListView.separated(
        padding: AppSpacing.h16,
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: AppRadius.pill,
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.border, width: 1),
              ),
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  filter,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? AppTypography.buttonPrimary.fontWeight
                        : AppTypography.labelMedium.fontWeight,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
