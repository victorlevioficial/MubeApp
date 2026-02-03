import 'package:flutter/material.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

class QuickFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const QuickFilterBar({
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
      height: 44, // Tight height for filter chips
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ), // No vertical padding
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPrimary : AppColors.surface,
                borderRadius: BorderRadius.circular(100),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.border, width: 1),
              ),
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  filter,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
