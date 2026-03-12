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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadius.all24,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s16,
              AppSpacing.s20,
              AppSpacing.s20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ──────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppRadius.pill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                // ── Header ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtros',
                        style: AppTypography.headlineSmall,
                      ),
                    ),
                    if (_filters.hasActiveFilters)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s10,
                          vertical: AppSpacing.s4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: AppRadius.pill,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${_filters.activeFilterCount} ativo${_filters.activeFilterCount == 1 ? '' : 's'}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                // ── Scrollable body ──────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FilterSection(
                          title: 'Status',
                          child: _buildChoiceSection<GigStatus>(
                            values: GigStatus.values,
                            selected: _filters.statuses.toSet(),
                            labelOf: (item) => item.label,
                            onToggle: (item) {
                              final next = _toggleMulti(
                                _filters.statuses,
                                item,
                              );
                              setState(
                                () => _filters = _filters.copyWith(
                                  statuses: next,
                                ),
                              );
                            },
                          ),
                        ),
                        const _FilterDivider(),
                        _FilterSection(
                          title: 'Tipo de gig',
                          child: _buildChoiceSection<GigType>(
                            values: GigType.values,
                            selected: _filters.gigTypes.toSet(),
                            labelOf: (item) => item.label,
                            onToggle: (item) {
                              final next = _toggleMulti(
                                _filters.gigTypes,
                                item,
                              );
                              setState(
                                () => _filters = _filters.copyWith(
                                  gigTypes: next,
                                ),
                              );
                            },
                          ),
                        ),
                        const _FilterDivider(),
                        _FilterSection(
                          title: 'Modalidade',
                          child: _buildChoiceSection<GigLocationType>(
                            values: GigLocationType.values,
                            selected: _filters.locationTypes.toSet(),
                            labelOf: (item) => item.label,
                            onToggle: (item) {
                              final next = _toggleMulti(
                                _filters.locationTypes,
                                item,
                              );
                              setState(
                                () => _filters = _filters.copyWith(
                                  locationTypes: next,
                                ),
                              );
                            },
                          ),
                        ),
                        const _FilterDivider(),
                        _FilterSection(
                          title: 'Cachê',
                          child: _buildChoiceSection<CompensationType>(
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
                        ),
                        const _FilterDivider(),
                        _FilterSection(
                          title: 'Gêneros',
                          child: _ConfigSelector(
                            title: 'Gêneros',
                            subtitle: 'Selecione os estilos desejados',
                            items: widget.config.genres,
                            selectedIds: _filters.genres,
                            onChanged: (next) {
                              setState(
                                () =>
                                    _filters = _filters.copyWith(genres: next),
                              );
                            },
                          ),
                        ),
                        const _FilterDivider(),
                        _FilterSection(
                          title: 'Instrumentos',
                          child: _ConfigSelector(
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
                        ),
                        const _FilterDivider(),
                        _FilterSection(
                          title: 'Funções técnicas',
                          child: _ConfigSelector(
                            title: 'Funções técnicas',
                            subtitle: 'Selecione as funções requisitadas',
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
                        ),
                        const _FilterDivider(),
                        _FilterSection(
                          title: 'Serviços de estúdio',
                          child: _ConfigSelector(
                            title: 'Serviços de estúdio',
                            subtitle: 'Selecione os serviços desejados',
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
                        ),
                        const _FilterDivider(),
                        // ── Toggle ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Apenas com vaga',
                                      style: AppTypography.labelLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.s2),
                                    Text(
                                      'Ocultar gigs sem vagas disponíveis',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _filters.onlyOpenSlots,
                                activeTrackColor: AppColors.primary.withValues(
                                  alpha: 0.3,
                                ),
                                activeThumbColor: AppColors.primary,
                                inactiveThumbColor: AppColors.textTertiary,
                                inactiveTrackColor: AppColors.surfaceHighlight,
                                onChanged: (value) {
                                  setState(
                                    () => _filters = _filters.copyWith(
                                      onlyOpenSlots: value,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                      ],
                    ),
                  ),
                ),
                // ── Actions ───────────────────────────────────────────
                const SizedBox(height: AppSpacing.s12),
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
                      flex: 2,
                      child: AppButton.primary(
                        text: 'Aplicar filtros',
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
    required List<T> values,
    required Set<T> selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onToggle,
  }) {
    return Wrap(
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
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTypography.settingsGroupTitle),
          const SizedBox(height: AppSpacing.s10),
          child,
        ],
      ),
    );
  }
}

class _FilterDivider extends StatelessWidget {
  const _FilterDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, height: 1, thickness: 1);
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s14,
              vertical: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all12,
              border: Border.all(
                color: selectedItems.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItems.isEmpty
                        ? 'Selecionar'
                        : '${selectedItems.length} selecionado${selectedItems.length == 1 ? '' : 's'}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: selectedItems.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
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
