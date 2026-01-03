import 'package:flutter/material.dart';
import '../../../../common_widgets/app_selection_modal.dart';
import '../../../../common_widgets/app_filter_chip.dart';
import '../../../../common_widgets/secondary_button.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../../../constants/app_constants.dart';

class BandFormFields extends StatefulWidget {
  final List<String> selectedGenres;
  final VoidCallback onStateChanged;

  const BandFormFields({
    super.key,
    required this.selectedGenres,
    required this.onStateChanged,
  });

  @override
  State<BandFormFields> createState() => _BandFormFieldsState();
}

class _BandFormFieldsState extends State<BandFormFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s16),
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
                  itemLabelBuilder: (item) => item,
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
                  label: item,
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
