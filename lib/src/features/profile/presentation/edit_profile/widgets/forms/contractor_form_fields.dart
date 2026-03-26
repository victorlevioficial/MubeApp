import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../../../common_widgets/formatters/sentence_start_uppercase_formatter.dart';
import '../../../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/venue_type_constants.dart';
import '../../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../../design_system/components/inputs/app_date_picker_field.dart';
import '../../../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../../../utils/instagram_utils.dart';

/// Enhanced Contractor Form Fields with modern design matching onboarding.
class ContractorFormFields extends StatelessWidget {
  final TextEditingController nomeExibicaoController;
  final TextEditingController celularController;
  final MaskTextInputFormatter celularMask;
  final TextEditingController dataNascimentoController;
  final TextEditingController generoController;
  final TextEditingController instagramController;
  final TextEditingController bioController;
  final String? contractorVenueType;
  final List<String> contractorAmenities;
  final ValueChanged<String?> onVenueTypeChanged;
  final ValueChanged<List<String>> onAmenitiesChanged;
  final VoidCallback onChanged;

  const ContractorFormFields({
    super.key,
    required this.nomeExibicaoController,
    required this.celularController,
    required this.celularMask,
    required this.dataNascimentoController,
    required this.generoController,
    required this.instagramController,
    required this.bioController,
    required this.contractorVenueType,
    required this.contractorAmenities,
    required this.onVenueTypeChanged,
    required this.onAmenitiesChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final amenitiesPreview = venueAmenityLabels(contractorAmenities);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dados do Estabelecimento', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s16),
          AppTextField(
            controller: nomeExibicaoController,
            label: 'Nome de Exibicao',
            hint: 'Nome publico do local',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
            prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppDropdownField<String>(
            label: 'Tipo de Local',
            value: contractorVenueType,
            items: venueTypeOptions
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.id,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              onVenueTypeChanged(value);
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.s16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comodidades', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  amenitiesPreview.isEmpty
                      ? 'Selecione o que seu local oferece'
                      : '${amenitiesPreview.length} selecionada(s)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (amenitiesPreview.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: amenitiesPreview.take(4).map((item) {
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
                ],
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.outline(
                    text: amenitiesPreview.isEmpty
                        ? 'Selecionar Comodidades'
                        : 'Editar Comodidades',
                    onPressed: () async {
                      final result =
                          await EnhancedMultiSelectModal.show<String>(
                            context: context,
                            title: 'Comodidades',
                            subtitle: 'Escolha as comodidades do local',
                            items: venueAmenityOptions
                                .map((option) => option.id)
                                .toList(growable: false),
                            selectedItems: contractorAmenities,
                            searchHint: 'Buscar comodidade...',
                            itemLabel: (item) => venueAmenityLabel(item),
                          );
                      if (result == null) return;

                      onAmenitiesChanged(result);
                      onChanged();
                    },
                    icon: Icon(
                      amenitiesPreview.isEmpty
                          ? Icons.add_rounded
                          : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s48),

          Text('Dados Pessoais', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: celularController,
            label: 'Celular',
            hint: '(00) 00000-0000',
            keyboardType: TextInputType.phone,
            inputFormatters: [celularMask],
            validator: (v) => v!.length < 14 ? 'Celular inválido' : null,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppDatePickerField(
            label: 'Data de Nascimento',
            controller: dataNascimentoController,
          ),
          const SizedBox(height: AppSpacing.s16),

          AppDropdownField<String>(
            label: 'Gênero',
            value: normalizeGenderValue(generoController.text).isEmpty
                ? null
                : normalizeGenderValue(generoController.text),
            items: genderOptions
                .map(
                  (gender) =>
                      DropdownMenuItem(value: gender, child: Text(gender)),
                )
                .toList(),
            onChanged: (v) {
              generoController.text = normalizeGenderValue(v);
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: instagramController,
            label: instagramLabelOptional,
            hint: instagramHint,
            prefixIcon: const Icon(Icons.alternate_email, size: 20),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: bioController,
            label: 'Bio',
            maxLines: 3,
            hint: 'Conte um pouco sobre você...',
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [SentenceStartUppercaseTextInputFormatter()],
            onChanged: (_) => onChanged(),
          ),

          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }
}
