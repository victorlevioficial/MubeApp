import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../constants/app_constants.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/components/inputs/app_date_picker_field.dart';
import '../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';

class ProfessionalFormFields extends ConsumerStatefulWidget {
  final TextEditingController nomeArtisticoController;
  final TextEditingController celularController;
  final TextEditingController dataNascimentoController;
  final TextEditingController generoController;
  final TextEditingController instagramController;
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

        const SizedBox(height: AppSpacing.s32),
        const SizedBox(height: AppSpacing.s32),

        // --- Categories and Specific Questions ---
        _buildCategorySelector(),

        // 1. Singer Specifics
        if (widget.selectedCategories.contains('singer')) ...[
          const SizedBox(height: AppSpacing.s24),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(16),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
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
    final selected = widget.selectedCategories;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Categorias', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s12),

          AppButton.outline(
            text: selected.isEmpty ? 'Selecionar' : 'Editar seleção',
            icon: const Icon(Icons.add, size: 18),
            onPressed: () async {
              final result = await showModalBottomSheet<List<String>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AppSelectionModal(
                  title: 'Categorias',
                  items: options,
                  selectedItems: selected,
                  allowMultiple: true,
                  itemLabelBuilder: (item) {
                    final cat = professionalCategories.firstWhere(
                      (e) => e['id'] == item,
                      orElse: () => <String, Object>{'label': item},
                    );
                    return cat['label'] as String;
                  },
                ),
              );

              if (result != null) {
                // Use dedicated callback that allows parent to handle cascading clear
                widget.onCategoriesChanged(result);
              }
            },
          ),

          if (selected.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selected.map((item) {
                String display = item;
                final cat = professionalCategories.firstWhere(
                  (e) => e['id'] == item,
                  orElse: () => <String, Object>{'label': item},
                );
                if (cat['label'] != null) {
                  display = cat['label'] as String;
                }

                return AppFilterChip(
                  label: display,
                  isSelected: true,
                  onSelected: (_) {},
                  onRemove: () {
                    // Remove and notify parent via dedicated callback
                    final updated = List<String>.from(selected);
                    updated.remove(item);
                    widget.onCategoriesChanged(updated);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagSelector(
    String label,
    List<String> options,
    List<String> selected,
    ValueChanged<List<String>> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s12),

          AppButton.outline(
            text: selected.isEmpty ? 'Selecionar' : 'Editar seleção',
            icon: const Icon(Icons.add, size: 18),
            onPressed: () async {
              final result = await showModalBottomSheet<List<String>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AppSelectionModal(
                  title: label,
                  items: options,
                  selectedItems: selected,
                  allowMultiple: true,
                  // Items (instruments, roles, genres) are already
                  // display-ready strings from providers
                  itemLabelBuilder: (item) => item,
                ),
              );

              AppLogger.info('📋 Modal returned: $result for $label');
              if (result != null) {
                AppLogger.info('📋 Calling onChanged callback with: $result');
                onChanged(result);
                AppLogger.info('📋 onChanged callback completed');
              } else {
                AppLogger.info('📋 Result was null, not calling callback');
              }
            },
          ),

          if (selected.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selected.map((item) {
                // Items are already display-ready strings from providers
                return AppFilterChip(
                  label: item,
                  isSelected: true,
                  onSelected: (_) {},
                  onRemove: () {
                    final newList = List<String>.from(selected);
                    newList.remove(item);
                    onChanged(newList);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
