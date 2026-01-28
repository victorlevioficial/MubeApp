import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';

import '../../../../common_widgets/app_shimmer.dart';

import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../domain/media_item.dart';

/// Reorderable gallery grid with drag-and-drop support.
class GalleryGrid extends StatelessWidget {
  final List<MediaItem> items;
  final int maxSlots;
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
    this.maxSlots = 9,
    this.maxVideos = 2,
    required this.onAddPhoto,
    required this.onAddVideo,
    required this.onRemove,
    required this.onReorder,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadStatus = '',
  });

  int get _videoCount => items.where((i) => i.type == MediaType.video).length;
  bool get _canAddVideo => _videoCount < maxVideos;
  bool get _canAddMore => items.length < maxSlots && !isUploading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MÍDIA', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Adicione até $maxSlots fotos/vídeos. Máximo $maxVideos vídeos.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),

        // Grid
        ReorderableBuilder<MediaItem>(
          onReorder: (reorderFunc) {
            final reordered = reorderFunc(List<MediaItem>.from(items));
            // Find the change
            for (int i = 0; i < items.length; i++) {
              if (i < reordered.length && items[i].id != reordered[i].id) {
                final oldIndex = items.indexWhere(
                  (e) => e.id == reordered[i].id,
                );
                onReorder(oldIndex, i);
                break;
              }
            }
          },
          builder: (children) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.s8,
              crossAxisSpacing: AppSpacing.s8,
              children: children,
            );
          },
          children: [
            // Filled slots
            ...items.map(
              (item) => _FilledSlot(
                key: ValueKey(item.id),
                item: item,
                isFirst: items.indexOf(item) == 0,
                onRemove: () => onRemove(items.indexOf(item)),
              ),
            ),
            // Upload progress slot
            if (isUploading)
              _UploadingSlot(
                key: const ValueKey('uploading_slot'),
                progress: uploadProgress,
                status: uploadStatus,
              ),
            // Empty slots
            if (_canAddMore)
              _EmptySlot(
                key: const ValueKey('add_slot'),
                canAddVideo: _canAddVideo,
                onAddPhoto: onAddPhoto,
                onAddVideo: onAddVideo,
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.s16),
        Text(
          'Segure e arraste para reordenar.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// A slot with media content.
class _FilledSlot extends StatelessWidget {
  final MediaItem item;
  final bool isFirst;
  final VoidCallback onRemove;

  const _FilledSlot({
    super.key,
    required this.item,
    required this.isFirst,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.type == MediaType.video
        ? item.thumbnailUrl ?? item.url
        : item.url;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => AppShimmer.box(borderRadius: 12),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surface,
              child: const Icon(Icons.error, color: AppColors.error),
            ),
          ),
        ),

        // Video indicator
        if (item.type == MediaType.video)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: AppColors.textPrimary,
                    size: 14,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Vídeo',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Remove button
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

/// An empty slot for adding media.
class _EmptySlot extends StatelessWidget {
  final bool canAddVideo;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddVideo;

  const _EmptySlot({
    super.key,
    required this.canAddVideo,
    required this.onAddPhoto,
    required this.onAddVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        color: AppColors.surface,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAddOptions(context),
          child: const Center(
            child: Icon(Icons.add, color: AppColors.textSecondary, size: 32),
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Adicionar Mídia',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s24),
              ListTile(
                leading: const Icon(Icons.photo, color: AppColors.primary),
                title: const Text('Foto'),
                subtitle: const Text('Será cortada em formato quadrado'),
                onTap: () {
                  Navigator.pop(context);
                  onAddPhoto();
                },
              ),
              if (canAddVideo)
                ListTile(
                  leading: const Icon(Icons.videocam, color: AppColors.primary),
                  title: const Text('Vídeo'),
                  subtitle: const Text('Máximo 30 segundos'),
                  onTap: () {
                    Navigator.pop(context);
                    onAddVideo();
                  },
                )
              else
                const ListTile(
                  leading: Icon(Icons.videocam, color: AppColors.textSecondary),
                  title: Text(
                    'Vídeo',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  subtitle: Text(
                    'Limite de vídeos atingido',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A slot showing upload progress.
class _UploadingSlot extends StatelessWidget {
  final double progress;
  final String status;

  const _UploadingSlot({
    super.key,
    required this.progress,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.s8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: AppColors.surfaceHighlight,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          // Percentage text
          Text(
            progress > 0 ? '${(progress * 100).toInt()}%' : status,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: progress > 0 ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
