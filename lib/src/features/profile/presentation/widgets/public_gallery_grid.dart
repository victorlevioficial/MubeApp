import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../domain/media_item.dart';

/// Read-only gallery grid for public profile viewing.
class PublicGalleryGrid extends StatelessWidget {
  final List<MediaItem> items;
  final void Function(int index)? onItemTap;

  const PublicGalleryGrid({super.key, required this.items, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.s4,
        crossAxisSpacing: AppSpacing.s4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _GalleryItem(item: item, onTap: () => onItemTap?.call(index));
      },
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;

  const _GalleryItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.type == MediaType.video
        ? item.thumbnailUrl ?? item.url
        : item.url;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: AppColors.surface,
                highlightColor: AppColors.surfaceHighlight,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surface,
                child: const Icon(
                  Icons.broken_image,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // Video indicator
          if (item.type == MediaType.video)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
