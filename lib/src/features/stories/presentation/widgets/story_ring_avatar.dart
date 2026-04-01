import 'package:flutter/material.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';

class StoryRingAvatar extends StatelessWidget {
  const StoryRingAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.photoPreviewUrl,
    this.size = 72,
    this.hasUnseen = false,
    this.showAddBadge = false,
  });

  final String name;
  final String? photoUrl;
  final String? photoPreviewUrl;
  final double size;
  final bool hasUnseen;
  final bool showAddBadge;

  @override
  Widget build(BuildContext context) {
    final ringWidth = hasUnseen ? 3.0 : 2.0;
    final innerSize = size - (ringWidth * 2) - 4;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnseen
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryPressed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasUnseen ? null : AppColors.surfaceHighlight,
            ),
            child: Padding(
              padding: EdgeInsets.all(ringWidth),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
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
                  border: Border.all(
                    color: AppColors.background,
                    width: 2,
                  ),
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
