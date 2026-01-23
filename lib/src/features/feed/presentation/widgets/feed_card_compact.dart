import 'package:flutter/material.dart';
import '../../../../common_widgets/user_avatar.dart';
import '../../../../constants/app_constants.dart';
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

            // Location & Category Info (Vertical to prevent overflow)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location Info Chip
                if (item.distanceText.isNotEmpty) _buildInfoChip(),

                // Category Icons (Below location)
                if (item.tipoPerfil == 'profissional' ||
                    item.tipoPerfil == 'banda' ||
                    item.tipoPerfil == 'estudio') ...[
                  const SizedBox(height: 4),
                  _buildCategoryIcons(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        ],
      ),
    );
  }

  Widget _buildCategoryIcons() {
    final icons = <Widget>[];
    const Color color = AppColors.primary;

    if (item.tipoPerfil == 'profissional') {
      for (final subCatId in item.subCategories) {
        final subCat = professionalCategories.firstWhere(
          (c) => c['id'] == subCatId,
          orElse: () => <String, dynamic>{},
        );
        if (subCat.containsKey('icon')) {
          icons.add(
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(subCat['icon'] as IconData, size: 12, color: color),
            ),
          );
        }
      }
    } else if (item.tipoPerfil == 'banda') {
      icons.add(
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.people, size: 12, color: color),
        ),
      );
    } else if (item.tipoPerfil == 'estudio') {
      icons.add(
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.headphones, size: 12, color: color),
        ),
      );
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }
}
