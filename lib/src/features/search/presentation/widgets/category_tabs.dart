import 'package:flutter/material.dart';

import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
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
          const SizedBox(width: AppSpacing.s8),
          _buildTab(
            label: 'Profissionais',
            icon: Icons.person_outline,
            category: SearchCategory.professionals,
          ),
          const SizedBox(width: AppSpacing.s8),
          _buildTab(
            label: 'Bandas',
            icon: Icons.groups_outlined,
            category: SearchCategory.bands,
          ),
          const SizedBox(width: AppSpacing.s8),
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
    return AppFilterChip(
      label: label,
      icon: icon,
      isSelected: selectedCategory == category,
      onSelected: (_) => onCategoryChanged(category),
    );
  }
}
