import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/storage/domain/upload_validator.dart';

void main() {
  group('UploadLimits', () {
    test('maxPhotoSizeBytes is 10MB', () {
      expect(UploadLimits.maxPhotoSizeBytes, 10 * 1024 * 1024);
    });

    test('maxVideoSizeBytes is 50MB', () {
      expect(UploadLimits.maxVideoSizeBytes, 50 * 1024 * 1024);
    });

    test('allowedImageExtensions contains common image formats', () {
      expect(UploadLimits.allowedImageExtensions, contains('.jpg'));
      expect(UploadLimits.allowedImageExtensions, contains('.jpeg'));
      expect(UploadLimits.allowedImageExtensions, contains('.png'));
      expect(UploadLimits.allowedImageExtensions, contains('.webp'));
      expect(UploadLimits.allowedImageExtensions, contains('.gif'));
    });

    test('allowedVideoExtensions contains common video formats', () {
      expect(UploadLimits.allowedVideoExtensions, contains('.mp4'));
      expect(UploadLimits.allowedVideoExtensions, contains('.mov'));
      expect(UploadLimits.allowedVideoExtensions, contains('.webm'));
    });
  });

  group('UploadValidationException', () {
    test('message is accessible', () {
      const exception = UploadValidationException('Test message');
      expect(exception.message, 'Test message');
    });

    test('toString returns message', () {
      const exception = UploadValidationException('Test message');
      expect(exception.toString(), 'Test message');
    });
  });

  group('UploadValidator', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('upload_validator_test');
    });

    tearDownAll(() async {
      await tempDir.delete(recursive: true);
    });

    group('validateImage', () {
      test('throws when file does not exist', () async {
        final file = File('${tempDir.path}/nonexistent.jpg');

        expect(
          () => UploadValidator.validateImage(file),
          throwsA(isA<UploadValidationException>()),
        );
      });

      test('throws for invalid image extension', () async {
        final file = File('${tempDir.path}/test.exe');
        await file.writeAsBytes([0, 1, 2, 3]); // Create small file

        expect(
          () => UploadValidator.validateImage(file),
          throwsA(
            isA<UploadValidationException>().having(
              (e) => e.message,
              'message',
              contains('Formato de imagem não suportado'),
            ),
          ),
        );
      });

      test('accepts valid image extension', () async {
        final file = File('${tempDir.path}/test.jpg');
        await file.writeAsBytes([0, 1, 2, 3]); // Create small file

        // Should not throw
        await UploadValidator.validateImage(file);
      });

      test('accepts all allowed image extensions', () async {
        for (final ext in UploadLimits.allowedImageExtensions) {
          final file = File('${tempDir.path}/test$ext');
          await file.writeAsBytes([0, 1, 2, 3]);

          // Should not throw
          await UploadValidator.validateImage(file);
        }
      });
    });

    group('validateVideo', () {
      test('throws for invalid video extension', () async {
        final file = File('${tempDir.path}/video.jpg');
        await file.writeAsBytes([0, 1, 2, 3]);

        expect(
          () => UploadValidator.validateVideo(file),
          throwsA(
            isA<UploadValidationException>().having(
              (e) => e.message,
              'message',
              contains('Formato de vídeo não suportado'),
            ),
          ),
        );
      });

      test('accepts valid video extension', () async {
        final file = File('${tempDir.path}/test.mp4');
        await file.writeAsBytes([0, 1, 2, 3]);

        // Should not throw
        await UploadValidator.validateVideo(file);
      });
    });

    group('validateMedia', () {
      test('validates as image when isVideo is false', () async {
        final file = File('${tempDir.path}/media.jpg');
        await file.writeAsBytes([0, 1, 2, 3]);

        // Should not throw
        await UploadValidator.validateMedia(file, isVideo: false);
      });

      test('validates as video when isVideo is true', () async {
        final file = File('${tempDir.path}/media.mp4');
        await file.writeAsBytes([0, 1, 2, 3]);

        // Should not throw
        await UploadValidator.validateMedia(file, isVideo: true);
      });

      test('throws when validating image file as video', () async {
        final file = File('${tempDir.path}/wrong_type.jpg');
        await file.writeAsBytes([0, 1, 2, 3]);

        expect(
          () => UploadValidator.validateMedia(file, isVideo: true),
          throwsA(isA<UploadValidationException>()),
        );
      });
    });

    group('getReadableFileSize', () {
      test('returns bytes for small files', () async {
        final file = File('${tempDir.path}/tiny.dat');
        await file.writeAsBytes(List.filled(500, 0));

        final size = await UploadValidator.getReadableFileSize(file);
        expect(size, '500 B');
      });

      test('returns KB for kilobyte files', () async {
        final file = File('${tempDir.path}/small.dat');
        await file.writeAsBytes(List.filled(2048, 0)); // 2KB

        final size = await UploadValidator.getReadableFileSize(file);
        expect(size, '2.0 KB');
      });

      test('returns MB for megabyte files', () async {
        final file = File('${tempDir.path}/medium.dat');
        await file.writeAsBytes(List.filled(2 * 1024 * 1024, 0)); // 2MB

        final size = await UploadValidator.getReadableFileSize(file);
        expect(size, '2.0 MB');
      });
    });
  });
}
