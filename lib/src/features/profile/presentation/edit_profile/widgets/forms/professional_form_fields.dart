import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../core/providers/app_config_provider.dart';
import '../../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../../../design_system/components/inputs/app_date_picker_field.dart';
import '../../../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';

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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: widget.nomeArtisticoController,
          label: 'Nome Artístico',
          textCapitalization: TextCapitalization.words,
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: widget.celularController,
          label: 'Celular',
          inputFormatters: [widget.celularMask],
          keyboardType: TextInputType.phone,
          validator: (v) => v!.length < 14 ? 'Inválido' : null,
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
          label: 'Instagram',
          hint: '@usuario',
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: widget.bioController,
          label: 'Bio',
          maxLines: 3,
          hint: 'Conte um pouco sobre você...',
          onChanged: (_) => widget.onStateChanged(),
        ),

        const SizedBox(height: AppSpacing.s16),

        // --- Categories and Specific Questions ---
        _buildCategorySelector(),

        // 1. Singer Specifics
        if (widget.selectedCategories.contains('singer')) ...[
          const SizedBox(height: AppSpacing.s16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(
                color: AppColors.background.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: AppDropdownField<String>(
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
          ),
        ],

        // 2. Instrumentalist Specifics
        if (widget.selectedCategories.contains('instrumentalist')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildTagSelector(
            'Instrumentos',
            ref.watch(instrumentLabelsProvider),
            widget.selectedInstruments,
            widget.onInstrumentsChanged,
          ),
          const SizedBox(height: AppSpacing.s16),

          // Backing Vocal Checkbox for Instrumentalist
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(
                color: AppColors.background.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: widget.instrumentalistBackingVocal,
                    activeColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.textSecondary,
                      width: 2,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.all4,
                    ),
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
          ),
        ],

        // 3. Crew Specifics
        if (widget.selectedCategories.contains('crew')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildTagSelector(
            'Funções Técnicas',
            ref.watch(crewRoleLabelsProvider),
            widget.selectedRoles,
            widget.onRolesChanged,
          ),
        ],

        const SizedBox(height: AppSpacing.s24),
        _buildTagSelector(
          'Gêneros Musicais',
          ref.watch(genreLabelsProvider),
          widget.selectedGenres,
          widget.onGenresChanged,
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final options = professionalCategories
        .map((e) => e['id'] as String)
        .toList();

    return _buildCard(
      title: 'Categorias',
      items: widget.selectedCategories.map((id) {
        final cat = professionalCategories.firstWhere(
          (e) => e['id'] == id,
          orElse: () => <String, Object>{'label': id},
        );
        return cat['label'] as String;
      }).toList(),
      onAdd: () => _showSelectionModal(
        title: 'Selecione as Categorias',
        options: options,
        selected: widget.selectedCategories,
        onChanged: widget.onCategoriesChanged,
        itemLabelBuilder: (item) {
          final cat = professionalCategories.firstWhere(
            (e) => e['id'] == item,
            orElse: () => <String, Object>{'label': item},
          );
          return cat['label'] as String;
        },
      ),
      onRemove: (itemLabel) {
        final categoryId =
            professionalCategories.firstWhere(
                  (e) => e['label'] == itemLabel,
                  orElse: () => <String, Object>{'id': itemLabel},
                )['id']
                as String;
        final newSelected = List<String>.from(widget.selectedCategories)
          ..remove(categoryId);
        widget.onCategoriesChanged(newSelected);
      },
    );
  }

  Widget _buildTagSelector(
    String label,
    List<String> options,
    List<String> selected,
    ValueChanged<List<String>> onChanged,
  ) {
    return _buildCard(
      title: label,
      items: selected,
      onAdd: () => _showSelectionModal(
        title: 'Selecione $label',
        options: options,
        selected: selected,
        onChanged: onChanged,
      ),
      onRemove: (item) {
        final newSelected = List<String>.from(selected)..remove(item);
        onChanged(newSelected);
      },
    );
  }

  Widget _buildCard({
    required String title,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(String) onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.background.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.titleMedium),
              AppButton.ghost(
                text: 'Adicionar',
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                size: AppButtonSize.small,
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: items.map((item) {
                return AppFilterChip(
                  label: item,
                  isSelected: true,
                  onSelected: (_) {},
                  onRemove: () => onRemove(item),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showSelectionModal({
    required String title,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
    String Function(String)? itemLabelBuilder,
  }) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => AppSelectionModal(
        title: title,
        items: options,
        selectedItems: selected,
        allowMultiple: true,
        itemLabelBuilder: itemLabelBuilder ?? (item) => item,
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}
