import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';

/// Enhanced Studio Form Fields with modern design matching onboarding.
class EnhancedStudioFormFields extends ConsumerWidget {
  final TextEditingController celularController;
  final MaskTextInputFormatter celularMask;
  final String? studioType;
  final ValueChanged<String> onStudioTypeChanged;
  final List<String> selectedServices;
  final ValueChanged<List<String>> onServicesChanged;
  final TextEditingController bioController;

  const EnhancedStudioFormFields({
    super.key,
    required this.celularController,
    required this.celularMask,
    required this.studioType,
    required this.onStudioTypeChanged,
    required this.selectedServices,
    required this.onServicesChanged,
    required this.bioController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dados do Estúdio', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: celularController,
            label: 'Celular',
            hint: '(00) 00000-0000',
            keyboardType: TextInputType.phone,
            inputFormatters: [celularMask],
            validator: (v) => v!.length < 14 ? 'Celular inválido' : null,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppDropdownField<String>(
            label: 'Tipo de Estúdio',
            value: studioType,
            items: studioTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (v) {
              if (v != null) onStudioTypeChanged(v);
            },
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: bioController,
            label: 'Bio',
            maxLines: 3,
            hint: 'Descreva o estúdio...',
          ),

          const SizedBox(height: AppSpacing.s48),

          Text('Serviços Oferecidos', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Quais serviços o estúdio oferece?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.s16),

          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(
                color: selectedServices.isEmpty
                    ? AppColors.error
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Serviços *',
                  style: AppTypography.titleMedium.copyWith(
                    color: selectedServices.isEmpty
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  selectedServices.isEmpty
                      ? 'Selecione os serviços oferecidos'
                      : '${selectedServices.length} serviço${selectedServices.length > 1 ? 's' : ''} selecionado${selectedServices.length > 1 ? 's' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (selectedServices.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      ...selectedServices.take(3).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s10,
                            vertical: AppSpacing.s4,
                          ),
                          decoration: BoxDecoration(
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
                      }),
                      if (selectedServices.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s10,
                            vertical: AppSpacing.s4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: AppRadius.all8,
                          ),
                          child: Text(
                            '+${selectedServices.length - 3}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.outline(
                    text: selectedServices.isEmpty
                        ? 'Selecionar Serviços'
                        : 'Editar Serviços',
                    onPressed: () async {
                      final result =
                          await EnhancedMultiSelectModal.show<String>(
                            context: context,
                            title: 'Serviços',
                            subtitle: 'Selecione os serviços oferecidos',
                            items: studioServices,
                            selectedItems: selectedServices,
                            searchHint: 'Buscar serviço...',
                          );
                      if (result != null) {
                        onServicesChanged(result);
                      }
                    },
                    icon: Icon(
                      selectedServices.isEmpty
                          ? Icons.add
                          : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }
}
