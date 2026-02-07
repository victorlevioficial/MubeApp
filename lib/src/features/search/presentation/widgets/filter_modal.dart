import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/components/chips/mube_filter_chip.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/search_filters.dart';

/// Modal for advanced filter options.
class FilterModal extends ConsumerStatefulWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onApply;

  const FilterModal({super.key, required this.filters, required this.onApply});

  @override
  ConsumerState<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends ConsumerState<FilterModal> {
  late List<String> _selectedGenres;
  late List<String> _selectedInstruments;
  late List<String> _selectedRoles;
  late List<String> _selectedServices;
  late String? _studioType;
  late bool? _canDoBackingVocal;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.filters.genres);
    _selectedInstruments = List.from(widget.filters.instruments);
    _selectedRoles = List.from(widget.filters.roles);
    _selectedServices = List.from(widget.filters.services);
    _studioType = widget.filters.studioType;
    _canDoBackingVocal = widget.filters.canDoBackingVocal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.top24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.s12),
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.border,
              borderRadius: AppRadius.all4,
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtros', style: AppTypography.headlineSmall),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    'Limpar',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genres
                  _buildSection(
                    title: 'Gêneros Musicais',
                    options: ref.watch(genreLabelsProvider),
                    selected: _selectedGenres,
                    onChanged: (v) => setState(() => _selectedGenres = v),
                  ),

                  const SizedBox(height: AppSpacing.s24),

                  // Instruments (for professionals)
                  if (widget.filters.category == SearchCategory.professionals)
                    _buildSection(
                      title: 'Instrumentos',
                      options: ref.watch(instrumentLabelsProvider),
                      selected: _selectedInstruments,
                      onChanged: (v) =>
                          setState(() => _selectedInstruments = v),
                    ),

                  if (widget.filters.category == SearchCategory.professionals)
                    const SizedBox(height: AppSpacing.s24),

                  // Crew Roles (for professionals)
                  if (widget.filters.category == SearchCategory.professionals)
                    _buildSection(
                      title: 'Funções (Crew)',
                      options: ref.watch(crewRoleLabelsProvider),
                      selected: _selectedRoles,
                      onChanged: (v) => setState(() => _selectedRoles = v),
                    ),

                  // Studio Services
                  if (widget.filters.category == SearchCategory.studios)
                    _buildSection(
                      title: 'Serviços',
                      options: ref.watch(studioServiceLabelsProvider),
                      selected: _selectedServices,
                      onChanged: (v) => setState(() => _selectedServices = v),
                    ),

                  // Backing Vocal Filter (for professionals)
                  if (widget.filters.category == SearchCategory.professionals)
                    _buildBackingVocalFilter(),

                  const SizedBox(height: AppSpacing.s32),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: AppButton.primary(
                    text: 'Aplicar',
                    onPressed: _applyFilters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return AppFilterChip(
              label: option,
              isSelected: isSelected,
              onSelected: (value) {
                final newList = List<String>.from(selected);
                if (value) {
                  newList.add(option);
                } else {
                  newList.remove(option);
                }
                onChanged(newList);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBackingVocalFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.s24),
        Text('Backing Vocal', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            MubeFilterChip(
              label: 'Qualquer',
              isSelected: _canDoBackingVocal == null,
              onSelected: (_) => setState(() => _canDoBackingVocal = null),
            ),
            const SizedBox(width: AppSpacing.s8),
            MubeFilterChip(
              label: 'Faz backing',
              isSelected: _canDoBackingVocal == true,
              onSelected: (_) => setState(() => _canDoBackingVocal = true),
            ),
          ],
        ),
      ],
    );
  }

  void _clearAll() {
    setState(() {
      _selectedGenres.clear();
      _selectedInstruments.clear();
      _selectedRoles.clear();
      _selectedServices.clear();
      _studioType = null;
      _canDoBackingVocal = null;
    });
  }

  void _applyFilters() {
    final newFilters = widget.filters.copyWith(
      genres: _selectedGenres,
      instruments: _selectedInstruments,
      roles: _selectedRoles,
      services: _selectedServices,
      studioType: _studioType,
      canDoBackingVocal: _canDoBackingVocal,
    );
    widget.onApply(newFilters);
    Navigator.pop(context);
  }
}
