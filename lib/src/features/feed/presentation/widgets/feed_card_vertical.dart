import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Removed
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/design_system/components/buttons/app_like_button.dart';
import 'package:mube/src/design_system/foundations/app_spacing.dart';
import 'package:mube/src/design_system/foundations/app_typography.dart';
import 'package:mube/src/features/favorites/domain/favorite_controller.dart';

import '../../../../common_widgets/user_avatar.dart';
import '../../../../constants/app_constants.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../domain/feed_item.dart'; // Restored

/// A vertical feed card that reactively updates its favorite status.
class FeedCardVertical extends ConsumerStatefulWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const FeedCardVertical({super.key, required this.item, required this.onTap});

  @override
  ConsumerState<FeedCardVertical> createState() => _FeedCardVerticalState();
}

class _FeedCardVerticalState extends ConsumerState<FeedCardVertical> {
  bool _isPressed = false;

  bool get _hasLocationInfo => widget.item.distanceText.isNotEmpty;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    // Favorites logic removed

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onDoubleTap: null,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          padding: AppSpacing.all12,
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
              const SizedBox(width: AppSpacing.s12),

              // Middle: Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Name with Category Icons immediately after
                    Row(
                      children: [
                        // Name (Bold White - Semantic Title)
                        Flexible(
                          child: Text(
                            item.displayName,
                            style: AppTypography.cardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: AppSpacing.s8),

                        // Category Icons - immediately after name
                        _buildCategoryIcons(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s6),

                    // 2. Distance Info (CRITICAL FEATURE!)
                    if (_hasLocationInfo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s6),
                        child: _buildInfoChip(),
                      ),

                    // 3. Skills Chips (Solid gray background) - Single line
                    if (item.skills.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s6),
                        child: _SingleLineChipList(
                          items: item.skills,
                          chipBuilder: _buildSkillChip,
                          overflowBuilder: (count) =>
                              _buildSkillChip('+$count'),
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

              // Right: Like Button with Optimistic UI
              AppLikeButton(
                targetId: item.uid,
                initialCount: item.likeCount,
                initialIsLiked: ref
                    .read(favoriteControllerProvider)
                    .serverFavorites
                    .contains(item.uid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Skill chip: elegant outline style with accent color border
  /// Creates clear visual distinction from genre chips (solid gray)
  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceHighlight, width: 1.2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          widget.item.distanceText,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIcons() {
    final icons = <Widget>[];
    // Use Semantic Action (Pink Pastel) for icons to ensure visibility
    const Color color = AppColors.semanticAction;

    if (widget.item.tipoPerfil == 'profissional') {
      for (final subCatId in widget.item.subCategories) {
        final subCat = professionalCategories.firstWhere(
          (c) => c['id'] == subCatId,
          orElse: () => <String, dynamic>{},
        );
        if (subCat.containsKey('icon')) {
          icons.add(
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s8),
              child: Icon(subCat['icon'] as IconData, size: 14, color: color),
            ),
          );
        }
      }
    } else if (widget.item.tipoPerfil == 'banda') {
      icons.add(
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.s8),
          child: Icon(Icons.people, size: 14, color: color),
        ),
      );
    } else if (widget.item.tipoPerfil == 'estudio') {
      icons.add(
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.s8),
          child: Icon(Icons.headphones, size: 14, color: color),
        ),
      );
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  /// Genre chip: solid gray background for better legibility
  Widget _buildGenreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A widget that displays chips in a single line, showing an overflow indicator
/// (e.g., "+2") if not all items fit.
/// Optimized to avoid LayoutBuilder for every card.
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

    // PERFORMANCE OPTIMIZATION:
    // Instead of LayoutBuilder + Layout Simulation (expensive),
    // we use a specific Wrap-like logic or just a constrained ListView
    // The previous implementation was O(N^2) relative to layout passes.

    // Simplification: display up to 3 items max for skills/genres, then +N.
    // This is a pragmatic trade-off for scrolling performance.
    const maxVisibleItems = 3;

    if (items.length <= maxVisibleItems) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Flexible(child: chipBuilder(items[i])),
          ],
        ],
      );
    }

    // Overflow case
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < maxVisibleItems - 1; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Flexible(child: chipBuilder(items[i])),
        ],
        const SizedBox(width: 6),
        overflowBuilder(items.length - (maxVisibleItems - 1)),
      ],
    );
  }
}
