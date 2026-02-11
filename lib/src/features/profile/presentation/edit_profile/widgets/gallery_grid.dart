import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

import '../../../../../design_system/components/loading/app_shimmer.dart';
import '../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../domain/media_item.dart';

/// Reorderable gallery grid with separate sections for Photos and Videos.
class GalleryGrid extends StatefulWidget {
  final List<MediaItem> items;
  final int maxPhotos;
  final int maxVideos;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddVideo;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool isUploading;
  final double uploadProgress;
  final String uploadStatus;

  const GalleryGrid({
    super.key,
    required this.items,
    this.maxPhotos = 6,
    this.maxVideos = 3,
    required this.onAddPhoto,
    required this.onAddVideo,
    required this.onRemove,
    required this.onReorder,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadStatus = '',
  });

  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> {
  // Filters for separate sections
  List<MediaItem> get _photos =>
      widget.items.where((i) => i.type == MediaType.photo).toList();
  List<MediaItem> get _videos =>
      widget.items.where((i) => i.type == MediaType.video).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text('Portfólio de Mídia', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Adicione fotos e vídeos do seu trabalho',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s32),

          // --- Photos Section ---
          Text('Galeria de Fotos', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Adicione até ${widget.maxPhotos} fotos do seu trabalho',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),

          _buildPhotosGrid(),

          const SizedBox(height: AppSpacing.s32),

          // --- Videos Section ---
          Text('Vídeos', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Adicione até ${widget.maxVideos} vídeos', // Removed "(YouTube ou upload)"
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),

          _buildVideosList(),

          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    final photos = _photos;
    final emptyCount = widget.maxPhotos - photos.length;

    return ReorderableBuilder<MediaItem>(
      onReorder: (reorderFunc) {
        final reordered = reorderFunc(List<MediaItem>.from(photos));
        for (int i = 0; i < photos.length; i++) {
          if (i < reordered.length && photos[i].id != reordered[i].id) {
            final movedItem = reordered[i];

            final globalOld = widget.items.indexOf(movedItem);
            // Logic to find new global index based on local change
            int globalNew;
            if (i >= photos.length) {
              globalNew = widget.items.indexOf(photos.last);
            } else {
              globalNew = widget.items.indexOf(photos[i]);
            }

            widget.onReorder(globalOld, globalNew);
            break;
          }
        }
      },
      builder: (children) {
        // Append empty slots to the grid
        final allChildren = [...children];
        for (int i = 0; i < emptyCount; i++) {
          allChildren.add(
            _EmptySlot(
              key: ValueKey('empty_photo_$i'),
              type: MediaType.photo,
              onTap: widget.isUploading ? () {} : widget.onAddPhoto,
            ),
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.s8,
          crossAxisSpacing: AppSpacing.s8,
          children: allChildren,
        );
      },
      children: [
        for (var item in photos)
          _FilledSlot(
            key: ValueKey(item.id),
            item: item,
            onRemove: () => widget.onRemove(widget.items.indexOf(item)),
          ),
      ],
    );
  }

  Widget _buildVideosList() {
    final videos = _videos;
    final emptyCount = widget.maxVideos - videos.length;

    return ReorderableBuilder<MediaItem>(
      onReorder: (reorderFunc) {
        final reordered = reorderFunc(List<MediaItem>.from(videos));
        for (int i = 0; i < videos.length; i++) {
          if (i < reordered.length && videos[i].id != reordered[i].id) {
            final movedItem = reordered[i];

            final globalOld = widget.items.indexOf(movedItem);
            int globalNew;
            if (i >= videos.length) {
              globalNew = widget.items.indexOf(videos.last);
            } else {
              globalNew = widget.items.indexOf(videos[i]);
            }

            widget.onReorder(globalOld, globalNew);
            break;
          }
        }
      },
      builder: (children) {
        final allChildren = [...children];
        for (int i = 0; i < emptyCount; i++) {
          allChildren.add(
            _EmptySlot(
              key: ValueKey('empty_video_$i'),
              type: MediaType.video,
              onTap: widget.isUploading ? () {} : widget.onAddVideo,
            ),
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.s8,
          crossAxisSpacing: AppSpacing.s8,
          children: allChildren,
        );
      },
      children: [
        for (var item in videos)
          _VideoCard(
            key: ValueKey(item.id),
            item: item,
            onRemove: () => widget.onRemove(widget.items.indexOf(item)),
          ),
      ],
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onRemove;

  const _FilledSlot({super.key, required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: AppRadius.all12,
          child: CachedNetworkImage(
            imageUrl: item.url,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            memCacheWidth: 300,
            placeholder: (context, url) => AppShimmer.box(borderRadius: 12),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surface,
              child: const Icon(Icons.error, color: AppColors.error),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onRemove;

  const _VideoCard({super.key, required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: AppRadius.all12,
          child: item.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: item.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => AppShimmer.box(borderRadius: 12),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.videocam_off,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.videocam, color: AppColors.textSecondary),
                  ),
                ),
        ),
        // Play Icon Overlay
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        // Remove Button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final MediaType type;
  final VoidCallback onTap;

  const _EmptySlot({super.key, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.all12,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(8), // Always rounded square
              ),
              child: Icon(
                type == MediaType.video ? Icons.videocam : Icons.add_a_photo,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Adicionar',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
