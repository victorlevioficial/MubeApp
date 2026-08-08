import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/storage/data/storage_repository.dart';
import 'package:mube/src/features/storage/domain/image_compressor.dart';

import '../../../helpers/firebase_mocks.dart';

class _RecordingFirebaseStorage extends Mock implements FirebaseStorage {
  final Map<String, FirebaseException> failures;
  final List<String> deletionAttempts = [];

  _RecordingFirebaseStorage({this.failures = const {}});

  @override
  Reference ref([String? path]) =>
      _RecordingReference(storage: this, path: path ?? '');
}

class _RecordingReference extends Mock implements Reference {
  @override
  final _RecordingFirebaseStorage storage;
  final String path;

  _RecordingReference({required this.storage, required this.path});

  @override
  String get fullPath => path;

  @override
  Reference child(String childPath) => _RecordingReference(
    storage: storage,
    path: path.isEmpty ? childPath : '$path/$childPath',
  );

  @override
  Future<void> delete() async {
    storage.deletionAttempts.add(path);
    final failure = storage.failures[path];
    if (failure != null) throw failure;
  }
}

void main() {
  group('StorageRepository deletion', () {
    test(
      'continues video cleanup when the original file is already absent',
      () async {
        final storage = _RecordingFirebaseStorage(
          failures: {
            'gallery_videos/user-1/media-1.mp4': FirebaseException(
              plugin: 'firebase_storage',
              code: 'object-not-found',
            ),
          },
        );
        final repository = StorageRepository(storage, auth: MockFirebaseAuth());

        await repository.deleteGalleryItem(
          userId: 'user-1',
          mediaId: 'media-1',
          isVideo: true,
        );

        expect(storage.deletionAttempts, [
          'gallery_videos/user-1/media-1.mp4',
          'gallery_videos_transcoded/user-1/media-1/master.mp4',
          'gallery_thumbnails/user-1/media-1.webp',
        ]);
      },
    );

    test(
      'propagates permission failures after attempting every video file',
      () async {
        final storage = _RecordingFirebaseStorage(
          failures: {
            'gallery_videos/user-1/media-1.mp4': FirebaseException(
              plugin: 'firebase_storage',
              code: 'unauthorized',
            ),
          },
        );
        final repository = StorageRepository(storage, auth: MockFirebaseAuth());

        await expectLater(
          repository.deleteGalleryItem(
            userId: 'user-1',
            mediaId: 'media-1',
            isVideo: true,
          ),
          throwsA(
            isA<FirebaseException>().having(
              (error) => error.code,
              'code',
              'unauthorized',
            ),
          ),
        );
        expect(storage.deletionAttempts, hasLength(3));
      },
    );

    test('removes every current and legacy profile photo path', () async {
      final storage = _RecordingFirebaseStorage();
      final repository = StorageRepository(storage, auth: MockFirebaseAuth());

      await repository.deleteProfileImages('user-1');

      expect(storage.deletionAttempts, [
        'profile_photos/user-1/thumbnail.webp',
        'profile_photos/user-1/large.webp',
        'profile_photos/user-1',
        'profile_photos/user-1.webp',
        'profile_photos/user-1.jpg',
        'profile_photos/user-1.jpeg',
        'profile_photos/user-1.png',
      ]);
    });
  });

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
