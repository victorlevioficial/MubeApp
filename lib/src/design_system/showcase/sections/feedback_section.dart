import 'package:flutter/material.dart';

import '../../components/buttons/app_button.dart';
import '../../components/feedback/app_snackbar.dart';
import '../../components/feedback/empty_state_widget.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Seção de demonstração de Feedback components.
class FeedbackSection extends StatelessWidget {
  const FeedbackSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Snackbar Demo', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => AppSnackBar.success(
                context,
                'Operação realizada com sucesso!',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('Success'),
            ),
            ElevatedButton(
              onPressed: () => AppSnackBar.error(context, 'Ocorreu um erro.'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Error'),
            ),
            ElevatedButton(
              onPressed: () =>
                  AppSnackBar.info(context, 'Informação importante.'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceHighlight,
              ),
              child: const Text('Info'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        Text('Empty State', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: EmptyStateWidget(
            icon: Icons.search_off,
            title: 'Nenhum resultado',
            subtitle: 'Não encontramos resultados para sua busca.',
            actionButton: AppButton.primary(
              text: 'Limpar filtros',
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }
}
