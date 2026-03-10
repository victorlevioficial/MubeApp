import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import 'star_rating_widget.dart';

class UserRatingDisplay extends StatelessWidget {
  const UserRatingDisplay({
    super.key,
    required this.averageRating,
    required this.reviewCount,
    this.isLoading = false,
  });

  final double? averageRating;
  final int reviewCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Text(
        'Carregando avaliações...',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      );
    }

    if (averageRating == null || reviewCount <= 0) {
      return Text(
        'Sem avaliacoes ainda',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRatingWidget(rating: averageRating!.round().clamp(0, 5), size: 18),
        const SizedBox(width: AppSpacing.s8),
        Text(
          '${averageRating!.toStringAsFixed(1)} ($reviewCount)',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
