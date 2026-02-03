import 'package:flutter/material.dart';
import '../../components/buttons/app_button.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

class ButtonsSection extends StatelessWidget {
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ButtonGroup(
          title: 'Primary',
          children: [
            AppButton.primary(text: 'Primary Button', onPressed: () {}),
            const SizedBox(height: AppSpacing.s8),
            AppButton.primary(
              text: 'Loading',
              isLoading: true,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.s8),
            const AppButton.primary(text: 'Disabled', onPressed: null),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ButtonGroup(
          title: 'Secondary',
          children: [
            AppButton.secondary(text: 'Secondary Button', onPressed: () {}),
            const SizedBox(height: AppSpacing.s8),
            AppButton.secondary(
              text: 'With Icon',
              icon: const Icon(Icons.star, size: 18),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ButtonGroup(
          title: 'Outline',
          children: [
            AppButton.outline(text: 'Outline Button', onPressed: () {}),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ButtonGroup(
          title: 'Ghost',
          children: [AppButton.ghost(text: 'Ghost Button', onPressed: () {})],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ButtonGroup(
          title: 'Sizes',
          children: [
            AppButton.primary(
              text: 'Small',
              size: AppButtonSize.small,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.s8),
            AppButton.primary(
              text: 'Medium',
              size: AppButtonSize.medium,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.s8),
            AppButton.primary(
              text: 'Large',
              size: AppButtonSize.large,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _ButtonGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ButtonGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: children,
        ),
      ],
    );
  }
}
