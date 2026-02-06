import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import 'onboarding_progress_bar.dart';

class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button aligned to the left edge of the content
        SizedBox(
          width: 40, // Fixed width to match right spacer
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: onBack,
              padding: EdgeInsets.zero, // Remove internal padding
              alignment: Alignment.centerLeft, // Align icon to the left
              constraints: const BoxConstraints(), // Shrink wrap if needed
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),

        // Centered Progress Bar
        Expanded(
          child: Center(
            child: SizedBox(
              width: 120, // Fixed width for consistency
              child: OnboardingProgressBar(
                currentStep: currentStep,
                totalSteps: totalSteps,
              ),
            ),
          ),
        ),

        // Counter-balance for the back button to ensure perfect centering
        const SizedBox(width: AppSpacing.s40),
      ],
    );
  }
}
