import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/media_item.dart';
import 'public_gallery_grid.dart';

/// Gallery section that shows photos and videos one after another.
///
/// Keeps the same tap contract: callback receives the selected index
/// and the filtered section list (photos or videos).
class ProfileGalleryTabs extends StatelessWidget {
  final List<MediaItem> items;
  final Color accentColor;
  final void Function(int index, List<MediaItem> filteredItems) onItemTap;

  const ProfileGalleryTabs({
    super.key,
    required this.items,
    required this.accentColor,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final photos = items.where((i) => i.type == MediaType.photo).toList();
    final videos = items.where((i) => i.type == MediaType.video).toList();
    final totalItems = photos.length + videos.length;
    if (totalItems == 0) return const SizedBox.shrink();
    final showDivider = photos.isNotEmpty && videos.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.perm_media_rounded,
                  size: 15,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text('Fotos e vídeos', style: AppTypography.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s2,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '$totalItems',
                  style: AppTypography.labelSmall.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Portfólio visual do perfil',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          if (photos.isNotEmpty)
            _GallerySection(
              title: 'Fotos',
              count: photos.length,
              icon: Icons.photo_outlined,
              accentColor: accentColor,
              items: photos,
              onItemTap: onItemTap,
            ),
          if (showDivider) ...[
            const SizedBox(height: AppSpacing.s12),
            Container(
              height: 1,
              color: AppColors.surfaceHighlight,
              margin: const EdgeInsets.only(bottom: AppSpacing.s12),
            ),
          ],
          if (videos.isNotEmpty)
            _GallerySection(
              title: 'V\u00EDdeos',
              count: videos.length,
              icon: Icons.videocam_outlined,
              accentColor: accentColor,
              items: videos,
              onItemTap: onItemTap,
            ),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color accentColor;
  final List<MediaItem> items;
  final void Function(int index, List<MediaItem> filteredItems) onItemTap;

  const _GallerySection({
    required this.title,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.s4),
            Text(title, style: AppTypography.titleSmall),
            const SizedBox(width: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s2,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                '$count',
                style: AppTypography.labelSmall.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        PublicGalleryGrid(
          items: items,
          onItemTap: (index) => onItemTap(index, items),
        ),
      ],
    );
  }
}

