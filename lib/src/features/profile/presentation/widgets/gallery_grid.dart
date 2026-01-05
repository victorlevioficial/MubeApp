import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  const GalleryGrid({
    super.key,
    required this.items,
    this.maxSlots = 9,
    this.maxVideos = 2,
    required this.onAddPhoto,
    required this.onAddVideo,
    required this.onRemove,
    required this.onReorder,
  });

  int get _videoCount => items.where((i) => i.type == MediaType.video).length;
  bool get _canAddVideo => _videoCount < maxVideos;
  bool get _canAddMore => items.length < maxSlots;

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
          'Segure e arraste para reordenar. A primeira mídia é a foto principal.',
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
            placeholder: (_, __) => Container(
              color: AppColors.surface,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
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
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 14),
                  SizedBox(width: 2),
                  Text(
                    'Vídeo',
                    style: TextStyle(color: Colors.white, fontSize: 10),
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
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
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
          color: AppColors.textSecondary.withOpacity(0.5),
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
                ListTile(
                  leading: Icon(Icons.videocam, color: Colors.grey.shade600),
                  title: Text(
                    'Vídeo',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  subtitle: Text(
                    'Limite de vídeos atingido',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
