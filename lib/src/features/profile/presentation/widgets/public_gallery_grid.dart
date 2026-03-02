import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/image_cache_config.dart';
import '../../../../design_system/components/loading/app_shimmer.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../domain/media_item.dart';

/// Read-only gallery grid for public profile viewing.
class PublicGalleryGrid extends StatefulWidget {
  final List<MediaItem> items;
  final void Function(int index)? onItemTap;

  const PublicGalleryGrid({super.key, required this.items, this.onItemTap});

  @override
  State<PublicGalleryGrid> createState() => _PublicGalleryGridState();
}

class _PublicGalleryGridState extends State<PublicGalleryGrid> {
  final Set<String> _prefetchedUrls = <String>{};

  @override
  void initState() {
    super.initState();
    _schedulePrefetch();
  }

  @override
  void didUpdateWidget(covariant PublicGalleryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _schedulePrefetch();
    }
  }

  void _schedulePrefetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchVisibleThumbs();
    });
  }

  void _prefetchVisibleThumbs() {
    const warmupLimit = 18;
    final previewUrls = widget.items
        .map(
          (item) => item.type == MediaType.video ? item.thumbnailUrl : item.url,
        )
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .take(warmupLimit);

    for (final url in previewUrls) {
      if (!_prefetchedUrls.add(url)) continue;
      unawaited(
        precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: ImageCacheConfig.thumbnailCacheManager,
          ),
          context,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.s4,
        crossAxisSpacing: AppSpacing.s4,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return _GalleryItem(
          item: item,
          onTap: () => widget.onItemTap?.call(index),
        );
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
        ? (item.thumbnailUrl ?? '')
        : item.url;
    final hasPreviewImage = imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'media_${item.id}',
            child: ClipRRect(
              borderRadius: AppRadius.all8,
              child: hasPreviewImage
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final dpr = MediaQuery.devicePixelRatioOf(context);
                        final cacheWidth = (constraints.maxWidth * dpr)
                            .round()
                            .clamp(120, 900)
                            .toInt();
                        final diskWidth = (cacheWidth * 2)
                            .clamp(240, 1400)
                            .toInt();

                        return CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          useOldImageOnUrlChange: true,
                          cacheManager: ImageCacheConfig.thumbnailCacheManager,
                          memCacheWidth: cacheWidth,
                          maxWidthDiskCache: diskWidth,
                          placeholder: (context, url) =>
                              AppShimmer.box(borderRadius: AppRadius.r8),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.videocam_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          if (item.type == MediaType.video)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4,
                  vertical: AppSpacing.s2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.7),
                  borderRadius: AppRadius.all4,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppColors.textPrimary,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
