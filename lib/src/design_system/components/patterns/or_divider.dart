import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

class OrDivider extends StatelessWidget {
  final String text;

  const OrDivider({super.key, this.text = 'Ou'});

  /// Share of the row the label may take before it starts truncating. Leaves
  /// room for a visible rule on each side.
  static const double _maxLabelWidthFactor = 0.7;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: Divider(
                color: Theme.of(context).colorScheme.outline,
                thickness: 1,
              ),
            ),
            // Natural width up to a cap: keeps the label intact on normal
            // screens and lets it ellipsize on narrow ones instead of
            // overflowing the row.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * _maxLabelWidthFactor,
              ),
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
      },
    );
  }
}
