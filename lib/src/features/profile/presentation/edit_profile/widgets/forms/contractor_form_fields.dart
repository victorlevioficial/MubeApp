import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/components/inputs/app_date_picker_field.dart';
import '../../../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';

/// Enhanced Contractor Form Fields with modern design matching onboarding.
class ContractorFormFields extends StatelessWidget {
  final TextEditingController celularController;
  final MaskTextInputFormatter celularMask;
  final TextEditingController dataNascimentoController;
  final TextEditingController generoController;
  final TextEditingController instagramController;
  final TextEditingController bioController;
  final VoidCallback onChanged;

  const ContractorFormFields({
    super.key,
    required this.celularController,
    required this.celularMask,
    required this.dataNascimentoController,
    required this.generoController,
    required this.instagramController,
    required this.bioController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            value: generoController.text.isEmpty ? null : generoController.text,
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
              generoController.text = v!;
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: instagramController,
            label: 'Instagram (opcional)',
            hint: '@nome',
            prefixIcon: const Icon(Icons.alternate_email, size: 20),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: bioController,
            label: 'Bio',
            maxLines: 3,
            hint: 'Conte um pouco sobre você...',
            onChanged: (_) => onChanged(),
          ),

          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }
}
