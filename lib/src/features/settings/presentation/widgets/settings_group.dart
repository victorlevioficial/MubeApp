import 'package:flutter/material.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

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
          padding: const EdgeInsets.only(
            left: AppSpacing.s4,
            bottom: AppSpacing.s12,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.settingsGroupTitle,
          ),
        ),

        // Group Items
        ...children,

        const SizedBox(height: AppSpacing.s24), // Spacing between groups
      ],
    );
  }
}
