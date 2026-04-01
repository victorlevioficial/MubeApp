import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/story_tray_bundle.dart';
import 'story_ring_avatar.dart';

class StoryTray extends StatelessWidget {
  const StoryTray({
    super.key,
    required this.currentUser,
    required this.storyBundles,
    required this.onCreateStory,
    required this.onOpenStoryBundle,
  });

  final AppUser currentUser;
  final List<StoryTrayBundle> storyBundles;
  final VoidCallback onCreateStory;
  final void Function(StoryTrayBundle bundle) onOpenStoryBundle;

  @override
  Widget build(BuildContext context) {
    final currentUserBundle = storyBundles.cast<StoryTrayBundle?>().firstWhere(
      (bundle) => bundle?.isCurrentUser == true,
      orElse: () => null,
    );
    final others = storyBundles
        .where((bundle) => !bundle.isCurrentUser)
        .toList(growable: false);

    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
        children: [
          _StoryTrayItem(
            title: 'Seu story',
            subtitle: currentUserBundle == null ? 'Publicar' : 'Ver story',
            hasUnseen: currentUserBundle?.hasUnseen ?? false,
            showAddBadge: true,
            photoUrl: currentUser.foto,
            photoPreviewUrl: currentUser.fotoThumb,
            name: currentUser.appDisplayName,
            onTap: currentUserBundle == null
                ? onCreateStory
                : () => onOpenStoryBundle(currentUserBundle),
            onLongPress: onCreateStory,
          ),
          ...others.map(
            (bundle) => _StoryTrayItem(
              title: bundle.ownerName,
              subtitle: bundle.isFavorite ? 'Favorito' : 'Stories',
              hasUnseen: bundle.hasUnseen,
              photoUrl: bundle.ownerPhoto,
              photoPreviewUrl: bundle.ownerPhotoPreview,
              name: bundle.ownerName,
              onTap: () => onOpenStoryBundle(bundle),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryTrayItem extends StatelessWidget {
  const _StoryTrayItem({
    required this.title,
    required this.subtitle,
    required this.name,
    required this.onTap,
    this.photoUrl,
    this.photoPreviewUrl,
    this.hasUnseen = false,
    this.showAddBadge = false,
    this.onLongPress,
  });

  final String title;
  final String subtitle;
  final String name;
  final String? photoUrl;
  final String? photoPreviewUrl;
  final bool hasUnseen;
  final bool showAddBadge;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s16),
      child: SizedBox(
        width: 82,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadius.all16,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StoryRingAvatar(
                  name: name,
                  photoUrl: photoUrl,
                  photoPreviewUrl: photoPreviewUrl,
                  size: 64,
                  hasUnseen: hasUnseen,
                  showAddBadge: showAddBadge,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
