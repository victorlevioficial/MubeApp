import 'package:flutter/material.dart';
import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_typography.dart';

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
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
