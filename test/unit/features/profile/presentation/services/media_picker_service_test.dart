import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/profile/presentation/services/media_picker_service.dart';
import 'package:mube/src/features/storage/domain/upload_validator.dart';

void main() {
  group('MediaPickerService.requiresLocalVideoTranscode', () {
    test('returns false for mp4 video within upload limit', () {
      final result = MediaPickerService.requiresLocalVideoTranscode(
        videoPath: '/tmp/video.mp4',
        fileSizeBytes: UploadLimits.maxVideoSizeBytes,
      );

      expect(result, isFalse);
    });

    test('returns true for oversized mp4 video', () {
      final result = MediaPickerService.requiresLocalVideoTranscode(
        videoPath: '/tmp/video.mp4',
        fileSizeBytes: UploadLimits.maxVideoSizeBytes + 1,
      );

      expect(result, isTrue);
    });

    test('returns true for non-mp4 video even within upload limit', () {
      final result = MediaPickerService.requiresLocalVideoTranscode(
        videoPath: '/tmp/video.mov',
        fileSizeBytes: UploadLimits.maxVideoSizeBytes - 1024,
      );

      expect(result, isTrue);
    });
  });
}
