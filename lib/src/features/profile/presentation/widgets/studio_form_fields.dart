import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/app_dropdown_field.dart';
import '../../../../common_widgets/app_filter_chip.dart';
import '../../../../common_widgets/app_selection_modal.dart';
import '../../../../common_widgets/app_text_field.dart';
import '../../../../common_widgets/secondary_button.dart';
import '../../../../constants/app_constants.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';

class StudioFormFields extends StatefulWidget {
  final TextEditingController celularController;
  final MaskTextInputFormatter celularMask;
  final String? studioType;
  final ValueChanged<String?> onStudioTypeChanged;
  final List<String> selectedServices;
  final VoidCallback onStateChanged;

  const StudioFormFields({
    super.key,
    required this.celularController,
    required this.celularMask,
    required this.studioType,
    required this.onStudioTypeChanged,
    required this.selectedServices,
    required this.onStateChanged,
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
        _buildTagSelector('Serviços', studioServices, widget.selectedServices),
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
                    // Simple mapping for now or use constants map if needed
                    return item;
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
                return AppFilterChip(
                  label:
                      item, // Studio services are usually already labels in constant list? Check app_constants.
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
