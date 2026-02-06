import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress (e.g. step 1 of 4 = 0.25)
    final double progress = currentStep / totalSteps;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: ClipRRect(
            borderRadius: AppRadius.all4,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  AppColors.surfaceHighlight, // Dark gray background
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Etapa $currentStep de $totalSteps',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
