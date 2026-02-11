import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/providers/app_config_provider.dart';
import '../../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';

class BandFormFields extends ConsumerStatefulWidget {
  final List<String> selectedGenres;
  final ValueChanged<List<String>> onGenresChanged;
  final TextEditingController bioController;

  const BandFormFields({
    super.key,
    required this.selectedGenres,
    required this.onGenresChanged,
    required this.bioController,
  });

  @override
  ConsumerState<BandFormFields> createState() => _BandFormFieldsState();
}

class _BandFormFieldsState extends ConsumerState<BandFormFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s16),
        _buildTagSelector(
          'Gêneros Musicais',
          ref.watch(genreLabelsProvider),
          widget.selectedGenres,
          widget.onGenresChanged,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: widget.bioController,
          label: 'Bio',
          maxLines: 3,
          hint: 'Conte um pouco sobre a banda...',
        ),
        const SizedBox(height: AppSpacing.s24),
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
