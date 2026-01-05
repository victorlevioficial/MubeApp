import 'package:flutter/material.dart';

import '../../../../common_widgets/user_avatar.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../domain/feed_item.dart';

/// Full-width card for vertical lists with like button.
class FeedCardFull extends StatelessWidget {
  final FeedItem item;
  final bool isFavorited;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const FeedCardFull({
    super.key,
    required this.item,
    required this.isFavorited,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s16),
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar
            UserAvatar(photoUrl: item.foto, name: item.displayName, size: 80),
            const SizedBox(width: AppSpacing.s12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    item.displayName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Category
                  if (item.categoria != null)
                    Text(
                      item.categoria!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Location + Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _buildLocationText(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Genres
                  if (item.generosMusicais.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.generosMusicais.take(3).join(' • '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Like button + count
            Column(
              children: [
                IconButton(
                  onPressed: onFavoriteTap,
                  icon: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${item.favoriteCount}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildLocationText() {
    final parts = <String>[];

    if (item.distanceText.isNotEmpty) {
      parts.add(item.distanceText);
    }

    if (item.location != null) {
      final bairro = item.location!['bairro'] as String?;
      final cidade = item.location!['cidade'] as String?;
      final estado = item.location!['estado'] as String?;

      if (bairro != null && bairro.isNotEmpty) {
        parts.add(bairro);
      } else if (cidade != null && cidade.isNotEmpty) {
        parts.add(cidade);
      }

      if (estado != null && estado.isNotEmpty) {
        parts.add(estado);
      }
    }

    return parts.join(' • ');
  }
}
