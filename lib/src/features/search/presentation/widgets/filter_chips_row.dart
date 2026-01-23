import 'package:flutter/material.dart';

import '../../../../common_widgets/app_selection_modal.dart';
import '../../../../constants/app_constants.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../domain/search_filters.dart';

/// Dynamic filter chips that change based on selected category.
class FilterChipsRow extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<ProfessionalSubcategory?> onSubcategoryChanged;
  final ValueChanged<List<String>> onGenresChanged;
  final ValueChanged<List<String>> onInstrumentsChanged;
  final ValueChanged<List<String>> onRolesChanged;
  final ValueChanged<List<String>> onServicesChanged;
  final ValueChanged<String?> onStudioTypeChanged;

  const FilterChipsRow({
    super.key,
    required this.filters,
    required this.onSubcategoryChanged,
    required this.onGenresChanged,
    required this.onInstrumentsChanged,
    required this.onRolesChanged,
    required this.onServicesChanged,
    required this.onStudioTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: _buildChips(context)),
    );
  }

  List<Widget> _buildChips(BuildContext context) {
    final chips = <Widget>[];

    switch (filters.category) {
      case SearchCategory.professionals:
        // Subcategory chips
        chips.addAll(_buildProfessionalSubcategoryChips());
        chips.add(const SizedBox(width: 8));
        // Genres button
        chips.add(
          _buildMultiSelectChip(
            context: context,
            label: 'Gêneros',
            icon: Icons.music_note,
            selected: filters.genres,
            options: genres,
            onChanged: onGenresChanged,
          ),
        );
        // Instruments (if instrumentalist selected)
        if (filters.professionalSubcategory ==
            ProfessionalSubcategory.instrumentalist) {
          chips.add(const SizedBox(width: 8));
          chips.add(
            _buildMultiSelectChip(
              context: context,
              label: 'Instrumentos',
              icon: Icons.piano,
              selected: filters.instruments,
              options: instruments,
              onChanged: onInstrumentsChanged,
            ),
          );
        }
        // Roles (if crew selected)
        if (filters.professionalSubcategory == ProfessionalSubcategory.crew) {
          chips.add(const SizedBox(width: 8));
          chips.add(
            _buildMultiSelectChip(
              context: context,
              label: 'Funções',
              icon: Icons.work_outline,
              selected: filters.roles,
              options: crewRoles,
              onChanged: onRolesChanged,
            ),
          );
        }
        break;

      case SearchCategory.bands:
        // Genres only
        chips.add(
          _buildMultiSelectChip(
            context: context,
            label: 'Gêneros',
            icon: Icons.music_note,
            selected: filters.genres,
            options: genres,
            onChanged: onGenresChanged,
          ),
        );
        break;

      case SearchCategory.studios:
        // Studio type chips
        chips.addAll(_buildStudioTypeChips());
        chips.add(const SizedBox(width: 8));
        // Services
        chips.add(
          _buildMultiSelectChip(
            context: context,
            label: 'Serviços',
            icon: Icons.build_outlined,
            selected: filters.services,
            options: studioServices,
            onChanged: onServicesChanged,
          ),
        );
        break;

      case SearchCategory.all:
        // Genres only for "all"
        chips.add(
          _buildMultiSelectChip(
            context: context,
            label: 'Gêneros',
            icon: Icons.music_note,
            selected: filters.genres,
            options: genres,
            onChanged: onGenresChanged,
          ),
        );
        break;
    }

    return chips;
  }

  List<Widget> _buildProfessionalSubcategoryChips() {
    return [
      _buildSubcategoryChip(
        label: 'Cantor',
        icon: Icons.mic,
        subcategory: ProfessionalSubcategory.singer,
      ),
      const SizedBox(width: 8),
      _buildSubcategoryChip(
        label: 'Instrumentista',
        icon: Icons.piano,
        subcategory: ProfessionalSubcategory.instrumentalist,
      ),
      const SizedBox(width: 8),
      _buildSubcategoryChip(
        label: 'Equipe Técnica',
        icon: Icons.build,
        subcategory: ProfessionalSubcategory.crew,
      ),
      const SizedBox(width: 8),
      _buildSubcategoryChip(
        label: 'DJ',
        icon: Icons.album,
        subcategory: ProfessionalSubcategory.dj,
      ),
    ];
  }

  Widget _buildSubcategoryChip({
    required String label,
    required IconData icon,
    required ProfessionalSubcategory subcategory,
  }) {
    final isSelected = filters.professionalSubcategory == subcategory;

    return GestureDetector(
      onTap: () => onSubcategoryChanged(isSelected ? null : subcategory),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudioTypeChips() {
    return [
      _buildStudioTypeChip(label: 'Home Studio', value: 'home_studio'),
      const SizedBox(width: 8),
      _buildStudioTypeChip(label: 'Comercial', value: 'commercial'),
    ];
  }

  Widget _buildStudioTypeChip({required String label, required String value}) {
    final isSelected = filters.studioType == value;

    return GestureDetector(
      onTap: () => onStudioTypeChanged(isSelected ? null : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required List<String> selected,
    required List<String> options,
    required ValueChanged<List<String>> onChanged,
  }) {
    final hasSelection = selected.isNotEmpty;
    final displayLabel = hasSelection ? '$label (${selected.length})' : label;

    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AppSelectionModal(
            title: label,
            items: options,
            selectedItems: selected,
            allowMultiple: true,
          ),
        );
        if (result != null) {
          onChanged(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasSelection
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelection ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: hasSelection ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 13,
                color: hasSelection
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: hasSelection ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
