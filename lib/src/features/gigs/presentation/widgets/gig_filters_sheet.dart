import 'package:flutter/material.dart';

import '../../../../core/domain/app_config.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_chip.dart';
import '../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/compensation_type.dart';
import '../../domain/gig_filters.dart';
import '../../domain/gig_location_type.dart';
import '../../domain/gig_status.dart';
import '../../domain/gig_type.dart';

class GigFiltersSheet extends StatefulWidget {
  const GigFiltersSheet({
    super.key,
    required this.initialFilters,
    required this.config,
  });

  final GigFilters initialFilters;
  final AppConfig config;

  @override
  State<GigFiltersSheet> createState() => _GigFiltersSheetState();
}

class _GigFiltersSheetState extends State<GigFiltersSheet> {
  late GigFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadius.all24,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros de gigs',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _buildChoiceSection<GigStatus>(
                    title: 'Status',
                    values: GigStatus.values,
                    selected: _filters.statuses.toSet(),
                    labelOf: (item) => item.label,
                    onToggle: (item) {
                      final next = _toggleMulti(_filters.statuses, item);
                      setState(
                        () => _filters = _filters.copyWith(statuses: next),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _buildChoiceSection<GigType>(
                    title: 'Tipo de gig',
                    values: GigType.values,
                    selected: _filters.gigTypes.toSet(),
                    labelOf: (item) => item.label,
                    onToggle: (item) {
                      final next = _toggleMulti(_filters.gigTypes, item);
                      setState(
                        () => _filters = _filters.copyWith(gigTypes: next),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _buildChoiceSection<GigLocationType>(
                    title: 'Modalidade',
                    values: GigLocationType.values,
                    selected: _filters.locationTypes.toSet(),
                    labelOf: (item) => item.label,
                    onToggle: (item) {
                      final next = _toggleMulti(_filters.locationTypes, item);
                      setState(
                        () => _filters = _filters.copyWith(locationTypes: next),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _buildChoiceSection<CompensationType>(
                    title: 'Cache',
                    values: CompensationType.values,
                    selected: _filters.compensationTypes.toSet(),
                    labelOf: (item) => item.label,
                    onToggle: (item) {
                      final next = _toggleMulti(
                        _filters.compensationTypes,
                        item,
                      );
                      setState(
                        () => _filters = _filters.copyWith(
                          compensationTypes: next,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _ConfigSelector(
                    title: 'Generos',
                    subtitle: 'Selecione os estilos desejados',
                    items: widget.config.genres,
                    selectedIds: _filters.genres,
                    onChanged: (next) {
                      setState(
                        () => _filters = _filters.copyWith(genres: next),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _ConfigSelector(
                    title: 'Instrumentos',
                    subtitle: 'Selecione os instrumentos requisitados',
                    items: widget.config.instruments,
                    selectedIds: _filters.requiredInstruments,
                    onChanged: (next) {
                      setState(
                        () => _filters = _filters.copyWith(
                          requiredInstruments: next,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _ConfigSelector(
                    title: 'Funcoes tecnicas',
                    subtitle: 'Selecione as funcoes requisitadas',
                    items: widget.config.crewRoles,
                    selectedIds: _filters.requiredCrewRoles,
                    onChanged: (next) {
                      setState(
                        () => _filters = _filters.copyWith(
                          requiredCrewRoles: next,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _ConfigSelector(
                    title: 'Servicos de estudio',
                    subtitle: 'Selecione os servicos desejados',
                    items: widget.config.studioServices,
                    selectedIds: _filters.requiredStudioServices,
                    onChanged: (next) {
                      setState(
                        () => _filters = _filters.copyWith(
                          requiredStudioServices: next,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  SwitchListTile.adaptive(
                    value: _filters.onlyOpenSlots,
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    activeThumbColor: AppColors.primary,
                    title: Text(
                      'Mostrar apenas gigs com vaga',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onChanged: (value) {
                      setState(
                        () =>
                            _filters = _filters.copyWith(onlyOpenSlots: value),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.outline(
                          text: 'Limpar',
                          onPressed: () {
                            setState(() => _filters = const GigFilters());
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: AppButton.primary(
                          text: 'Aplicar',
                          onPressed: () => Navigator.of(context).pop(_filters),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<T> _toggleMulti<T>(List<T> current, T value) {
    final next = current.toList(growable: true);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return next;
  }

  Widget _buildChoiceSection<T>({
    required String title,
    required List<T> values,
    required Set<T> selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: values
              .map((item) {
                return AppChip.filter(
                  label: labelOf(item),
                  isSelected: selected.contains(item),
                  onTap: () => onToggle(item),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _ConfigSelector extends StatelessWidget {
  const _ConfigSelector({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final List<ConfigItem> items;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedItems = items
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        InkWell(
          onTap: () async {
            final result = await EnhancedMultiSelectModal.show<ConfigItem>(
              context: context,
              title: title,
              subtitle: subtitle,
              items: items,
              selectedItems: selectedItems,
              itemLabel: (item) => item.label,
            );
            if (result == null) return;
            onChanged(result.map((item) => item.id).toList(growable: false));
          },
          borderRadius: AppRadius.all12,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all12,
            ),
            child: Text(
              selectedItems.isEmpty
                  ? 'Selecionar'
                  : '${selectedItems.length} selecionados',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s10),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: selectedItems
                .map((item) => AppChip.skill(label: item.label))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
