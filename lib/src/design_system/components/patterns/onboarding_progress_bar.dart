import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';

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
            borderRadius: BorderRadius.circular(2),
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
        const SizedBox(height: 8),
        Text(
          'Etapa $currentStep de $totalSteps',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
