import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/user_avatar.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/favorites_provider.dart';
import '../../data/feed_repository.dart';
import '../../domain/feed_item.dart';
import 'animated_favorite_button.dart';

/// A vertical feed card that reactively updates its favorite status.
/// Uses ConsumerWidget with ref.select() for granular rebuilds.
/// A vertical feed card that manages its own favorite state locally.
class FeedCardVertical extends ConsumerStatefulWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const FeedCardVertical({super.key, required this.item, required this.onTap});

  @override
  ConsumerState<FeedCardVertical> createState() => _FeedCardVerticalState();
}

class _FeedCardVerticalState extends ConsumerState<FeedCardVertical> {
  late bool _isFavorited;
  late int _favoriteCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize state from the passed item
    _isFavorited = widget.item.isFavorited;
    _favoriteCount = widget.item.favoriteCount;
  }

  @override
  void didUpdateWidget(FeedCardVertical oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent passes a new item with DIFFERENT favorite status, sync it.
    // This handles scenarios where the parent list refreshes from server.
    if (widget.item.isFavorited != oldWidget.item.isFavorited ||
        widget.item.favoriteCount != oldWidget.item.favoriteCount) {
      // Only update if we are not currently toggling to avoid glitches
      if (!_isLoading) {
        _isFavorited = widget.item.isFavorited;
        _favoriteCount = widget.item.favoriteCount;
      }
    }
  }

  /// Toggle favorite status locally and sync with server
  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    // 1. Optimistic Update
    setState(() {
      _isLoading = true;
      _isFavorited = !_isFavorited;
      _favoriteCount += _isFavorited ? 1 : -1;
      // Clamp to prevent negative counts
      if (_favoriteCount < 0) _favoriteCount = 0;
    });

    try {
      // 2. Server Sync
      final feedRepository = ref.read(feedRepositoryProvider);

      // We don't need the result bool because we trust our optimistic update
      // unless it throws an error.
      await feedRepository.toggleFavorite(
        userId: user.uid,
        targetId: widget.item.uid,
      );

      // Also update the centralized favorites provider list so other screens allow consistency
      // (Like the favorites screen list)
      final favoritesNotifier = ref.read(favoritesProvider.notifier);
      if (_isFavorited) {
        favoritesNotifier.addFavorite(widget.item.uid);
      } else {
        favoritesNotifier.removeFavorite(widget.item.uid);
      }
    } catch (e) {
      // 3. Revert on Error
      print('DEBUG: Erro ao favoritar, revertendo UI: $e');
      if (mounted) {
        setState(() {
          _isFavorited = !_isFavorited; // Flip back
          _favoriteCount += _isFavorited ? 1 : -1; // Revert count
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar favorito. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Returns true if there's distance info to display.
  bool get _hasLocationInfo => widget.item.distanceText.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // We intentionally IGNORE generic providers here to avoid the complexity that caused bugs.
    // This widget is now self-contained for its interaction logic.

    // However, we initial check if the global favorites provider knows this item status
    // This is useful for initial load consistency if the item came from a non-user-specific query
    final globalIsFavorited = ref
        .read(favoritesProvider)
        .isFavorited(widget.item.uid);
    if (!_isLoading &&
        _isFavorited != globalIsFavorited &&
        widget.item.isFavorited != globalIsFavorited) {
      // If local state differs from global source of truth, and we aren't loading, sync once.
      // This handles the "Hot Reload" case where global favorites load late.
      _isFavorited = globalIsFavorited;

      // Note: We can't easily sync count from global provider as it only stores IDs,
      // so we rely on the item's count or our local modifications.
    }

    return GestureDetector(
      onTap: widget.onTap,
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
            UserAvatar(
              photoUrl: widget.item.foto,
              name: widget.item.displayName,
              size: 80,
            ),
            const SizedBox(width: 12),

            // Middle: Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Name (Bold White) - TOP Priority
                  Text(
                    widget.item.displayName,
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
                              widget.item.distanceText,
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
                  if (widget.item.skills.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _SingleLineChipList(
                        items: widget.item.skills,
                        chipBuilder: _buildSkillChip,
                        overflowBuilder: (count) => _buildSkillChip('+$count'),
                      ),
                    ),

                  // 4. Genres Chips (Solid primary color) - Single line
                  if (widget.item.generosMusicais.isNotEmpty)
                    _SingleLineChipList(
                      items: widget.item.generosMusicais,
                      chipBuilder: _buildGenreChip,
                      overflowBuilder: (count) => _buildGenreChip('+$count'),
                    ),
                ],
              ),
            ),

            // Right: Like Button (Top Aligned) - Uses local state
            Column(
              children: [
                AnimatedFavoriteButton(
                  isFavorited: _isFavorited,
                  onTap: _toggleFavorite,
                  size: 24,
                  favoriteColor: AppColors.primary,
                  defaultColor: Colors.white54,
                ),
                if (_favoriteCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$_favoriteCount',
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
