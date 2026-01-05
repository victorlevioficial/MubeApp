import 'package:flutter/material.dart';

import '../../../../common_widgets/user_avatar.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../domain/feed_item.dart';

/// Compact card for horizontal feed sections (~160px width).
class FeedCardCompact extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const FeedCardCompact({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with initials fallback
            UserAvatar(photoUrl: item.foto, name: item.displayName, size: 140),
            const SizedBox(height: AppSpacing.s8),
            // Name
            Text(
              item.displayName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // Distance
            if (item.distanceText.isNotEmpty)
              Text(
                item.distanceText,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
