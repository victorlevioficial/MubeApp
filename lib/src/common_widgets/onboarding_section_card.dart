import 'package:flutter/material.dart';
import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_radius.dart';
import '../design_system/foundations/app_spacing.dart';
import '../design_system/foundations/app_typography.dart';

class OnboardingSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const OnboardingSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.s24),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}
