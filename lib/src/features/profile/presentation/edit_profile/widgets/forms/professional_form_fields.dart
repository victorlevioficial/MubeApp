import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../../../common_widgets/formatters/sentence_start_uppercase_formatter.dart';
import '../../../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../../../constants/app_constants.dart';
import '../../../../../../core/providers/app_config_provider.dart';
import '../../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../../../design_system/components/inputs/app_date_picker_field.dart';
import '../../../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../../../design_system/components/patterns/full_width_selection_card.dart';
import '../../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../../../utils/category_normalizer.dart';
import '../../../../../../utils/instagram_utils.dart';
import '../../../../../../utils/professional_profile_utils.dart';

class _RoleOption {
  final String id;
  final String label;

  const _RoleOption({required this.id, required this.label});
}

class _RoleSectionDefinition {
  final String categoryId;
  final String title;
  final String subtitle;
  final List<_RoleOption> options;

  const _RoleSectionDefinition({
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.options,
  });

  Map<String, String> get labelById => {
    for (final option in options) option.id: option.label,
  };
}

List<_RoleOption> _buildPlainRoleOptions(List<String> labels) {
  return labels
      .map(
        (label) =>
            _RoleOption(id: CategoryNormalizer.sanitize(label), label: label),
      )
      .toList(growable: false);
}

List<_RoleOption> _buildPrefixedRoleOptions(
  String prefix,
  List<String> labels,
) {
  return labels
      .map(
        (label) => _RoleOption(
          id: '${prefix}_${CategoryNormalizer.sanitize(label)}',
          label: label,
        ),
      )
      .toList(growable: false);
}

const List<String> _audiovisualRoleLabels = [
  'Direção de Vídeo',
  'Captação de Vídeo',
  'Edição de Vídeo',
  'Motion Design',
  'Operação de Câmera',
  'Streaming ao Vivo',
];

const List<String> _educationRoleLabels = [
  'Professor(a)',
  'Mentor(a)',
  'Oficineiro(a)',
  'Palestrante',
  'Coach Artístico',
  'Consultor(a)',
];

const List<String> _luthierRoleLabels = [
  'Ajuste e Regulagem',
  'Reparo',
  'Construção de Instrumentos',
  'Elétrica e Eletrônica',
  'Customização',
  'Encordoamento e Manutenção',
];

const List<String> _performanceRoleLabels = [
  'Performer',
  'Artista de Palco',
  'Intervenção Cênica',
  'Dança',
  'Live Act',
  'VJ / Visuals',
];

final List<_RoleSectionDefinition> _roleSections = [
  _RoleSectionDefinition(
    categoryId: 'production',
    title: 'Produção Musical *',
    subtitle: 'Quais funções de produção você desempenha?',
    options: _buildPlainRoleOptions(productionRoles),
  ),
  _RoleSectionDefinition(
    categoryId: 'stage_tech',
    title: 'Técnica de Palco *',
    subtitle: 'Quais funções técnicas de palco você desempenha?',
    options: _buildPlainRoleOptions(stageTechRoles),
  ),
  _RoleSectionDefinition(
    categoryId: 'audiovisual',
    title: 'Audiovisual *',
    subtitle: 'Selecione suas funções em vídeo e conteúdo visual',
    options: _buildPrefixedRoleOptions('audiovisual', _audiovisualRoleLabels),
  ),
  _RoleSectionDefinition(
    categoryId: 'education',
    title: 'Educação *',
    subtitle: 'Selecione suas funções ligadas a ensino e mentoria',
    options: _buildPrefixedRoleOptions('education', _educationRoleLabels),
  ),
  _RoleSectionDefinition(
    categoryId: 'luthier',
    title: 'Luthier *',
    subtitle: 'Selecione suas funções de construção e manutenção',
    options: _buildPrefixedRoleOptions('luthier', _luthierRoleLabels),
  ),
  _RoleSectionDefinition(
    categoryId: 'performance',
    title: 'Performance *',
    subtitle: 'Selecione suas funções de presença cênica e live acts',
    options: _buildPrefixedRoleOptions('performance', _performanceRoleLabels),
  ),
];

