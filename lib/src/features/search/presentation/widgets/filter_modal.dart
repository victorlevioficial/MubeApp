import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/search_filters.dart';

part 'filter_modal_ui.dart';

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
                      icon: FontAwesomeIcons.recordVinyl,
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
                        icon: FontAwesomeIcons.guitar,
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
                        icon: FontAwesomeIcons.toolbox,
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
                        icon: FontAwesomeIcons.headset,
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
      (
        ProfessionalSubcategory.singer,
        'Cantor(a)',
        FontAwesomeIcons.microphone,
      ),
      (
        ProfessionalSubcategory.instrumentalist,
        'Instrumentista',
        FontAwesomeIcons.guitar,
      ),
      (
        ProfessionalSubcategory.crew,
        'Equipe tecnica',
        FontAwesomeIcons.toolbox,
      ),
      (ProfessionalSubcategory.dj, 'DJ', FontAwesomeIcons.compactDisc),
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
