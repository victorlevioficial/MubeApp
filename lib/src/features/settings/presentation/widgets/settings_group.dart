import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

/// Professional settings group with refined section header
///
/// Features:
/// - Uppercase tracked section labels
/// - Refined spacing and visual hierarchy
/// - Subtle separator line
/// - Better visual grouping of items
class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsGroup({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with refined styling
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.s4,
            bottom: AppSpacing.s12,
          ),
          child: Row(
            children: [
              // Section label
              Text(
                title.toUpperCase(),
                style: AppTypography.settingsGroupTitle.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),

              const SizedBox(width: AppSpacing.s12),

              // Subtle separator line
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.textSecondary.withValues(alpha: 0.15),
                        AppColors.textSecondary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Settings items
        ...children,

        // Bottom spacing
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }
}