final Map<String, _RoleSectionDefinition> _roleSectionByCategoryId = {
  for (final section in _roleSections) section.categoryId: section,
};

const Set<String> _genreHiddenCategories = {
  'audiovisual',
  'education',
  'luthier',
};

/// Enhanced Professional Form Fields with modern card-based design.
/// Matches the onboarding flow UI.
class ProfessionalFormFields extends ConsumerStatefulWidget {
  final TextEditingController nomeArtisticoController;
  final TextEditingController celularController;
  final TextEditingController dataNascimentoController;
  final TextEditingController generoController;
  final TextEditingController instagramController;
  final TextEditingController bioController;
  final MaskTextInputFormatter celularMask;

  final List<String> selectedCategories;
  final List<String> selectedGenres;
  final List<String> selectedInstruments;
  final List<String> selectedRoles;

  final ValueChanged<List<String>> onInstrumentsChanged;
  final ValueChanged<List<String>> onRolesChanged;
  final ValueChanged<List<String>> onGenresChanged;

  final String backingVocalMode;
  final ValueChanged<String> onBackingVocalModeChanged;

  final bool instrumentalistBackingVocal;
  final ValueChanged<bool> onInstrumentalistBackingVocalChanged;

  final bool offersRemoteRecording;
  final ValueChanged<bool> onOffersRemoteRecordingChanged;

  final VoidCallback onStateChanged;
  final ValueChanged<List<String>> onCategoriesChanged;

  const ProfessionalFormFields({
    super.key,
    required this.nomeArtisticoController,
    required this.celularController,
    required this.dataNascimentoController,
    required this.generoController,
    required this.instagramController,
    required this.bioController,
    required this.celularMask,
    required this.selectedCategories,
    required this.selectedGenres,
    required this.selectedInstruments,
    required this.selectedRoles,
    required this.onInstrumentsChanged,
    required this.onRolesChanged,
    required this.onGenresChanged,
    required this.backingVocalMode,
    required this.onBackingVocalModeChanged,
    required this.instrumentalistBackingVocal,
    required this.onInstrumentalistBackingVocalChanged,
    required this.offersRemoteRecording,
    required this.onOffersRemoteRecordingChanged,
    required this.onStateChanged,
    required this.onCategoriesChanged,
  });

  @override
  ConsumerState<ProfessionalFormFields> createState() =>
      _ProfessionalFormFieldsState();
}

