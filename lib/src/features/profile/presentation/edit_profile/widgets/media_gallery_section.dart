import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../design_system/components/feedback/app_snackbar.dart';
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

  Future<void> _handleAddPhoto() async {
    final controller = ref.read(
      editProfileControllerProvider(widget.user.uid).notifier,
    );
    final state = ref.read(editProfileControllerProvider(widget.user.uid));

    // UI-side check
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

  Future<void> _handleAddVideo() async {
    final controller = ref.read(
      editProfileControllerProvider(widget.user.uid).notifier,
    );
    final state = ref.read(editProfileControllerProvider(widget.user.uid));

    if (state.videoCount >= 3) {
      if (mounted) AppSnackBar.warning(context, 'Limite de 3 vídeos atingido.');
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
      if (mounted) AppSnackBar.error(context, 'Erro ao adicionar vídeo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileControllerProvider(widget.user.uid));

    return GalleryGrid(
      items: state.galleryItems,
      maxPhotos: 6,
      maxVideos: 3,
      onAddPhoto: _handleAddPhoto,
      onAddVideo: _handleAddVideo,
      onRemove: (index) => ref
          .read(editProfileControllerProvider(widget.user.uid).notifier)
          .removeMedia(index, widget.user.uid),
      onReorder: (oldIndex, newIndex) {
        ref
            .read(editProfileControllerProvider(widget.user.uid).notifier)
            .reorderMedia(oldIndex, newIndex);
      },
      isUploading: state.isUploadingMedia,
      uploadProgress: state.uploadProgress,
      uploadStatus: state.uploadStatus,
    );
  }
}
