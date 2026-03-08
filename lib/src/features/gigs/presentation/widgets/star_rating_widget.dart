import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';

class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.size = 28,
  });

  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isActive = value <= rating;

        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.s4),
          child: InkWell(
            onTap: onRatingChanged == null
                ? null
                : () => onRatingChanged!(value),
            borderRadius: BorderRadius.circular(size),
            child: Icon(
              isActive ? Icons.star_rounded : Icons.star_border_rounded,
              color: isActive ? AppColors.warning : AppColors.textTertiary,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
