import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/app_date_picker_field.dart';
import '../../../../common_widgets/app_dropdown_field.dart';
import '../../../../common_widgets/app_text_field.dart';
import '../../../../design_system/foundations/app_spacing.dart';

class ContractorFormFields extends StatefulWidget {
  final TextEditingController celularController;
  final TextEditingController dataNascimentoController;
  final TextEditingController generoController;
  final TextEditingController instagramController;
  final MaskTextInputFormatter celularMask;
  final VoidCallback onStateChanged;

  const ContractorFormFields({
    super.key,
    required this.celularController,
    required this.dataNascimentoController,
    required this.generoController,
    required this.instagramController,
    required this.celularMask,
    required this.onStateChanged,
  });

  @override
  State<ContractorFormFields> createState() => _ContractorFormFieldsState();
}

class _ContractorFormFieldsState extends State<ContractorFormFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }
}
