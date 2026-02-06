import 'package:flutter/material.dart';

import '../../components/loading/app_loading.dart';
import '../../components/loading/app_loading_indicator.dart';
import '../../components/loading/app_shimmer.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Seção de demonstração de Loading states.
class LoadingSection extends StatelessWidget {
  const LoadingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AppLoading (Simple)', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        const Row(
          children: [
            AppLoading.small(),
            SizedBox(width: AppSpacing.s16),
            AppLoading.medium(),
            SizedBox(width: AppSpacing.s16),
            AppLoading.large(),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        Text(
          'AppLoadingIndicator (With Message)',
          style: AppTypography.titleSmall,
        ),
        const SizedBox(height: AppSpacing.s8),
        const Row(
          children: [
            AppLoadingIndicator.small(),
            SizedBox(width: AppSpacing.s24),
            AppLoadingIndicator.medium(),
            SizedBox(width: AppSpacing.s24),
            AppLoadingIndicator.large(),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        const AppLoadingIndicator.withMessage('Carregando...'),
        const SizedBox(height: AppSpacing.s24),

        Text('AppShimmer', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        AppShimmer(
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all12,
            ),
          ),
        ),
      ],
    );
  }
}
