import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../auth/domain/app_user.dart';
import '../../services/media_picker_service.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/edit_profile_state.dart';
import 'gallery_grid.dart';

class MediaGallerySection extends ConsumerStatefulWidget {
  final AppUser user;

  const MediaGallerySection({super.key, required this.user});

  @override
  ConsumerState<MediaGallerySection> createState() =>
      _MediaGallerySectionState();
}

class _MediaGallerySectionState extends ConsumerState<MediaGallerySection> {
  final _mediaPickerService = MediaPickerService();

  @override
  void dispose() {
    _mediaPickerService.dispose();
    super.dispose();
  }

  Future<void> _handlePhotoUpload() async {
    final controller = ref.read(
      editProfileControllerProvider(widget.user.uid).notifier,
    );
    final state = ref.read(editProfileControllerProvider(widget.user.uid));

    if (state.isUploadingMedia) return;

    if (state.photoCount >= 6) {
      if (mounted) {
        AppSnackBar.warning(context, 'Limite de 6 fotos atingido.');
      }
      return;
    }

    try {
      final file = await _mediaPickerService.pickAndCropPhoto(
        context,
        lockAspectRatio: false,
      );
      if (file == null || !mounted) return;

      await controller.addPhoto(file: file, userId: widget.user.uid);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Erro ao adicionar foto: $e');
    }
  }

  Future<void> _handleVideoUpload() async {
    final controller = ref.read(
      editProfileControllerProvider(widget.user.uid).notifier,
    );
    final state = ref.read(editProfileControllerProvider(widget.user.uid));

    if (state.isUploadingMedia) return;

    if (state.videoCount >= 3) {
      if (mounted) {
        AppSnackBar.warning(context, 'Limite de 3 videos atingido.');
      }
      return;
    }

    try {
      final result = await _mediaPickerService.pickAndProcessVideo(context);
      if (result == null || !mounted) return;

      final (videoFile, thumbnailFile) = result;
      await controller.addVideo(
        videoFile: videoFile,
        thumbnailFile: thumbnailFile,
        userId: widget.user.uid,
      );
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Erro ao adicionar video: $e');
    }
  }

  Future<void> _handleMediaRemove(int index) async {
    await ref
        .read(editProfileControllerProvider(widget.user.uid).notifier)
        .removeMedia(index, widget.user.uid);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    ref
        .read(editProfileControllerProvider(widget.user.uid).notifier)
        .reorderMedia(oldIndex, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileControllerProvider(widget.user.uid));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Midia e Portfolio',
            style: AppTypography.headlineLarge.copyWith(fontSize: 28),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Adicione fotos, videos e trabalhos da sua carreira',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s32),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  'Adicionar Midia',
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Selecione arquivos para atualizar seu portfolio',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        text: 'Foto',
                        onPressed: state.isUploadingMedia
                            ? null
                            : _handlePhotoUpload,
                        isLoading:
                            state.isUploadingMedia &&
                            state.uploadStatus.toLowerCase().contains('foto'),
                        icon: const Icon(Icons.photo_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: AppButton.outline(
                        text: 'Video',
                        onPressed: state.isUploadingMedia
                            ? null
                            : _handleVideoUpload,
                        isLoading:
                            state.isUploadingMedia &&
                            state.uploadStatus.toLowerCase().contains('video'),
                        icon: const Icon(
                          Icons.video_library_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (state.isUploadingMedia) ...[
            const SizedBox(height: AppSpacing.s16),
            _UploadProgressCard(
              progress: state.uploadProgress,
              status: state.uploadStatus,
            ),
          ],
          const SizedBox(height: AppSpacing.s48),
          if (state.galleryItems.isNotEmpty) ...[
            Text('Galeria', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.s16),
            GalleryGrid(
              items: state.galleryItems,
              maxPhotos: 6,
              maxVideos: 3,
              onRemove: _handleMediaRemove,
              onAddPhoto: _handlePhotoUpload,
              onAddVideo: _handleVideoUpload,
              onReorder: _handleReorder,
              isUploading: state.isUploadingMedia,
              uploadProgress: state.uploadProgress,
              uploadStatus: state.uploadStatus,
            ),
            const SizedBox(height: AppSpacing.s48),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s48,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.all16,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Nenhuma midia adicionada',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Comece adicionando suas fotos e videos',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadProgressCard extends StatelessWidget {
  final double progress;
  final String status;

  const _UploadProgressCard({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final showDeterminate = normalized > 0.0 && normalized < 1.0;
    final progressLabel = '${(normalized * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.isNotEmpty ? status : 'Enviando midia...',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          LinearProgressIndicator(
            value: showDeterminate ? normalized : null,
            minHeight: 6,
            borderRadius: AppRadius.pill,
            backgroundColor: AppColors.surfaceHighlight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            showDeterminate ? progressLabel : 'Processando arquivo...',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
