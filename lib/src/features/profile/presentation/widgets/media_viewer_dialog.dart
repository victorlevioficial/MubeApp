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
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.items.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return _buildMediaItem(item);
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

  Widget _buildMediaItem(MediaItem item) {
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
      return GalleryVideoPlayer(videoUrl: item.url);
    } else {
      return InteractiveViewer(
        child: Center(
          child: CachedNetworkImage(
            imageUrl: item.url,
            fit: BoxFit.contain,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            useOldImageOnUrlChange: true,
            cacheManager: ImageCacheConfig.optimizedCacheManager,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Icon(Icons.error, color: AppColors.error),
          ),
        ),
      );
    }
  }
}
