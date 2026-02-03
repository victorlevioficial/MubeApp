import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../constants/app_constants.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';

class StudioFormFields extends StatefulWidget {
  final TextEditingController celularController;
  final MaskTextInputFormatter celularMask;
  final String? studioType;
  final ValueChanged<String?> onStudioTypeChanged;
  final List<String> selectedServices;
  final ValueChanged<List<String>> onServicesChanged;

  const StudioFormFields({
    super.key,
    required this.celularController,
    required this.celularMask,
    required this.studioType,
    required this.onStudioTypeChanged,
    required this.selectedServices,
    required this.onServicesChanged,
  });

  @override
  State<StudioFormFields> createState() => _StudioFormFieldsState();
}

class _StudioFormFieldsState extends State<StudioFormFields> {
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
        AppDropdownField<String>(
          label: 'Tipo de Estúdio',
          value: widget.studioType,
          items: const [
            DropdownMenuItem(value: 'commercial', child: Text('Comercial')),
            DropdownMenuItem(value: 'home_studio', child: Text('Home Studio')),
          ],
          onChanged: widget.onStudioTypeChanged,
        ),
        const SizedBox(height: AppSpacing.s24),
        _buildTagSelector(
          'Serviços',
          studioServices,
          widget.selectedServices,
          widget.onServicesChanged,
        ),
      ],
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
                  itemLabelBuilder: (item) => item,
                ),
              );

              AppLogger.info('📋 StudioFormFields Modal returned: $result for $label');
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
