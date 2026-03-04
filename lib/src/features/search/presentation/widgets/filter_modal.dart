import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/search_filters.dart';

class FilterModal extends ConsumerStatefulWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onApply;

  const FilterModal({super.key, required this.filters, required this.onApply});

  @override
  ConsumerState<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends ConsumerState<FilterModal> {
  late ProfessionalSubcategory? _professionalSubcategory;
  late List<String> _selectedGenres;
  late List<String> _selectedInstruments;
  late List<String> _selectedRoles;
  late List<String> _selectedServices;
  late String? _studioType;
  late bool? _canDoBackingVocal;

  @override
  void initState() {
    super.initState();
    _professionalSubcategory = widget.filters.professionalSubcategory;
    _selectedGenres = List<String>.from(widget.filters.genres);
    _selectedInstruments = List<String>.from(widget.filters.instruments);
    _selectedRoles = List<String>.from(widget.filters.roles);
    _selectedServices = List<String>.from(widget.filters.services);
    _studioType = widget.filters.studioType;
    _canDoBackingVocal = widget.filters.canDoBackingVocal;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_professionalSubcategory != null) count++;
    if (_selectedGenres.isNotEmpty) count++;
    if (_selectedInstruments.isNotEmpty) count++;
    if (_selectedRoles.isNotEmpty) count++;
    if (_selectedServices.isNotEmpty) count++;
    if (_studioType != null) count++;
    if (_canDoBackingVocal != null) count++;
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  @override
  Widget build(BuildContext context) {
    final category = widget.filters.category;
    final isAll = category == SearchCategory.all;
    final isProfessional = category == SearchCategory.professionals || isAll;
    final isStudio = category == SearchCategory.studios || isAll;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.top24,
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: maxHeight,
          child: Column(
            children: [
              _FilterSheetHeader(
                activeFilterCount: _activeFilterCount,
                onClearAll: _hasActiveFilters ? _clearAll : null,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s24,
                  ),
                  children: [
                    if (isProfessional) ...[
                      _FilterSection(
                        title: 'Perfil profissional',
                        subtitle:
                            'Escolha a especialidade principal para a busca.',
                        child: _FilterPanel(child: _buildSubcategoryChips()),
                      ),
                      const SizedBox(height: AppSpacing.s20),
                    ],
                    if (isStudio) ...[
                      _FilterSection(
                        title: 'Tipo de estudio',
                        subtitle: 'Defina o tipo de espaco que voce procura.',
                        child: _FilterPanel(child: _buildStudioTypeChips()),
                      ),
                      const SizedBox(height: AppSpacing.s20),
                    ],
                    _SelectionLauncherCard(
                      icon: Icons.library_music_rounded,
                      title: 'Generos musicais',
                      description:
                          'Selecione estilos para refinar os resultados.',
                      selectedItems: _selectedGenres,
                      onTap: () => _openMultiSelect(
                        title: 'Generos musicais',
                        subtitle: 'Selecione os generos para filtrar',
                        items: ref.read(genreLabelsProvider),
                        selected: _selectedGenres,
                        searchHint: 'Buscar genero...',
                        onChanged: (value) {
                          setState(() => _selectedGenres = value);
                        },
                      ),
                      onClear: _selectedGenres.isNotEmpty
                          ? () => setState(() => _selectedGenres.clear())
                          : null,
                    ),
                    if (isProfessional) ...[
                      const SizedBox(height: AppSpacing.s12),
                      _SelectionLauncherCard(
                        icon: Icons.music_note_rounded,
                        title: 'Instrumentos',
                        description: 'Escolha os instrumentos mais relevantes.',
                        selectedItems: _selectedInstruments,
                        onTap: () => _openMultiSelect(
                          title: 'Instrumentos',
                          subtitle: 'Selecione os instrumentos para filtrar',
                          items: ref.read(instrumentLabelsProvider),
                          selected: _selectedInstruments,
                          searchHint: 'Buscar instrumento...',
                          onChanged: (value) {
                            setState(() => _selectedInstruments = value);
                          },
                        ),
                        onClear: _selectedInstruments.isNotEmpty
                            ? () => setState(() => _selectedInstruments.clear())
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      _SelectionLauncherCard(
                        icon: Icons.build_rounded,
                        title: 'Funcoes tecnicas',
                        description:
                            'Selecione funcoes de palco, audio ou producao.',
                        selectedItems: _selectedRoles,
                        onTap: () => _openMultiSelect(
                          title: 'Funcoes tecnicas',
                          subtitle:
                              'Selecione as funcoes tecnicas para filtrar',
                          items: ref.read(crewRoleLabelsProvider),
                          selected: _selectedRoles,
                          searchHint: 'Buscar funcao...',
                          onChanged: (value) {
                            setState(() => _selectedRoles = value);
                          },
                        ),
                        onClear: _selectedRoles.isNotEmpty
                            ? () => setState(() => _selectedRoles.clear())
                            : null,
                      ),
                    ],
                    if (isStudio) ...[
                      const SizedBox(height: AppSpacing.s12),
                      _SelectionLauncherCard(
                        icon: Icons.headset_mic_rounded,
                        title: 'Servicos de estudio',
                        description:
                            'Filtre pelos servicos disponiveis no estudio.',
                        selectedItems: _selectedServices,
                        onTap: () => _openMultiSelect(
                          title: 'Servicos de estudio',
                          subtitle: 'Selecione os servicos para filtrar',
                          items: ref.read(studioServiceLabelsProvider),
                          selected: _selectedServices,
                          searchHint: 'Buscar servico...',
                          onChanged: (value) {
                            setState(() => _selectedServices = value);
                          },
                        ),
                        onClear: _selectedServices.isNotEmpty
                            ? () => setState(() => _selectedServices.clear())
                            : null,
                      ),
                    ],
                    if (isProfessional) ...[
                      const SizedBox(height: AppSpacing.s20),
                      _FilterSection(
                        title: 'Backing vocal',
                        subtitle:
                            'Use este filtro so quando isso for importante.',
                        child: _FilterPanel(child: _buildBackingVocalChips()),
                      ),
                    ],
                  ],
                ),
              ),
              _FilterSheetFooter(
                activeFilterCount: _activeFilterCount,
                onCancel: () => Navigator.of(context).pop(),
                onApply: _applyFilters,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryChips() {
    final items = <(ProfessionalSubcategory, String, IconData)>[
      (ProfessionalSubcategory.singer, 'Cantor(a)', Icons.mic_rounded),
      (
        ProfessionalSubcategory.instrumentalist,
        'Instrumentista',
        Icons.music_note_rounded,
      ),
      (ProfessionalSubcategory.crew, 'Equipe tecnica', Icons.build_rounded),
      (ProfessionalSubcategory.dj, 'DJ', Icons.album_rounded),
    ];

    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: items.map((item) {
        final isSelected = _professionalSubcategory == item.$1;
        return AppFilterChip(
          label: item.$2,
          icon: item.$3,
          isSelected: isSelected,
          onSelected: (_) {
            setState(() {
              _professionalSubcategory = isSelected ? null : item.$1;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildStudioTypeChips() {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        AppFilterChip(
          label: 'Qualquer',
          isSelected: _studioType == null,
          onSelected: (_) => setState(() => _studioType = null),
        ),
        AppFilterChip(
          label: 'Comercial',
          icon: Icons.storefront_rounded,
          isSelected: _studioType == 'commercial',
          onSelected: (_) {
            setState(() {
              _studioType = _studioType == 'commercial' ? null : 'commercial';
            });
          },
        ),
        AppFilterChip(
          label: 'Home Studio',
          icon: Icons.home_rounded,
          isSelected: _studioType == 'home_studio',
          onSelected: (_) {
            setState(() {
              _studioType = _studioType == 'home_studio' ? null : 'home_studio';
            });
          },
        ),
      ],
    );
  }

  Widget _buildBackingVocalChips() {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        AppFilterChip(
          label: 'Qualquer',
          isSelected: _canDoBackingVocal == null,
          onSelected: (_) => setState(() => _canDoBackingVocal = null),
        ),
        AppFilterChip(
          label: 'Faz backing vocal',
          icon: Icons.record_voice_over_rounded,
          isSelected: _canDoBackingVocal == true,
          onSelected: (_) {
            setState(() {
              _canDoBackingVocal = _canDoBackingVocal == true ? null : true;
            });
          },
        ),
      ],
    );
  }

  Future<void> _openMultiSelect({
    required String title,
    required String subtitle,
    required List<String> items,
    required List<String> selected,
    required String searchHint,
    required ValueChanged<List<String>> onChanged,
  }) async {
    final result = await EnhancedMultiSelectModal.show<String>(
      context: context,
      title: title,
      subtitle: subtitle,
      items: items,
      selectedItems: selected,
      searchHint: searchHint,
    );

    if (!mounted || result == null) return;
    onChanged(result);
  }

  void _clearAll() {
    setState(() {
      _professionalSubcategory = null;
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
      professionalSubcategory: _professionalSubcategory,
      genres: _selectedGenres,
      instruments: _selectedInstruments,
      roles: _selectedRoles,
      services: _selectedServices,
      studioType: _studioType,
      canDoBackingVocal: _canDoBackingVocal,
    );

    widget.onApply(newFilters);
    Navigator.of(context).pop();
  }
}

class _FilterSheetHeader extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback? onClearAll;

  const _FilterSheetHeader({
    required this.activeFilterCount,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.s16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: AppRadius.all8,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros avancados',
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Refine a busca com o que realmente importa para voce.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeFilterCount > 0)
                _CountBadge(
                  label:
                      '$activeFilterCount ativo${activeFilterCount > 1 ? 's' : ''}',
                ),
            ],
          ),
          if (onClearAll != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClearAll,
                child: Text(
                  'Limpar tudo',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        child,
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final Widget child;

  const _FilterPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SelectionLauncherCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> selectedItems;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SelectionLauncherCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selectedItems,
    required this.onTap,
    required this.onClear,
  });

  bool get _hasItems => selectedItems.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all16,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s14),
          decoration: BoxDecoration(
            color: _hasItems ? AppColors.surface : AppColors.surface2,
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: _hasItems
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SelectionIcon(icon: icon, isActive: _hasItems),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.titleSmall),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          _hasItems
                              ? '${selectedItems.length} selecionado${selectedItems.length > 1 ? 's' : ''}'
                              : description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasItems) ...[
                    _CountBadge(label: '${selectedItems.length}'),
                    const SizedBox(width: AppSpacing.s4),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceHighlight,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.all12,
                        ),
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.s4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
              if (_hasItems) ...[
                const SizedBox(height: AppSpacing.s12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chipMaxWidth = constraints.maxWidth * 0.58;
                    return Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final item in selectedItems.take(3))
                          _SummaryChip(label: item, maxWidth: chipMaxWidth),
                        if (selectedItems.length > 3)
                          _SummaryChip(
                            label: '+${selectedItems.length - 3}',
                            maxWidth: chipMaxWidth,
                            isCount: true,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _SelectionIcon({required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
      ),
      child: Icon(
        icon,
        size: 18,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double maxWidth;
  final bool isCount;

  const _SummaryChip({
    required this.label,
    required this.maxWidth,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: isCount
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surfaceHighlight,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isCount
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: isCount ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;

  const _CountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterSheetFooter extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const _FilterSheetFooter({
    required this.activeFilterCount,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final applyText = activeFilterCount > 0
        ? 'Aplicar ($activeFilterCount)'
        : 'Aplicar filtros';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.outline(text: 'Cancelar', onPressed: onCancel),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            flex: 2,
            child: AppButton.primary(text: applyText, onPressed: onApply),
          ),
        ],
      ),
    );
  }
}
