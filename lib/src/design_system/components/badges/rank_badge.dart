import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Badge compacto para ranking (ex: 1, 2, 3).
///
/// Usa a cor primária com opacidade (`primaryMuted`).
class RankBadge extends StatelessWidget {
  final int rank;
  final EdgeInsets padding;
  final double minWidth;
  final double height;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const RankBadge({
    super.key,
    required this.rank,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.s8,
      vertical: AppSpacing.s4,
    ),
    this.minWidth = AppSpacing.s24,
    this.height = AppSpacing.s24,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryMuted,
        borderRadius: AppRadius.pill,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: (textStyle ?? AppTypography.labelSmall).copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTypography.buttonPrimary.fontWeight,
        ),
      ),
    );
  }
}
