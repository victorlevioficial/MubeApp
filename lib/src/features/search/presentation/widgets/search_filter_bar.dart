import 'package:flutter/material.dart';

import '../../../../design_system/components/chips/mube_filter_chip.dart';
import '../../domain/search_filters.dart';

/// Dynamic horizontal filter bar that shows relevant filters based on category.
/// - Left: Scrollable list of specific filters (e.g. Roles, Instruments).
/// - Right: Sticky "Gêneros" filter button.
class SearchFilterBar extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<ProfessionalSubcategory?> onSubcategoryChanged;
  final ValueChanged<List<String>> onGenresChanged;
  final ValueChanged<List<String>> onInstrumentsChanged;
  final ValueChanged<List<String>> onRolesChanged;
  final ValueChanged<List<String>> onServicesChanged;
  final ValueChanged<String?> onStudioTypeChanged;
  final VoidCallback onOpenGenres;

  const SearchFilterBar({
    super.key,
    required this.filters,
    required this.onSubcategoryChanged,
    required this.onGenresChanged,
    required this.onInstrumentsChanged,
    required this.onRolesChanged,
    required this.onServicesChanged,
    required this.onStudioTypeChanged,
    required this.onOpenGenres,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicChips = _buildDynamicChips();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildGenresChip(context),
          if (dynamicChips.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...dynamicChips,
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDynamicChips() {
    switch (filters.category) {
      case SearchCategory.professionals:
        return [
          _buildSubcategoryChip('Cantor', ProfessionalSubcategory.singer),
          const SizedBox(width: 8),
          _buildSubcategoryChip(
            'Instrumentista',
            ProfessionalSubcategory.instrumentalist,
          ),
          const SizedBox(width: 8),
          _buildSubcategoryChip('DJ', ProfessionalSubcategory.dj),
          const SizedBox(width: 8),
          _buildSubcategoryChip('Equipe Técnica', ProfessionalSubcategory.crew),
        ];

      case SearchCategory.bands:
        return [];

      case SearchCategory.studios:
        return [
          _buildSelectableChip('Gravação', 'recording', isService: true),
          const SizedBox(width: 8),
          _buildSelectableChip('Ensaio', 'rehearsal', isService: true),
          const SizedBox(width: 8),
          _buildSelectableChip('Mix/Master', 'mix_master', isService: true),
        ];

      case SearchCategory.all:
        return [];
    }
  }

  Widget _buildSubcategoryChip(String label, ProfessionalSubcategory value) {
    final isSelected = filters.professionalSubcategory == value;

    return MubeFilterChip(
      label: label,
      isSelected: isSelected,
      onSelected: (selected) {
        onSubcategoryChanged(selected ? value : null);
      },
    );
  }

  Widget _buildSelectableChip(
    String label,
    String value, {
    bool isRole = false,
    bool isService = false,
  }) {
    bool isSelected = false;

    if (isRole) {
      isSelected = filters.roles.contains(value);
    } else if (isService) {
      isSelected = filters.services.contains(value);
    }

    return MubeFilterChip(
      label: label,
      isSelected: isSelected,
      onSelected: (_) {
        if (isRole) {
          final newRoles = List<String>.from(filters.roles);
          if (isSelected) {
            newRoles.remove(value);
          } else {
            newRoles.add(value);
          }
          onRolesChanged(newRoles);
        } else if (isService) {
          final newServices = List<String>.from(filters.services);
          if (isSelected) {
            newServices.remove(value);
          } else {
            newServices.add(value);
          }
          onServicesChanged(newServices);
        }
      },
    );
  }

  Widget _buildGenresChip(BuildContext context) {
    final hasGenres = filters.genres.isNotEmpty;
    // We trigger the modal via callback in SearchScreen usually,
    // but here we might need to expose a specific "Open Genres" callback
    // OR we rely on the main "Filters" button in SearchScreen.
    // However, the user request specifically asked for "Gêneros" chip
    // to be always visible on the right.

    // Since we don't have a direct "onOpenGenres" callback passed,
    // I will assume we can simulate tapping the main filter button
    // or we should update the `FilterModal` to open focused on Genres?
    // For now, let's treat it as a trigger for the general subcategory changes
    // or pass a new callback for opening the modal?

    // Wait, the `SearchScreen` has `_showFilterModal`.
    // I need to properly hook this up.
    // The previous implementation used `FilterChipsRow` which accepted `onGenresChanged`.
    // But `FilterChipsRow` didn't seem to open a modal, it likely just showed chips?
    // Ah, previous file was MISSING. I am inferring functionality.

    // To properly support "Opening Genres Modal", I should probably
    // let the parent handle the interaction.
    // But since I can't change the parent signature easily without seeing it...
    // Let's assume this chip is just a visual indicator/shortcut?
    // No, user said "Gêneros tem que estar sempre visivel".

    // I'll add an `VoidCallback onOpenFilters` to this widget constructor
    // so we can open the modal from here.

    return MubeFilterChip(
      label: 'Gêneros',
      icon: Icons.music_note,
      isSelected: hasGenres,
      onSelected: (_) => onOpenGenres(),
      // Actually, I control this file. I can add `VoidCallback onOpenFilters`
      // and pass `_showFilterModal` from the screen.
    );
  }
}
