import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../../../constants/app_constants.dart';
import '../../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';

/// Enhanced Band Form Fields with modern design matching onboarding.
class BandFormFields extends ConsumerWidget {
  final TextEditingController nomeBandaController;
  final List<String> selectedGenres;
  final ValueChanged<List<String>> onGenresChanged;
  final TextEditingController bioController;
  final VoidCallback onChanged;

  const BandFormFields({
    super.key,
    required this.nomeBandaController,
    required this.selectedGenres,
    required this.onGenresChanged,
    required this.bioController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Informacoes da Banda', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: nomeBandaController,
            label: 'Nome da Banda',
            hint: 'Nome exibido no app',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
            validator: (v) => v!.trim().isEmpty ? 'Obrigatorio' : null,
            prefixIcon: const Icon(Icons.groups_outlined, size: 20),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.s16),

          AppTextField(
            controller: bioController,
            label: 'Bio',
            maxLines: 3,
            hint: 'Conte um pouco sobre a banda...',
            onChanged: (_) => onChanged(),
          ),

          const SizedBox(height: AppSpacing.s48),

          Text('Estilo Musical', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Quais generos a banda toca?',
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
                color: selectedGenres.isEmpty
                    ? AppColors.error
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generos Musicais *',
                  style: AppTypography.titleMedium.copyWith(
                    color: selectedGenres.isEmpty
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  selectedGenres.isEmpty
                      ? 'Selecione os estilos que a banda toca'
                      : '${selectedGenres.length} genero${selectedGenres.length > 1 ? 's' : ''} selecionado${selectedGenres.length > 1 ? 's' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (selectedGenres.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      ...selectedGenres.take(3).map((item) {
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
                      }),
                      if (selectedGenres.length > 3)
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
                            '+${selectedGenres.length - 3}',
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
                    text: selectedGenres.isEmpty
                        ? 'Selecionar Generos'
                        : 'Editar Generos',
                    onPressed: () async {
                      final result =
                          await EnhancedMultiSelectModal.show<String>(
                            context: context,
                            title: 'Generos Musicais',
                            subtitle: 'Selecione os estilos da banda',
                            items: genres,
                            selectedItems: selectedGenres,
                            searchHint: 'Buscar genero...',
                          );
                      if (result != null) {
                        onGenresChanged(result);
                        onChanged();
                      }
                    },
                    icon: Icon(
                      selectedGenres.isEmpty ? Icons.add : Icons.edit_outlined,
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
