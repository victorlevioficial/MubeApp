import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../../design_system/foundations/tokens/app_spacing.dart';
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
  bool _isPickingPhoto = false;
  bool _isPickingVideo = false;

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
    final remainingSlots = 6 - state.photoCount;

    if (state.isUploadingMedia || _isPickingPhoto || _isPickingVideo) return;

    if (state.photoCount >= 6) {
      if (mounted) {
        AppSnackBar.warning(context, 'Limite de 6 fotos atingido.');
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isPickingPhoto = true;
        });
      }

      final source = await MediaPickerService.showMediaSourcePicker(
        context,
        title: 'Adicionar Foto',
        cameraIcon: Icons.camera_alt_outlined,
        cameraLabel: 'Tirar Foto',
        galleryIcon: Icons.photo_library_outlined,
        galleryLabel: 'Escolher da Galeria',
      );

      if (source == null || !mounted) return;

      final selectedFiles = await _mediaPickerService.pickPhotos(
        source: source,
      );
      if (selectedFiles == null || selectedFiles.isEmpty || !mounted) return;

      final filesToUpload = selectedFiles.take(remainingSlots).toList();

      if (selectedFiles.length > remainingSlots && mounted) {
        AppSnackBar.warning(
          context,
          'Voce pode adicionar ate $remainingSlots foto(s) agora. As demais foram ignoradas.',
        );
      }

      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }

      await controller.addPhotosBatch(
        files: filesToUpload,
        userId: widget.user.uid,
      );
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Erro ao adicionar foto: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  Future<void> _handleVideoUpload() async {
    final controller = ref.read(
      editProfileControllerProvider(widget.user.uid).notifier,
    );
    final state = ref.read(editProfileControllerProvider(widget.user.uid));

    if (state.isUploadingMedia || _isPickingPhoto || _isPickingVideo) return;

    if (state.videoCount >= 3) {
      if (mounted) {
        AppSnackBar.warning(context, 'Limite de 3 videos atingido.');
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isPickingVideo = true;
        });
      }

      final result = await _mediaPickerService.pickAndProcessVideo(context);
      if (result == null || !mounted) return;

      final (videoFile, thumbnailFile) = result;
      if (mounted) {
        setState(() {
          _isPickingVideo = false;
        });
      }
      await controller.addVideo(
        videoFile: videoFile,
        thumbnailFile: thumbnailFile,
        userId: widget.user.uid,
      );
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Erro ao adicionar video: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingVideo = false;
        });
      }
    }
  }

  Future<void> _handleMediaRemove(int index) async {
    try {
      await ref
          .read(editProfileControllerProvider(widget.user.uid).notifier)
          .removeMedia(index, widget.user.uid);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao remover midia: $e');
      }
    }
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
      child: GalleryGrid(
        items: state.galleryItems,
        maxPhotos: 6,
        maxVideos: 3,
        isPickingPhoto: _isPickingPhoto,
        isPickingVideo: _isPickingVideo,
        onRemove: _handleMediaRemove,
        onAddPhoto: _handlePhotoUpload,
        onAddVideo: _handleVideoUpload,
        onReorder: _handleReorder,
        isUploading: state.isUploadingMedia,
        uploadProgress: state.uploadProgress,
        uploadStatus: state.uploadStatus,
      ),
    );
  }
}
