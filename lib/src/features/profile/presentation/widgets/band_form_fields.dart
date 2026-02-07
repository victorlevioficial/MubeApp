import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';

class BandFormFields extends ConsumerStatefulWidget {
  final List<String> selectedGenres;
  final ValueChanged<List<String>> onGenresChanged;

  const BandFormFields({
    super.key,
    required this.selectedGenres,
    required this.onGenresChanged,
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
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
                backgroundColor: AppColors.transparent,
                builder: (context) => AppSelectionModal(
                  title: label,
                  items: options,
                  selectedItems: selected,
                  allowMultiple: true,
                  itemLabelBuilder: (item) => item,
                ),
              );

              AppLogger.info('📋 BandFormFields Modal returned: $result for $label');
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
