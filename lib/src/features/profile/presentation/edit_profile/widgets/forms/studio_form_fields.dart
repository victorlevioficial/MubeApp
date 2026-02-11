import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';

class StudioFormFields extends StatefulWidget {
  final TextEditingController celularController;
  final TextEditingController bioController;
  final MaskTextInputFormatter celularMask;
  final String? studioType;
  final ValueChanged<String?> onStudioTypeChanged;
  final List<String> selectedServices;
  final ValueChanged<List<String>> onServicesChanged;

  const StudioFormFields({
    super.key,
    required this.celularController,
    required this.bioController,
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
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: widget.bioController,
          label: 'Bio',
          maxLines: 3,
          hint: 'Conte um pouco sobre o estúdio...',
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
