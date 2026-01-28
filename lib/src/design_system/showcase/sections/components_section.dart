import 'package:flutter/material.dart';

import '../../../common_widgets/user_avatar.dart'; // Reusing existing UserAvatar for now
import '../../components/chips/app_chip.dart';
import '../../foundations/app_colors.dart';
import '../../foundations/app_spacing.dart';
import '../../foundations/app_typography.dart';

class ComponentsSection extends StatelessWidget {
  const ComponentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ComponentGroup(
          title: 'Chips',
          children: [
            const AppChip(label: 'Skill Chip', variant: AppChipVariant.skill),
            const AppChip(label: 'Genre Chip', variant: AppChipVariant.genre),
            const Text(
              'Filter Chips:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            Wrap(
              spacing: 8,
              children: [
                AppChip(
                  label: 'Unselected',
                  variant: AppChipVariant.filter,
                  isSelected: false,
                  onTap: () {},
                ),
                AppChip(
                  label: 'Selected',
                  variant: AppChipVariant.filter,
                  isSelected: true,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        const _ComponentGroup(
          title: 'Avatars (Existing)',
          children: [
            UserAvatar(name: 'Victor', size: 40),
            UserAvatar(
              name: 'Alice',
              size: 40,
              photoUrl: 'https://i.pravatar.cc/150?img=1',
            ),
          ],
        ),
      ],
    );
  }
}

class _ComponentGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ComponentGroup({required this.title, required this.children});

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
