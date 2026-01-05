import 'package:flutter/material.dart';
import '../../../../common_widgets/user_avatar.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../domain/feed_item.dart';

class FeedCardVertical extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  const FeedCardVertical({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Large Avatar
            UserAvatar(photoUrl: item.foto, name: item.displayName, size: 80),
            const SizedBox(width: 12),

            // Middle: Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Name (Bold White) - TOP Priority
                  Text(
                    item.displayName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 2. Row: Only Distance
                  if (item.distanceText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.distanceText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 4),

                  // 3. Skills Chips (Solid gray background)
                  if (item.skills.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.skills.take(3).map((skill) {
                          return _buildSkillChip(skill);
                        }).toList(),
                      ),
                    ),

                  // 4. Genres Chips (Solid primary color)
                  if (item.generosMusicais.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.generosMusicais.take(3).map((genre) {
                        return _buildGenreChip(genre);
                      }).toList(),
                    ),
                ],
              ),
            ),

            // Right: Like Button (Top Aligned)
            Column(
              children: [
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    item.favoriteCount > 0
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: item.favoriteCount > 0
                        ? AppColors.primary
                        : Colors.white54,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                if (item.favoriteCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.favoriteCount}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Skill chip: solid gray background (instruments, services, roles)
  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight, // Solid gray
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE0E0E0), // Light gray text
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Genre chip: primary solid background for maximum impact and legibility
  Widget _buildGenreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary, // Solid pink
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary, // White text
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
