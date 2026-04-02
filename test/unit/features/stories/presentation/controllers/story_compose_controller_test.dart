import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/stories/domain/story_item.dart';
import 'package:mube/src/features/stories/domain/story_upload_media.dart';
import 'package:mube/src/features/stories/presentation/controllers/story_compose_controller.dart';

class _TestStoryComposeController extends StoryComposeController {
  _TestStoryComposeController(this._initialState);

  final StoryComposeState _initialState;

  @override
  StoryComposeState build() => _initialState;
}

void main() {
  test(
    'clearSelection removes selected media and resets transient compose state',
    () {
      final selectedMedia = StoryUploadMedia(
        file: File('C:/tmp/story.jpg'),
        mediaType: StoryMediaType.image,
        aspectRatio: 9 / 16,
        fromCamera: false,
      );
      final container = ProviderContainer(
        overrides: [
          storyComposeControllerProvider.overrideWith(
            () => _TestStoryComposeController(
              StoryComposeState(
                selectedMedia: selectedMedia,
                caption: 'Legenda temporaria',
                errorMessage: 'Erro antigo',
                isPublishing: true,
                didPublish: true,
                isPhotoMirrored: true,
                publishProgress: 0.58,
                publishStatus: 'Enviando',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(storyComposeControllerProvider.notifier).clearSelection();
      final state = container.read(storyComposeControllerProvider);

      expect(state.selectedMedia, isNull);
      expect(state.caption, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.isPublishing, isFalse);
      expect(state.didPublish, isFalse);
      expect(state.isPhotoMirrored, isFalse);
      expect(state.publishProgress, 0);
      expect(state.publishStatus, isNull);
    },
  );
}
