import 'package:flutter/material.dart';

import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../domain/search_filters.dart';

/// Horizontal category tabs for search filtering.
class CategoryTabs extends StatelessWidget {
  final SearchCategory selectedCategory;
  final ValueChanged<SearchCategory> onCategoryChanged;

  const CategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTab(
            label: 'Todos',
            icon: Icons.people_outline,
            category: SearchCategory.all,
          ),
          const SizedBox(width: 8),
          _buildTab(
            label: 'Profissionais',
            icon: Icons.person_outline,
            category: SearchCategory.professionals,
          ),
          const SizedBox(width: 8),
          _buildTab(
            label: 'Bandas',
            icon: Icons.groups_outlined,
            category: SearchCategory.bands,
          ),
          const SizedBox(width: 8),
          _buildTab(
            label: 'Estúdios',
            icon: Icons.mic_none,
            category: SearchCategory.studios,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required SearchCategory category,
  }) {
    final isSelected = selectedCategory == category;

    return GestureDetector(
      onTap: () => onCategoryChanged(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
