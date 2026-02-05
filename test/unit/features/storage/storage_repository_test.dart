import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/storage/data/storage_repository.dart';
import 'package:mube/src/features/storage/domain/image_compressor.dart';

void main() {
  group('ImageUrls', () {
    const urls = ImageUrls(
      thumbnail: 'https://example.com/thumb.jpg',
      medium: 'https://example.com/medium.jpg',
      large: 'https://example.com/large.jpg',
      full: 'https://example.com/full.jpg',
    );

    group('getUrlForSize', () {
      test('deve retornar thumbnail para ImageSize.thumbnail', () {
        expect(
          urls.getUrlForSize(ImageSize.thumbnail),
          'https://example.com/thumb.jpg',
        );
      });

      test('deve retornar medium para ImageSize.medium', () {
        expect(
          urls.getUrlForSize(ImageSize.medium),
          'https://example.com/medium.jpg',
        );
      });

      test('deve retornar large para ImageSize.large', () {
        expect(
          urls.getUrlForSize(ImageSize.large),
          'https://example.com/large.jpg',
        );
      });

      test('deve retornar full para ImageSize.full', () {
        expect(
          urls.getUrlForSize(ImageSize.full),
          'https://example.com/full.jpg',
        );
      });

      test('deve fazer fallback quando URL específica é nula', () {
        const partialUrls = ImageUrls(
          thumbnail: null,
          medium: null,
          large: 'https://example.com/large.jpg',
          full: null,
        );

        expect(
          partialUrls.getUrlForSize(ImageSize.thumbnail),
          'https://example.com/large.jpg',
        );
      });
    });

    group('firstAvailable', () {
      test('deve retornar primeira URL disponível', () {
        expect(urls.firstAvailable, 'https://example.com/thumb.jpg');
      });

      test('deve retornar null quando todas são nulas', () {
        const emptyUrls = ImageUrls();
        expect(emptyUrls.firstAvailable, null);
      });
    });

    group('JSON serialization', () {
      test('toJson deve converter corretamente', () {
        final json = urls.toJson();

        expect(json['thumbnail'], 'https://example.com/thumb.jpg');
        expect(json['medium'], 'https://example.com/medium.jpg');
        expect(json['large'], 'https://example.com/large.jpg');
        expect(json['full'], 'https://example.com/full.jpg');
      });

      test('fromJson deve converter corretamente', () {
        final json = {
          'thumbnail': 'https://example.com/thumb.jpg',
          'medium': 'https://example.com/medium.jpg',
          'large': 'https://example.com/large.jpg',
          'full': 'https://example.com/full.jpg',
        };

        final result = ImageUrls.fromJson(json);

        expect(result.thumbnail, 'https://example.com/thumb.jpg');
        expect(result.medium, 'https://example.com/medium.jpg');
        expect(result.large, 'https://example.com/large.jpg');
        expect(result.full, 'https://example.com/full.jpg');
      });
    });
  });

  group('GalleryMediaUrls', () {
    const imageUrls = GalleryMediaUrls(
      thumbnail: 'https://example.com/thumb.jpg',
      medium: 'https://example.com/medium.jpg',
      large: 'https://example.com/large.jpg',
      full: 'https://example.com/full.jpg',
      isVideo: false,
    );

    const videoUrls = GalleryMediaUrls(
      full: 'https://example.com/video.mp4',
      isVideo: true,
    );

    group('getUrlForSize', () {
      test('deve retornar URL correta para imagens', () {
        expect(
          imageUrls.getUrlForSize(ImageSize.thumbnail),
          'https://example.com/thumb.jpg',
        );
      });

      test('deve retornar sempre full para vídeos', () {
        expect(
          videoUrls.getUrlForSize(ImageSize.thumbnail),
          'https://example.com/video.mp4',
        );
        expect(
          videoUrls.getUrlForSize(ImageSize.full),
          'https://example.com/video.mp4',
        );
      });
    });

    group('firstAvailable', () {
      test('deve retornar primeira URL disponível', () {
        expect(imageUrls.firstAvailable, 'https://example.com/thumb.jpg');
      });
    });

    group('JSON serialization', () {
      test('toJson deve converter corretamente', () {
        final json = imageUrls.toJson();

        expect(json['thumbnail'], 'https://example.com/thumb.jpg');
        expect(json['isVideo'], false);
      });

      test('fromJson deve converter corretamente', () {
        final json = {
          'thumbnail': 'https://example.com/thumb.jpg',
          'medium': 'https://example.com/medium.jpg',
          'large': 'https://example.com/large.jpg',
          'full': 'https://example.com/full.jpg',
          'isVideo': true,
        };

        final result = GalleryMediaUrls.fromJson(json);

        expect(result.isVideo, true);
        expect(result.thumbnail, 'https://example.com/thumb.jpg');
      });

      test('fromJson deve tratar isVideo nulo como false', () {
        final json = {
          'thumbnail': 'https://example.com/thumb.jpg',
          'full': 'https://example.com/full.jpg',
        };

        final result = GalleryMediaUrls.fromJson(json);

        expect(result.isVideo, false);
      });
    });
  });
}
