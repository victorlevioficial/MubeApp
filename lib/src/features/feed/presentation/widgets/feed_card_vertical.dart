import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/user_avatar.dart';
import '../../../../constants/app_constants.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../data/feed_favorite_service.dart';
import '../../domain/feed_item.dart';
import '../feed_favorite_controller.dart';
import '../feed_favorite_logic_extension.dart';
import 'animated_favorite_button.dart';

/// A vertical feed card that reactively updates its favorite status.
class FeedCardVertical extends ConsumerWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const FeedCardVertical({super.key, required this.item, required this.onTap});

  /// Returns true if there's distance info to display.
  bool get _hasLocationInfo => item.distanceText.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Obter Stream de dados reais (Servidor)
    final favoriteCountAsync = ref.watch(favoriteCountProvider(item.uid));
    final isFavoritedAsync = ref.watch(isFavoritedProvider(item.uid));

    // 2. Obter Estado Otimista (Controller)
    final favState = ref.watch(feedFavoriteControllerProvider);

    // 3. Lógica Centralizada (Extension)
    // Mantém a UI limpa e a regra de negócio testável/reutilizável
    final isFavorited = favState.isFavorited(
      item.uid,
      isFavoritedAsync.value ?? false,
    );

    final displayCount = favState.displayCount(
      item.uid,
      favoriteCountAsync.value ?? item.favoriteCount,
      isFavoritedAsync.value ?? false,
    );

    // Listen for global errors (only show if it matches this item or generic)
    ref.listen(feedFavoriteControllerProvider, (prev, next) {
      if (next.error != null && next.inFlight.isEmpty) {
        // Simple toast mechanism or ignoring if handled globally
        // For now, we rely on the controller state to know rollback happened
      }
    });

    void handleLike() {
      ref
          .read(feedFavoriteControllerProvider.notifier)
          .toggleFavorite(target: item, currentIsFavorited: isFavorited);
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () {
        // Double tap apenas favorita (se nao estiver favoritado)
        if (!isFavorited) {
          handleLike();
        }
      },
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
                  // 1. Name with Category Icons immediately after
                  Row(
                    children: [
                      // Name (Bold White)
                      Flexible(
                        child: Text(
                          item.displayName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Category Icons - immediately after name
                      _buildCategoryIcons(),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 2. Distance Info (CRITICAL FEATURE!)
                  if (_hasLocationInfo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildInfoChip(),
                    ),

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

            // Right: Like Button (V8 Implementation)
            Column(
              children: [
                AnimatedFavoriteButton(
                  isFavorited: isFavorited,
                  onTap: handleLike,
                  size: 24,
                  favoriteColor: AppColors.primary,
                  defaultColor: Colors.white54,
                ),
                if (displayCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$displayCount',
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

  /// Skill chip: elegant outline style with accent color border
  /// Creates clear visual distinction from genre chips (solid gray)
  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.accent.withValues(alpha: 0.95),
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
          item.distanceText,
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
              padding: const EdgeInsets.only(left: 8),
              child: Icon(subCat['icon'] as IconData, size: 14, color: color),
            ),
          );
        }
      }
    } else if (item.tipoPerfil == 'banda') {
      icons.add(
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.people, size: 14, color: color),
        ),
      );
    } else if (item.tipoPerfil == 'estudio') {
      icons.add(
        const Padding(
          padding: EdgeInsets.only(left: 8),
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
          color: Color(0xFFE0E0E0),
          fontSize: 10,
          fontWeight: FontWeight.w500,
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
