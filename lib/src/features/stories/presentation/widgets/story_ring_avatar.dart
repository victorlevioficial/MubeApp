import 'package:flutter/material.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';

class StoryRingAvatar extends StatelessWidget {
  const StoryRingAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.photoPreviewUrl,
    this.size = 72,
    this.hasUnseen = false,
    this.hasStory = false,
    this.showAddBadge = false,
  });

  final String name;
  final String? photoUrl;
  final String? photoPreviewUrl;
  final double size;
  final bool hasUnseen;
  final bool hasStory;
  final bool showAddBadge;

  @override
  Widget build(BuildContext context) {
    final shouldShowStoryRing = hasUnseen || hasStory;
    final ringWidth = hasUnseen
        ? 3.0
        : shouldShowStoryRing
        ? 2.5
        : 2.0;
    final innerSize = size - (ringWidth * 2) - 4;
    final ringGradient = hasUnseen
        ? const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryPressed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : hasStory
        ? LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.82),
              AppColors.primaryPressed.withValues(alpha: 0.82),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ringGradient,
              color: ringGradient == null ? AppColors.surfaceHighlight : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(ringWidth),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(AppSpacing.s2),
                child: UserAvatar(
                  photoUrl: photoUrl,
                  photoPreviewUrl: photoPreviewUrl,
                  name: name,
                  size: innerSize,
                  showBorder: false,
                ),
              ),
            ),
          ),
          if (showAddBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.textPrimary,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
