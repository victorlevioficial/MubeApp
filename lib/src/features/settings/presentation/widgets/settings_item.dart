import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_icons.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

/// Reusable settings row widget.
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;
  final Color? iconColor;
  final Color? textColor;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.all16,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  AppIcons.arrowForward,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.surfaceHighlight,
            indent: 54,
          ),
      ],
    );
  }
}
