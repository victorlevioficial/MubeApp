import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/gig_status.dart';

class GigStatusBadge extends StatelessWidget {
  const GigStatusBadge({super.key, required this.status});

  final GigStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      GigStatus.open => AppColors.success,
      GigStatus.closed => AppColors.info,
      GigStatus.expired => AppColors.warning,
      GigStatus.cancelled => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
