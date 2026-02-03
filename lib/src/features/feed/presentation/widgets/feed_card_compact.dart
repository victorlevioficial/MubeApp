import 'package:flutter/material.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
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
        width: 110,
        margin: const EdgeInsets.only(right: AppSpacing.s12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with initials fallback (Smaller photo as requested: 110)
            UserAvatar(photoUrl: item.foto, name: item.displayName, size: 110),
            const SizedBox(height: AppSpacing.s8),

            // Name
            Text(
              item.displayName,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.s4),

            // Location & Profile Type Icon (Same row to save space)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Location Info
                if (item.distanceText.isNotEmpty) ...[
                  const Icon(
                    Icons.location_on,
                    size: 10,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    item.distanceText,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: AppSpacing.s6),
                ],
                // Profile Type Icon
                _buildProfileTypeIcon(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Profile type icon with color based on type
  Widget _buildProfileTypeIcon() {
    IconData icon;
    Color color;

    switch (item.tipoPerfil) {
      case 'banda':
        icon = Icons.groups;
        color = AppColors.badgeBand;
        break;
      case 'estudio':
        icon = Icons.headphones;
        color = AppColors.badgeStudio;
        break;
      case 'profissional':
      default:
        // All professionals (musicians, vocalists, crew) get music note
        icon = Icons.music_note;
        color = AppColors.badgeMusician;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }
}
