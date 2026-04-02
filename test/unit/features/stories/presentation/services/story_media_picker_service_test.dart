import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/stories/domain/story_constants.dart';
import 'package:mube/src/features/stories/presentation/services/story_media_picker_service.dart';

void main() {
  group('StoryMediaPickerService', () {
    test('normalizes larger mp4 videos before story upload', () {
      expect(
        StoryMediaPickerService.requiresVideoNormalization(
          videoPath: 'C:/tmp/story.mp4',
          fileSizeBytes: 20 * 1024 * 1024,
        ),
        isTrue,
      );
      expect(
        StoryMediaPickerService.requiresVideoNormalization(
          videoPath: 'C:/tmp/story.mp4',
          fileSizeBytes: 8 * 1024 * 1024,
        ),
        isFalse,
      );
    });

    test('accepts photo aspect ratios close to 9:16', () {
      expect(
        StoryMediaPickerService.isSupportedStoryImageAspectRatio(
          StoryConstants.targetAspectRatio,
        ),
        isTrue,
      );
      expect(
        StoryMediaPickerService.isSupportedStoryImageAspectRatio(1080 / 1920),
        isTrue,
      );
    });

    test('rejects photo aspect ratios outside the locked story ratio', () {
      expect(
        StoryMediaPickerService.isSupportedStoryImageAspectRatio(3 / 4),
        isFalse,
      );
      expect(
        StoryMediaPickerService.isSupportedStoryImageAspectRatio(1),
        isFalse,
      );
    });

    test('still accepts vertical video ratios within the configured limit', () {
      expect(
        StoryMediaPickerService.isSupportedStoryVideoAspectRatio(9 / 16),
        isTrue,
      );
      expect(
        StoryMediaPickerService.isSupportedStoryVideoAspectRatio(3 / 4),
        isTrue,
      );
      expect(
        StoryMediaPickerService.isSupportedStoryVideoAspectRatio(16 / 9),
        isFalse,
      );
    });
  });
}