class _ProfessionalFormFieldsState
    extends ConsumerState<ProfessionalFormFields> {
  late List<String> _selectedCategories;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'singer',
      'label': 'Cantor(a)',
      'description': 'Vocalista principal, coral, backing vocal',
      'icon': FontAwesomeIcons.microphone,
    },
    {
      'id': 'instrumentalist',
      'label': 'Instrumentista',
      'description': 'Guitarra, bateria, piano, baixo, cordas, sopros',
      'icon': FontAwesomeIcons.guitar,
    },
    {
      'id': 'dj',
      'label': 'DJ',
      'description': 'DJ de festa, club, eventos e sets ao vivo',
      'icon': FontAwesomeIcons.compactDisc,
    },
    {
      'id': 'production',
      'label': 'Produção Musical',
      'description': 'Produção, direção, gravação, mixagem e arranjos',
      'icon': FontAwesomeIcons.sliders,
    },
    {
      'id': 'stage_tech',
      'label': 'Técnica de Palco',
      'description': 'PA, monitor, RF, luz, LED, roadie e backline',
      'icon': FontAwesomeIcons.wrench,
    },
    {
      'id': 'audiovisual',
      'label': 'Audiovisual',
      'description': 'Vídeo, transmissão, captação, edição e motion',
      'icon': Icons.video_camera_front_outlined,
    },
    {
      'id': 'education',
      'label': 'Educação',
      'description': 'Aulas, oficinas, mentoria, palestras e consultoria',
      'icon': Icons.school_outlined,
    },
    {
      'id': 'luthier',
      'label': 'Luthier',
      'description': 'Ajuste, reparo, construção e manutenção de instrumentos',
      'icon': Icons.handyman_outlined,
    },
    {
      'id': 'performance',
      'label': 'Performance',
      'description': 'Cena, live acts, intervenção artística e corpo',
      'icon': Icons.auto_awesome_outlined,
    },
  ];

  bool get _shouldShowGenres => _categoriesRequireGenres(_selectedCategories);

  List<String> _selectedRoleIdsForCategory(String categoryId) {
    return widget.selectedRoles
        .where((roleId) => _roleBelongsToCategory(roleId, categoryId))
        .toList(growable: false);
  }

  bool _roleBelongsToCategory(String roleId, String categoryId) {
    return _roleSectionByCategoryId[categoryId]?.options.any(
          (option) => option.id == roleId,
        ) ??
        false;
  }

  bool _roleBelongsToAnySelectedCategory(
    String roleId,
    List<String> categories,
  ) {
    return categories.any(
      (category) => _roleBelongsToCategory(roleId, category),
    );
  }

  List<String> _pruneRolesForCategories(List<String> categories) {
    return widget.selectedRoles
        .where(
          (roleId) => _roleBelongsToAnySelectedCategory(roleId, categories),
        )
        .toList(growable: false);
  }

  bool _categoriesRequireGenres(List<String> categories) {
    final resolved = CategoryNormalizer.resolveCategories(
      rawCategories: categories,
      rawRoles: widget.selectedRoles,
    );
    return resolved.any(
      (category) => !_genreHiddenCategories.contains(category),
    );
  }

  void _updateRolesForCategory(String categoryId, List<String> roleIds) {
    final next = [
      ...widget.selectedRoles.where(
        (roleId) => !_roleBelongsToCategory(roleId, categoryId),
      ),
      ...roleIds,
    ];
    widget.onRolesChanged(next);
  }

  Future<void> _showRoleSelector(_RoleSectionDefinition section) async {
    final currentRoleIds = _selectedRoleIdsForCategory(section.categoryId);
    final result = await EnhancedMultiSelectModal.show<String>(
      context: context,
      title: section.title,
      subtitle: section.subtitle,
      items: section.options.map((option) => option.id).toList(growable: false),
      selectedItems: currentRoleIds,
      searchHint: 'Buscar função...',
      itemLabel: (id) => section.labelById[id] ?? id,
    );

    if (result != null) {
      _updateRolesForCategory(section.categoryId, result);
      widget.onStateChanged();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
    widget.onCategoriesChanged(_selectedCategories);
    widget.onRolesChanged(_pruneRolesForCategories(_selectedCategories));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: widget.nomeArtisticoController,
            label: 'Nome Artístico',
            hint: 'Nome exibido no app',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
            validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: widget.celularController,
            label: 'Celular',
            hint: '(00) 00000-0000',
            inputFormatters: [widget.celularMask],
            keyboardType: TextInputType.phone,
            validator: (v) => v!.length < 14 ? 'Inválido' : null,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppDatePickerField(
            label: 'Data de Nascimento',
            controller: widget.dataNascimentoController,
          ),
          const SizedBox(height: AppSpacing.s16),

          AppDropdownField<String>(
            label: 'Gênero',
            value: normalizeGenderValue(widget.generoController.text).isEmpty
                ? null
                : normalizeGenderValue(widget.generoController.text),
            items: genderOptions
                .map(
                  (gender) =>
                      DropdownMenuItem(value: gender, child: Text(gender)),
                )
                .toList(),
            onChanged: (v) {
              widget.generoController.text = normalizeGenderValue(v);
              widget.onStateChanged();
            },
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: widget.instagramController,
            label: instagramLabelOptional,
            hint: instagramHint,
            prefixIcon: const Icon(Icons.alternate_email, size: 20),
            onChanged: (_) => widget.onStateChanged(),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: widget.bioController,
            label: 'Bio',
            maxLines: 3,
            hint: 'Conte um pouco sobre você...',
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [SentenceStartUppercaseTextInputFormatter()],
            onChanged: (_) => widget.onStateChanged(),
          ),

          const SizedBox(height: AppSpacing.s48),

          // Categories Section
          Text('Qual é sua área?', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all20,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você pode marcar mais de uma opção.',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Selecione uma ou mais categorias que descrevem sua atuação profissional',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    '${_selectedCategories.length} de ${_categories.length} selecionadas',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s32),

          // Category Cards
          ..._categories.asMap().entries.map((entry) {
            final category = entry.value;
            final isLast = entry.key == _categories.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.s16),
              child: FullWidthSelectionCard(
                icon: category['icon'],
                title: category['label'],
                description: category['description'],
                isSelected: _selectedCategories.contains(category['id']),
                selectionMode: SelectionMode.multi,
                onTap: () => _toggleCategory(category['id']),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.s48),

          // Conditional Sections based on selected categories
          ..._buildCategorySpecificSections(),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySpecificSections() {
    final widgets = <Widget>[];

    // Singer Specifics
    if (_selectedCategories.contains('singer')) {
      widgets.addAll([
        Text('Dados de Vocalista', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.s16),
        AppDropdownField<String>(
          label: 'Faz Backing Vocal?',
          value: widget.backingVocalMode,
          items: const [
            DropdownMenuItem(
              value: '0',
              child: Text('Não, apenas voz principal'),
            ),
            DropdownMenuItem(
              value: '1',
              child: Text('Sim, também faço backing'),
            ),
            DropdownMenuItem(
              value: '2',
              child: Text('Faço exclusivamente backing vocal'),
            ),
          ],
          onChanged: (v) => widget.onBackingVocalModeChanged(v!),
        ),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    // Instrumentalist Specifics
    if (_selectedCategories.contains('instrumentalist')) {
      widgets.addAll([
        _buildInstrumentsSelector(),
        const SizedBox(height: AppSpacing.s16),
        _buildBackingVocalCheckbox(),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    if (_selectedCategories.contains('production')) {
      widgets.addAll([
        _buildRoleSection(_roleSectionByCategoryId['production']!),
        const SizedBox(height: AppSpacing.s16),
        _buildRemoteRecordingCheckbox(),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    if (_selectedCategories.contains('stage_tech')) {
      widgets.addAll([
        _buildRoleSection(_roleSectionByCategoryId['stage_tech']!),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    if (_selectedCategories.contains('audiovisual')) {
      widgets.addAll([
        _buildRoleSection(_roleSectionByCategoryId['audiovisual']!),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    if (_selectedCategories.contains('education')) {
      widgets.addAll([
        _buildRoleSection(_roleSectionByCategoryId['education']!),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    if (_selectedCategories.contains('luthier')) {
      widgets.addAll([
        _buildRoleSection(_roleSectionByCategoryId['luthier']!),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    if (_selectedCategories.contains('performance')) {
      widgets.addAll([
        _buildRoleSection(_roleSectionByCategoryId['performance']!),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    if (_shouldShowGenres) {
      widgets.addAll([
        _buildGenresSelector(),
        const SizedBox(height: AppSpacing.s24),
      ]);
    }

    return widgets;
  }

  Widget _buildRoleSection(_RoleSectionDefinition section) {
    final selectedIds = _selectedRoleIdsForCategory(section.categoryId);
    final selectedLabels = selectedIds
        .map((id) => section.labelById[id] ?? id)
        .toList(growable: false);

    return _buildSelectionContainer(
      label: section.title,
      selectedItems: selectedLabels,
      onEdit: () => _showRoleSelector(section),
    );
  }

  Widget _buildInstrumentsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Instrumentos', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Quais instrumentos você toca?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _buildSelectionContainer(
          label: 'Instrumentos',
          selectedItems: widget.selectedInstruments,
          onEdit: () => _showEnhancedModal(
            title: 'Instrumentos',
            subtitle: 'Selecione os instrumentos que você toca',
            items: ref.watch(instrumentLabelsProvider),
            loadItems: () async {
              final config = await ref.read(appConfigProvider.future);
              return config.instruments.map((item) => item.label).toList();
            },
            selectedItems: widget.selectedInstruments,
            onChanged: widget.onInstrumentsChanged,
            searchHint: 'Buscar instrumento...',
          ),
        ),
      ],
    );
  }

  Widget _buildGenresSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Gêneros Musicais', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Quais são seus gêneros favoritos?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _buildSelectionContainer(
          label: 'Gêneros Musicais',
          selectedItems: widget.selectedGenres,
          onEdit: () => _showEnhancedModal(
            title: 'Gêneros Musicais',
            subtitle: 'Selecione seus gêneros',
            items: ref.watch(genreLabelsProvider),
            loadItems: () async {
              final config = await ref.read(appConfigProvider.future);
              return config.genres.map((item) => item.label).toList();
            },
            selectedItems: widget.selectedGenres,
            onChanged: widget.onGenresChanged,
            searchHint: 'Buscar gênero...',
          ),
        ),
      ],
    );
  }

  Widget _buildBackingVocalCheckbox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: widget.instrumentalistBackingVocal,
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.textSecondary, width: 2),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.all4),
              onChanged: (v) =>
                  widget.onInstrumentalistBackingVocalChanged(v ?? false),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              'Faço backing vocal tocando',
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteRecordingCheckbox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: widget.offersRemoteRecording,
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.textSecondary, width: 2),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.all4),
              onChanged: (v) =>
                  widget.onOffersRemoteRecordingChanged(v ?? false),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              professionalRemoteRecordingCheckboxLabel,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionContainer({
    required String label,
    required List<String> selectedItems,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: selectedItems.isEmpty ? AppColors.error : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: selectedItems.isEmpty
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            selectedItems.isEmpty
                ? 'Nenhum selecionado'
                : '${selectedItems.length} selecionado${selectedItems.length > 1 ? 's' : ''}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (selectedItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: selectedItems.take(3).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s10,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: AppRadius.all8,
                  ),
                  child: Text(
                    item,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedItems.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s8),
                child: Text(
                  '+${selectedItems.length - 3} mais',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            width: double.infinity,
            child: AppButton.outline(
              text: selectedItems.isEmpty ? 'Selecionar' : 'Editar',
              onPressed: onEdit,
              icon: Icon(
                selectedItems.isEmpty ? Icons.add : Icons.edit_outlined,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEnhancedModal({
    required String title,
    required String subtitle,
    required List<String> items,
    required List<String> selectedItems,
    required ValueChanged<List<String>> onChanged,
    required String searchHint,
    Future<List<String>> Function()? loadItems,
  }) async {
    var availableItems = items;

    if (availableItems.isEmpty && loadItems != null) {
      try {
        availableItems = await loadItems();
      } catch (_) {
        availableItems = [];
      }
    }

    if (!mounted) return;

    if (availableItems.isEmpty) {
      AppSnackBar.warning(
        context,
        'Ainda carregando opções. Tente novamente em alguns segundos.',
      );
      return;
    }

    final result = await EnhancedMultiSelectModal.show<String>(
      context: context,
      title: title,
      subtitle: subtitle,
      items: availableItems,
      selectedItems: selectedItems,
      searchHint: searchHint,
    );

    if (result != null) {
      onChanged(result);
      widget.onStateChanged();
    }
  }
}
