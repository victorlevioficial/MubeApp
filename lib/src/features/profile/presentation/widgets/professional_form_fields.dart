import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../common_widgets/app_text_field.dart';
import '../../../../common_widgets/app_date_picker_field.dart';
import '../../../../common_widgets/app_dropdown_field.dart';
import '../../../../common_widgets/app_selection_modal.dart';
import '../../../../common_widgets/app_filter_chip.dart';
import '../../../../common_widgets/secondary_button.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../../../constants/app_constants.dart';

class ProfessionalFormFields extends StatefulWidget {
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

  final String backingVocalMode;
  final ValueChanged<String> onBackingVocalModeChanged;

  final bool instrumentalistBackingVocal;
  final ValueChanged<bool> onInstrumentalistBackingVocalChanged;

  final VoidCallback onStateChanged;

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
    required this.backingVocalMode,
    required this.onBackingVocalModeChanged,
    required this.instrumentalistBackingVocal,
    required this.onInstrumentalistBackingVocalChanged,
    required this.onStateChanged,
  });

  @override
  State<ProfessionalFormFields> createState() => _ProfessionalFormFieldsState();
}

class _ProfessionalFormFieldsState extends State<ProfessionalFormFields> {
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
        _buildTagSelector(
          'Categorias',
          PROFESSIONAL_CATEGORIES.map((e) => e['id'] as String).toList(),
          widget.selectedCategories,
        ),

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
            INSTRUMENTS,
            widget.selectedInstruments,
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
            CREW_ROLES,
            widget.selectedRoles,
          ),
        ],

        const SizedBox(height: AppSpacing.s24),
        _buildTagSelector('Gêneros Musicais', GENRES, widget.selectedGenres),
      ],
    );
  }

  Widget _buildTagSelector(
    String label,
    List<String> options,
    List<String> selected,
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

          SecondaryButton(
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
                  itemLabelBuilder: (item) {
                    final cat = PROFESSIONAL_CATEGORIES.firstWhere(
                      (e) => e['id'] == item,
                      orElse: () => <String, Object>{'label': item},
                    );
                    return cat['label'] as String;
                  },
                ),
              );

              if (result != null) {
                selected.clear();
                selected.addAll(result);
                widget.onStateChanged();
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
                final cat = PROFESSIONAL_CATEGORIES.firstWhere(
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
                    selected.remove(item);
                    widget.onStateChanged();
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
