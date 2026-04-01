import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../utils/app_logger.dart';
import '../../data/story_repository.dart';
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
    state = state.copyWith(selectedMedia: selection, clearError: true);
  }

  Future<void> pickVideo(BuildContext context) async {
    final selection = await _mediaPickerService.pickVideo(context);
    if (selection == null) return;
    state = state.copyWith(selectedMedia: selection, clearError: true);
  }

  void updateCaption(String value) {
    state = state.copyWith(caption: value);
  }

  void clearSelection() {
    state = state.copyWith(
      selectedMedia: null,
      caption: '',
      clearError: true,
      isPublishing: false,
      didPublish: false,
    );
  }

  Future<bool> publish(BuildContext context) async {
    final selectedMedia = state.selectedMedia;
    if (selectedMedia == null) {
      state = state.copyWith(errorMessage: 'Selecione uma midia primeiro.');
      return false;
    }

    state = state.copyWith(isPublishing: true, clearError: true, didPublish: false);

    try {
      await ref
          .read(storyRepositoryProvider)
          .publishStory(media: selectedMedia, caption: state.caption);
      ref.invalidate(storyTrayControllerProvider);
      state = state.copyWith(
        isPublishing: false,
        didPublish: true,
        clearError: true,
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
      );
      if (context.mounted) {
        AppSnackBar.error(context, state.errorMessage ?? 'Nao foi possivel publicar o story.');
      }
      return false;
    }
  }

  String _resolveErrorMessage(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception:')) {
      return message.replaceFirst('Exception:', '').trim();
    }
    return message.isEmpty ? 'Nao foi possivel publicar o story.' : message;
  }
}

class StoryComposeState {
  const StoryComposeState({
    this.selectedMedia,
    this.caption = '',
    this.errorMessage,
    this.isPublishing = false,
    this.didPublish = false,
  });

  final StoryUploadMedia? selectedMedia;
  final String caption;
  final String? errorMessage;
  final bool isPublishing;
  final bool didPublish;

  StoryComposeState copyWith({
    StoryUploadMedia? selectedMedia,
    String? caption,
    String? errorMessage,
    bool? isPublishing,
    bool? didPublish,
    bool clearError = false,
  }) {
    return StoryComposeState(
      selectedMedia: selectedMedia ?? this.selectedMedia,
      caption: caption ?? this.caption,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isPublishing: isPublishing ?? this.isPublishing,
      didPublish: didPublish ?? this.didPublish,
    );
  }
}
