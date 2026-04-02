import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../utils/app_logger.dart';
import '../../data/story_repository.dart';
import '../../domain/story_item.dart';
import '../../domain/story_repository_exception.dart';
import '../../domain/story_upload_media.dart';
import '../services/story_media_picker_service.dart';
import 'story_tray_controller.dart';

final storyComposeControllerProvider =
    NotifierProvider.autoDispose<StoryComposeController, StoryComposeState>(
      StoryComposeController.new,
    );

class StoryComposeController extends Notifier<StoryComposeState> {
  late final StoryMediaPickerService _mediaPickerService;

  @override
  StoryComposeState build() {
    _mediaPickerService = StoryMediaPickerService();
    ref.onDispose(_mediaPickerService.dispose);
    return const StoryComposeState();
  }

  Future<void> pickImage(BuildContext context) async {
    final selection = await _mediaPickerService.pickImage(context);
    if (selection == null) return;
    state = state.copyWith(
      selectedMedia: selection,
      clearError: true,
      didPublish: false,
      isPhotoMirrored: false,
      publishProgress: 0,
      clearPublishStatus: true,
    );
  }

  Future<void> pickVideo(BuildContext context) async {
    final selection = await _mediaPickerService.pickVideo(context);
    if (selection == null) return;
    state = state.copyWith(
      selectedMedia: selection,
      clearError: true,
      didPublish: false,
      isPhotoMirrored: false,
      publishProgress: 0,
      clearPublishStatus: true,
    );
  }

  void updateCaption(String value) {
    state = state.copyWith(caption: value);
  }

  void togglePhotoMirror() {
    final selectedMedia = state.selectedMedia;
    if (selectedMedia == null ||
        selectedMedia.mediaType != StoryMediaType.image) {
      return;
    }

    state = state.copyWith(
      isPhotoMirrored: !state.isPhotoMirrored,
      clearError: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedMedia: null,
      caption: '',
      clearError: true,
      isPublishing: false,
      didPublish: false,
      isPhotoMirrored: false,
      publishProgress: 0,
      clearPublishStatus: true,
    );
  }

  Future<bool> publish(BuildContext context) async {
    final selectedMedia = state.selectedMedia;
    if (selectedMedia == null) {
      state = state.copyWith(errorMessage: 'Selecione uma midia primeiro.');
      return false;
    }

    state = state.copyWith(
      isPublishing: true,
      clearError: true,
      didPublish: false,
      publishProgress: 0.08,
      publishStatus: 'Preparando upload',
    );

    try {
      var mediaToPublish = selectedMedia;
      if (selectedMedia.mediaType == StoryMediaType.image &&
          state.isPhotoMirrored) {
        state = state.copyWith(
          publishProgress: 0.12,
          publishStatus: 'Preparando foto',
        );
        final mirroredFile = await _mediaPickerService.mirrorImageHorizontally(
          selectedMedia.file,
        );
        mediaToPublish = selectedMedia.copyWith(file: mirroredFile);
        state = state.copyWith(
          publishProgress: 0.18,
          publishStatus: 'Foto pronta para envio',
        );
      }

      await ref
          .read(storyRepositoryProvider)
          .publishStory(
            media: mediaToPublish,
            caption: state.caption,
            onProgress: (progress) {
              state = state.copyWith(
                isPublishing: true,
                publishProgress: progress.value,
                publishStatus: progress.label,
                clearError: true,
              );
            },
          );
      ref.invalidate(storyTrayControllerProvider);
      state = state.copyWith(
        isPublishing: false,
        didPublish: true,
        clearError: true,
        publishProgress: 1,
        publishStatus: 'Story publicado',
      );
      if (context.mounted) {
        AppSnackBar.success(
          context,
          selectedMedia.mediaType.name == 'video'
              ? 'Story enviado. O video pode levar alguns instantes para aparecer.'
              : 'Story publicado com sucesso.',
        );
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('Falha ao publicar story', error, stackTrace);
      state = state.copyWith(
        isPublishing: false,
        errorMessage: _resolveErrorMessage(error),
        publishProgress: 0,
        clearPublishStatus: true,
      );
      if (context.mounted) {
        AppSnackBar.error(
          context,
          state.errorMessage ?? 'Nao foi possivel publicar o story.',
        );
      }
      return false;
    }
  }

  String _resolveErrorMessage(Object error) {
    if (error is StoryRepositoryException) {
      return error.message;
    }
    final message = error.toString().trim();
    if (message.startsWith('Exception:')) {
      return message.replaceFirst('Exception:', '').trim();
    }
    return message.isEmpty ? 'Nao foi possivel publicar o story.' : message;
  }
}

class StoryComposeState {
  static const Object _selectedMediaSentinel = Object();

  const StoryComposeState({
    this.selectedMedia,
    this.caption = '',
    this.errorMessage,
    this.isPublishing = false,
    this.didPublish = false,
    this.isPhotoMirrored = false,
    this.publishProgress = 0,
    this.publishStatus,
  });

  final StoryUploadMedia? selectedMedia;
  final String caption;
  final String? errorMessage;
  final bool isPublishing;
  final bool didPublish;
  final bool isPhotoMirrored;
  final double publishProgress;
  final String? publishStatus;

  StoryComposeState copyWith({
    Object? selectedMedia = _selectedMediaSentinel,
    String? caption,
    String? errorMessage,
    bool? isPublishing,
    bool? didPublish,
    bool? isPhotoMirrored,
    double? publishProgress,
    String? publishStatus,
    bool clearError = false,
    bool clearPublishStatus = false,
  }) {
    return StoryComposeState(
      selectedMedia: identical(selectedMedia, _selectedMediaSentinel)
          ? this.selectedMedia
          : selectedMedia as StoryUploadMedia?,
      caption: caption ?? this.caption,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isPublishing: isPublishing ?? this.isPublishing,
      didPublish: didPublish ?? this.didPublish,
      isPhotoMirrored: isPhotoMirrored ?? this.isPhotoMirrored,
      publishProgress: publishProgress ?? this.publishProgress,
      publishStatus: clearPublishStatus
          ? null
          : publishStatus ?? this.publishStatus,
    );
  }
}
