import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/profile/domain/video_transcode_state.dart';

void main() {
  group('parseVideoTranscodeJobState', () {
    test('returns success when job finished with transcoded url', () {
      final state = parseVideoTranscodeJobState({
        'status': 'succeeded',
        'transcodedUrl': 'https://example.com/gallery_videos_transcoded/a.mp4',
      });

      expect(state.status, VideoTranscodeStatus.succeeded);
      expect(state.isReady, true);
      expect(
        state.transcodedUrl,
        'https://example.com/gallery_videos_transcoded/a.mp4',
      );
    });

    test('returns failed when job reports failed status', () {
      final state = parseVideoTranscodeJobState({
        'status': 'failed',
        'errorMessage': 'codec-error',
      });

      expect(state.status, VideoTranscodeStatus.failed);
      expect(state.isFailed, true);
      expect(state.errorMessage, 'codec-error');
    });

    test('returns pending for in-flight statuses', () {
      final state = parseVideoTranscodeJobState({'status': 'processing'});

      expect(state.status, VideoTranscodeStatus.pending);
      expect(state.isReady, false);
      expect(state.isFailed, false);
    });
  });

  group('isTranscodedVideoUrl', () {
    test('detects transcoded storage urls', () {
      expect(
        isTranscodedVideoUrl(
          'https://firebasestorage.googleapis.com/v0/b/x/o/gallery_videos_transcoded%2Fuser%2Fmedia%2Fmaster.mp4',
        ),
        true,
      );
    });

    test('rejects original gallery urls', () {
      expect(
        isTranscodedVideoUrl(
          'https://firebasestorage.googleapis.com/v0/b/x/o/gallery_videos%2Fuser%2Fmedia.mp4',
        ),
        false,
      );
    });
  });
}
