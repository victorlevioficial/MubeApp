import 'package:flutter/material.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_typography.dart';

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsGroup({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 2.0, // Wider tracking for elegance
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),

        // Group Items
        ...children,

        const SizedBox(height: 24), // Spacing between groups
      ],
    );
  }
}
