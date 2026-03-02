import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

import '../../../../../design_system/components/loading/app_shimmer.dart';
import '../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../domain/media_item.dart';

class GalleryGrid extends StatefulWidget {
  final List<MediaItem> items;
  final int maxPhotos;
  final int maxVideos;
  final bool isPickingPhoto;
  final bool isPickingVideo;
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
    this.isPickingPhoto = false,
    this.isPickingVideo = false,
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
  List<MediaItem> get _photos =>
      widget.items.where((item) => item.type == MediaType.photo).toList();
  List<MediaItem> get _videos =>
      widget.items.where((item) => item.type == MediaType.video).toList();
  int? _activePhotoSlotIndex;
  int? _activeVideoSlotIndex;

  @override
  void didUpdateWidget(covariant GalleryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isPickingPhoto) {
      _activePhotoSlotIndex = null;
    }
    if (!widget.isPickingVideo) {
      _activeVideoSlotIndex = null;
    }
  }

  void _handlePhotoSlotTap(int slotIndex) {
    if (widget.isUploading || widget.isPickingPhoto || widget.isPickingVideo) {
      return;
    }

    setState(() {
      _activePhotoSlotIndex = slotIndex;
    });
    widget.onAddPhoto();
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || widget.isPickingPhoto) return;
      setState(() {
        _activePhotoSlotIndex = null;
      });
    });
  }

  void _handleVideoSlotTap(int slotIndex) {
    if (widget.isUploading || widget.isPickingPhoto || widget.isPickingVideo) {
      return;
    }

    setState(() {
      _activeVideoSlotIndex = slotIndex;
    });
    widget.onAddVideo();
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || widget.isPickingVideo) return;
      setState(() {
        _activeVideoSlotIndex = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    final videos = _videos;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isUploading) ...[
            _GalleryUploadBanner(
              progress: widget.uploadProgress,
              status: widget.uploadStatus,
            ),
            const SizedBox(height: AppSpacing.s20),
          ],
          Text('Galeria de Fotos', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Adicione até ${widget.maxPhotos} fotos do seu trabalho',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _buildPhotosGrid(photos),
          const SizedBox(height: AppSpacing.s32),
          Text('Videos', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Adicione até ${widget.maxVideos} videos',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _buildVideosGrid(videos),
          const SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(List<MediaItem> photos) {
    final emptyCount = widget.maxPhotos - photos.length;

    return ReorderableBuilder<MediaItem>(
      onReorder: (reorderFunc) {
        if (widget.isUploading) return;
        final reordered = reorderFunc(List<MediaItem>.from(photos));
        for (var i = 0; i < photos.length; i++) {
          if (i < reordered.length && photos[i].id != reordered[i].id) {
            final movedItem = reordered[i];
            final globalOld = widget.items.indexOf(movedItem);
            final globalNew = i >= photos.length
                ? widget.items.indexOf(photos.last)
                : widget.items.indexOf(photos[i]);
            widget.onReorder(globalOld, globalNew);
            break;
          }
        }
      },
      builder: (children) {
        final allChildren = [...children];
        for (var i = 0; i < emptyCount; i++) {
          allChildren.add(
            _EmptySlot(
              key: ValueKey('empty_photo_$i'),
              type: MediaType.photo,
              isLoading:
                  widget.isPickingPhoto && _activePhotoSlotIndex == i,
              onTap: () => _handlePhotoSlotTap(i),
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
        for (final item in photos)
          _FilledSlot(
            key: ValueKey(item.id),
            item: item,
            onRemove: widget.isUploading
                ? () {}
                : () => widget.onRemove(widget.items.indexOf(item)),
          ),
      ],
    );
  }

  Widget _buildVideosGrid(List<MediaItem> videos) {
    final emptyCount = widget.maxVideos - videos.length;

    return ReorderableBuilder<MediaItem>(
      onReorder: (reorderFunc) {
        if (widget.isUploading) return;
        final reordered = reorderFunc(List<MediaItem>.from(videos));
        for (var i = 0; i < videos.length; i++) {
          if (i < reordered.length && videos[i].id != reordered[i].id) {
            final movedItem = reordered[i];
            final globalOld = widget.items.indexOf(movedItem);
            final globalNew = i >= videos.length
                ? widget.items.indexOf(videos.last)
                : widget.items.indexOf(videos[i]);
            widget.onReorder(globalOld, globalNew);
            break;
          }
        }
      },
      builder: (children) {
        final allChildren = [...children];
        for (var i = 0; i < emptyCount; i++) {
          allChildren.add(
            _EmptySlot(
              key: ValueKey('empty_video_$i'),
              type: MediaType.video,
              isLoading:
                  widget.isPickingVideo && _activeVideoSlotIndex == i,
              onTap: () => _handleVideoSlotTap(i),
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
        for (final item in videos)
          _VideoCard(
            key: ValueKey(item.id),
            item: item,
            onRemove: widget.isUploading
                ? () {}
                : () => widget.onRemove(widget.items.indexOf(item)),
          ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final MediaType type;
  final bool isLoading;
  final VoidCallback onTap;

  const _EmptySlot({
    super.key,
    required this.type,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLoading,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all12,
            border: Border.all(
              color: isLoading ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLoading
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        type == MediaType.video
                            ? Icons.videocam
                            : Icons.add_a_photo,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                isLoading ? 'Carregando...' : 'Adicionar',
                style: AppTypography.labelSmall.copyWith(
                  color: isLoading
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryUploadBanner extends StatelessWidget {
  final double progress;
  final String status;

  const _GalleryUploadBanner({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final showDeterminate = normalized > 0.0 && normalized < 1.0;
    final percent = '${(normalized * 100).round()}%';
    final isDeleting = status.toLowerCase().contains('removendo');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.isNotEmpty ? status : 'Enviando midia...',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          LinearProgressIndicator(
            value: isDeleting ? null : (showDeterminate ? normalized : null),
            minHeight: 5,
            borderRadius: AppRadius.pill,
            backgroundColor: AppColors.surfaceHighlight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            isDeleting ? 'Processando...' : (showDeterminate ? percent : 'Processando...'),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onRemove;

  const _FilledSlot({super.key, required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isProcessing = item.isProcessing;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: AppRadius.all12, child: _buildImageContent()),
        if (isProcessing)
          ClipRRect(
            borderRadius: AppRadius.all12,
            child: Container(
              color: AppColors.background.withValues(alpha: 0.5),
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: item.isUploading && item.uploadProgress > 0
                        ? item.uploadProgress
                        : null,
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        if (!isProcessing)
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

  Widget _buildImageContent() {
    if (item.hasLocalPreview) {
      return Image.file(
        File(item.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surface,
          child: const Icon(Icons.error, color: AppColors.error),
        ),
      );
    }

    return CachedNetworkImage(
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
    );
  }
}

class _VideoCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onRemove;

  const _VideoCard({super.key, required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isProcessing = item.isProcessing;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: AppRadius.all12,
          child: _buildThumbnailContent(),
        ),
        if (isProcessing)
          ClipRRect(
            borderRadius: AppRadius.all12,
            child: Container(
              color: AppColors.background.withValues(alpha: 0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: item.isUploading && item.uploadProgress > 0
                          ? item.uploadProgress
                          : null,
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
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
        if (!isProcessing)
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

  Widget _buildThumbnailContent() {
    if (item.localThumbnailPath != null &&
        item.localThumbnailPath!.isNotEmpty) {
      return Image.file(
        File(item.localThumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surface,
          child: const Icon(Icons.videocam_off, color: AppColors.textSecondary),
        ),
      );
    }

    if (item.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: item.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => AppShimmer.box(borderRadius: 12),
        errorWidget: (context, url, error) => Container(
          color: AppColors.surface,
          child: const Icon(Icons.videocam_off, color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.videocam, color: AppColors.textSecondary),
      ),
    );
  }
}
