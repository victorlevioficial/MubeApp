import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../../../common_widgets/formatters/title_case_formatter.dart';
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
      'id': 'crew',
      'label': 'Equipe Técnica',
      'description': 'Técnico de som, luz, roadie, produtor',
      'icon': FontAwesomeIcons.wrench,
    },
    {
      'id': 'dj',
      'label': 'DJ',
      'description': 'DJ de festa, club, eventos, produtor musical',
      'icon': FontAwesomeIcons.compactDisc,
    },
  ];

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
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic Info Section
          Text('Informações Pessoais', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s16),

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
            value: widget.generoController.text.isEmpty
                ? null
                : widget.generoController.text,
            items: const [
              DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
              DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
              DropdownMenuItem(value: 'Outro', child: Text('Outro')),
              DropdownMenuItem(
                value: 'Prefiro não dizer',
                child: Text('Prefiro não dizer'),
              ),
            ],
            onChanged: (v) {
              widget.generoController.text = v!;
              widget.onStateChanged();
            },
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: widget.instagramController,
            label: 'Instagram (opcional)',
            hint: '@nome_artístico',
            prefixIcon: const Icon(Icons.alternate_email, size: 20),
            onChanged: (_) => widget.onStateChanged(),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: widget.bioController,
            label: 'Bio',
            maxLines: 3,
            hint: 'Conte um pouco sobre você...',
            onChanged: (_) => widget.onStateChanged(),
          ),

          const SizedBox(height: AppSpacing.s48),

          // Categories Section
          Text('Qual é sua área?', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Selecione uma ou mais categorias que descrevem sua atuação profissional',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
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

    // Crew Specifics
    if (_selectedCategories.contains('crew')) {
      widgets.addAll([
        _buildRolesSelector(),
        const SizedBox(height: AppSpacing.s48),
      ]);
    }

    // Genres (always shown)
    widgets.addAll([
      _buildGenresSelector(),
      const SizedBox(height: AppSpacing.s24),
    ]);

    return widgets;
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

  Widget _buildRolesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Funções Técnicas', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Quais são suas funções técnicas?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _buildSelectionContainer(
          label: 'Funções Técnicas',
          selectedItems: widget.selectedRoles,
          onEdit: () => _showEnhancedModal(
            title: 'Funções Técnicas',
            subtitle: 'Selecione suas funções',
            items: ref.watch(crewRoleLabelsProvider),
            loadItems: () async {
              final config = await ref.read(appConfigProvider.future);
              return config.crewRoles.map((item) => item.label).toList();
            },
            selectedItems: widget.selectedRoles,
            onChanged: widget.onRolesChanged,
            searchHint: 'Buscar função...',
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
