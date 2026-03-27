import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/profile/domain/media_item.dart';

void main() {
  group('MediaItem', () {
    test('prefers smaller photo variants for preview and large for viewer', () {
      const item = MediaItem(
        id: 'photo-1',
        url: 'https://cdn.example.com/full.webp',
        type: MediaType.photo,
        thumbnailUrl: 'https://cdn.example.com/thumb.webp',
        mediumUrl: 'https://cdn.example.com/medium.webp',
        largeUrl: 'https://cdn.example.com/large.webp',
        order: 0,
      );

      expect(item.previewUrl, 'https://cdn.example.com/thumb.webp');
      expect(item.viewerUrl, 'https://cdn.example.com/large.webp');
    });

    test('keeps video preview tied to thumbnail and viewer tied to source', () {
      const item = MediaItem(
        id: 'video-1',
        url: 'https://cdn.example.com/video.mp4',
        type: MediaType.video,
        thumbnailUrl: 'https://cdn.example.com/video-thumb.webp',
        order: 0,
      );

      expect(item.previewUrl, 'https://cdn.example.com/video-thumb.webp');
      expect(item.viewerUrl, 'https://cdn.example.com/video.mp4');
    });
  });
}
