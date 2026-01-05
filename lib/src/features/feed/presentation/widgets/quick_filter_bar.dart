import 'package:flutter/material.dart';
import '../../../../design_system/foundations/app_colors.dart';

class QuickFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const QuickFilterBar({
    Key? key,
    required this.selectedFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  final List<String> _filters = const [
    'Todos',
    'Músicos',
    'Bandas',
    'Estúdios',
    'Perto de mim',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.background, // Background match for sticky header
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedFilter == filter;

          // Map display name to internal value if needed,
          // or just use display name for logic in screen (simplest for MVP)

          return ActionChip(
            label: Text(filter),
            onPressed: () => onFilterSelected(filter),
            backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceHighlight,
              ),
            ),
          );
        },
      ),
    );
  }
}
