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
      child: SizedBox(
        width: 110,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 160.0;
            final avatarSize = (maxHeight - 56).clamp(84.0, 96.0);
            final nameSpacing = maxHeight < 156 ? AppSpacing.s4 : AppSpacing.s8;
            final metaSpacing = maxHeight < 156 ? AppSpacing.s2 : AppSpacing.s4;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatar(
                  photoUrl: item.foto,
                  name: item.displayName,
                  size: avatarSize,
                ),
                SizedBox(height: nameSpacing),
                Text(
                  item.displayName,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: AppTypography.buttonPrimary.fontWeight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: metaSpacing),
                SizedBox(
                  width: constraints.maxWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.distanceText.isNotEmpty) ...[
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 10,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.s2),
                              Flexible(
                                child: Text(
                                  item.distanceText,
                                  style: AppTypography.chipLabel.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s4),
                      ],
                      _buildProfileTypeIcon(),
                    ],
                  ),
                ),
              ],
            );
          },
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
