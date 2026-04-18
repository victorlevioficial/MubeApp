import 'package:flutter/material.dart';

import '../../../../design_system/components/loading/app_skeleton.dart';
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
    this.pendingProcessingCount = 0,
    required this.onCreateStory,
    required this.onOpenStoryBundle,
    required this.onOpenCurrentUserStoryOptions,
  });

  final AppUser currentUser;
  final List<StoryTrayBundle> storyBundles;
  final int pendingProcessingCount;
  final VoidCallback onCreateStory;
  final void Function(StoryTrayBundle bundle) onOpenStoryBundle;
  final void Function(StoryTrayBundle bundle) onOpenCurrentUserStoryOptions;

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
            subtitle: currentUserBundle != null
                ? 'Ver ou publicar'
                : pendingProcessingCount > 1
                ? '$pendingProcessingCount processando'
                : pendingProcessingCount == 1
                ? 'Processando'
                : 'Publicar',
            hasUnseen: currentUserBundle?.hasUnseen ?? false,
            hasStory: currentUserBundle != null,
            showAddBadge: true,
            photoUrl: currentUser.foto,
            photoPreviewUrl: currentUser.fotoThumb,
            name: currentUser.appDisplayName,
            onTap: currentUserBundle == null
                ? onCreateStory
                : () => onOpenCurrentUserStoryOptions(currentUserBundle),
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
    this.hasStory = false,
    this.showAddBadge = false,
    this.onLongPress,
  });

  final String title;
  final String subtitle;
  final String name;
  final String? photoUrl;
  final String? photoPreviewUrl;
  final bool hasUnseen;
  final bool hasStory;
  final bool showAddBadge;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s16),
      child: SizedBox(
        width: 92,
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
                  hasStory: hasStory,
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

class StoryTraySkeleton extends StatelessWidget {
  const StoryTraySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: SkeletonShimmer(
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s16),
              child: SizedBox(
                width: 82,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SkeletonCircle(size: 64),
                      const SizedBox(height: AppSpacing.s8),
                      SkeletonText(width: index == 0 ? 60 : 50, height: 12),
                      const SizedBox(height: AppSpacing.s4),
                      const SkeletonText(width: 40, height: 10),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
