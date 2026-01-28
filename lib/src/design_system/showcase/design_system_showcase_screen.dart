import 'package:flutter/material.dart';

import '../../common_widgets/mube_app_bar.dart';
import '../foundations/app_colors.dart';
import '../foundations/app_spacing.dart';
import '../foundations/app_typography.dart';
import 'sections/buttons_section.dart';
import 'sections/colors_section.dart';
import 'sections/components_section.dart';
import 'sections/inputs_section.dart';
import 'sections/typography_section.dart';

class DesignSystemShowcaseScreen extends StatelessWidget {
  const DesignSystemShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MubeAppBar(title: 'Design System'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: const [
          _SectionHeader(title: '1. Colors'),
          ColorsSection(),
          SizedBox(height: AppSpacing.s32),

          _SectionHeader(title: '2. Typography'),
          TypographySection(),
          SizedBox(height: AppSpacing.s32),

          _SectionHeader(title: '3. Buttons'),
          ButtonsSection(),
          SizedBox(height: AppSpacing.s32),

          _SectionHeader(title: '4. Inputs'),
          InputsSection(),
          SizedBox(height: AppSpacing.s32),

          _SectionHeader(title: '5. Components'),
          ComponentsSection(),
          SizedBox(height: AppSpacing.s32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.semanticAction,
            ),
          ),
          const Divider(color: AppColors.surfaceHighlight),
        ],
      ),
    );
  }
}
