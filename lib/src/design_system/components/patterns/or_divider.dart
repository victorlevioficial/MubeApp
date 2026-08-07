import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

class OrDivider extends StatelessWidget {
  final String text;

  const OrDivider({super.key, this.text = 'Ou'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline,
            thickness: 1,
          ),
        ),
        // High flex with the default loose fit: the label takes only the width
        // it needs and the rules split what is left, but on a narrow screen it
        // can still shrink instead of overflowing the row.
        Flexible(
          flex: 100,
          child: Padding(
            padding: AppSpacing.h16,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
