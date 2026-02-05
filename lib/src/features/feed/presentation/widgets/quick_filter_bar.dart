import 'package:flutter/material.dart';
import '../../../../design_system/components/chips/mube_filter_chip.dart';

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
    'Profissionais',
    'Bandas',
    'Estúdios',
    'Perto de mim',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedFilter == filter;

          return Center(
            child: MubeFilterChip(
              label: filter,
              isSelected: isSelected,
              icon: _getFilterIcon(filter),
              onTap: () => onFilterSelected(filter),
            ),
          );
        },
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Todos':
        return Icons.people_outline;
      case 'Profissionais':
        return Icons.person_outline_rounded;
      case 'Bandas':
        return Icons.groups_outlined;
      case 'Estúdios':
        return Icons.mic_none_outlined;
      case 'Perto de mim':
        return Icons.location_on_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
