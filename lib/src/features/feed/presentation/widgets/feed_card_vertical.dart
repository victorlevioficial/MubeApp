import 'package:flutter/material.dart';
import '../../../../common_widgets/user_avatar.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../domain/feed_item.dart';
import 'animated_favorite_button.dart';

class FeedCardVertical extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool? isFavorited;

  const FeedCardVertical({
    super.key,
    required this.item,
    required this.onTap,
    this.onFavorite,
    this.isFavorited,
  });

  /// Returns true if favorited: uses explicit prop if provided, else checks count.
  bool get _isFavorited => isFavorited ?? (item.favoriteCount > 0);

  /// Returns true if there's distance info to display.
  bool get _hasLocationInfo => item.distanceText.isNotEmpty;

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

                  // 2. Location Row: Distance + City/State
                  if (_hasLocationInfo)
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
                          Expanded(
                            child: Text(
                              item.distanceText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 4),

                  // 3. Skills Chips (Solid gray background) - Single line
                  if (item.skills.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _SingleLineChipList(
                        items: item.skills,
                        chipBuilder: _buildSkillChip,
                        overflowBuilder: (count) => _buildSkillChip('+$count'),
                      ),
                    ),

                  // 4. Genres Chips (Solid primary color) - Single line
                  if (item.generosMusicais.isNotEmpty)
                    _SingleLineChipList(
                      items: item.generosMusicais,
                      chipBuilder: _buildGenreChip,
                      overflowBuilder: (count) => _buildGenreChip('+$count'),
                    ),
                ],
              ),
            ),

            // Right: Like Button (Top Aligned)
            Column(
              children: [
                AnimatedFavoriteButton(
                  isFavorited: _isFavorited,
                  onTap: onFavorite,
                  size: 24,
                  favoriteColor: AppColors.primary,
                  defaultColor: Colors.white54,
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

/// A widget that displays chips in a single line, showing an overflow indicator
/// (e.g., "+2") if not all items fit. Uses layout measurement to determine fit.
class _SingleLineChipList extends StatelessWidget {
  final List<String> items;
  final Widget Function(String label) chipBuilder;
  final Widget Function(int count) overflowBuilder;

  const _SingleLineChipList({
    required this.items,
    required this.chipBuilder,
    required this.overflowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        if (maxWidth == double.infinity || maxWidth <= 0) {
          // Fallback: show first item only
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [chipBuilder(items.first)],
          );
        }

        // Estimate chip widths. This is an approximation.
        // Formula: ~8px per character + 20px padding
        double estimateChipWidth(String label) {
          return (label.length * 7.0) + 24.0;
        }

        const double overflowChipWidth = 40.0; // "+XX" is roughly this wide

        final List<Widget> visibleChips = [];
        double usedWidth = 0.0;
        int visibleCount = 0;

        for (int i = 0; i < items.length; i++) {
          final chipWidth = estimateChipWidth(items[i]);

          // Reserve space for overflow chip if there are more items after this
          final bool needsOverflowSpace = (i < items.length - 1);
          final double reservedSpace = needsOverflowSpace
              ? overflowChipWidth + 6.0
              : 0.0;

          // Check if this chip fits
          final potentialWidth =
              usedWidth +
              chipWidth +
              (visibleChips.isNotEmpty ? 6.0 : 0.0) +
              reservedSpace;

          if (potentialWidth <= maxWidth) {
            // This chip fits
            if (visibleChips.isNotEmpty) {
              visibleChips.add(const SizedBox(width: 6.0));
            }
            visibleChips.add(chipBuilder(items[i]));
            usedWidth += chipWidth + (visibleChips.length > 1 ? 6.0 : 0.0);
            visibleCount++;
          } else {
            // This chip doesn't fit - add overflow indicator
            final overflowCount = items.length - visibleCount;
            if (overflowCount > 0) {
              if (visibleChips.isNotEmpty) {
                visibleChips.add(const SizedBox(width: 6.0));
              }
              visibleChips.add(overflowBuilder(overflowCount));
            }
            break;
          }

          // If this is the last item and it fit, no overflow needed
          if (i == items.length - 1) {
            break;
          }
        }

        // Edge case: if nothing fit, at least show the overflow indicator
        if (visibleChips.isEmpty && items.isNotEmpty) {
          visibleChips.add(overflowBuilder(items.length));
        }

        return SizedBox(
          height: 24.0,
          child: Row(mainAxisSize: MainAxisSize.min, children: visibleChips),
        );
      },
    );
  }
}
