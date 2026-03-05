import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/image_cache_config.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/media_item.dart';
import 'gallery_video_player.dart';

/// Full-screen media viewer dialog
class MediaViewerDialog extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;

  const MediaViewerDialog({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<MediaViewerDialog> createState() => _MediaViewerDialogState();
}

class _MediaViewerDialogState extends State<MediaViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    if (widget.items.isEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = widget.initialIndex
          .clamp(0, widget.items.length - 1)
          .toInt();
    }
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheAround(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _precacheAround(int centerIndex) {
    for (var offset = -1; offset <= 1; offset++) {
      final index = centerIndex + offset;
      if (index < 0 || index >= widget.items.length) continue;
      _precacheItem(widget.items[index]);
    }
  }

  void _precacheItem(MediaItem item) {
    final url = item.type == MediaType.video ? item.thumbnailUrl : item.url;
    if (url == null || url.isEmpty || !mounted) return;

    unawaited(
      precacheImage(
        CachedNetworkImageProvider(
          url,
          cacheManager: ImageCacheConfig.optimizedCacheManager,
        ),
        context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.items.isEmpty)
          Center(
            child: Text(
              'Nenhuma mídia disponível.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          )
        else
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _precacheAround(index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildMediaItem(item, index);
            },
          ),
        // Close button
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: 30,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        // Indicator
        if (widget.items.isNotEmpty)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.items.length}',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaItem(MediaItem item, int index) {
    if (item.type == MediaType.video) {
      if (item.url.contains('youtu')) {
        // Placeholder for Youtube video
        return Center(
          child: Text(
            'Vídeo do YouTube (em breve): ${item.url}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
        );
      }
      // Use GalleryVideoPlayer for network videos
      return GalleryVideoPlayer(
        key: ValueKey('gallery_video_${item.id}_${item.url}'),
        videoUrl: item.url,
        thumbnailUrl: item.thumbnailUrl,
        isActive: _currentIndex == index,
      );
    } else {
      return InteractiveViewer(
        child: Center(
          child: Hero(
            tag: 'media_${item.id}',
            child: CachedNetworkImage(
              imageUrl: item.url,
              fit: BoxFit.contain,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              useOldImageOnUrlChange: true,
              cacheManager: ImageCacheConfig.optimizedCacheManager,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: AppColors.error),
            ),
          ),
        ),
      );
    }
  }
}
