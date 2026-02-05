import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/storage/domain/image_compressor.dart';

void main() {
  group('ImageCompressor', () {
    group('ImageSize enum', () {
      test('deve ter valores corretos', () {
        expect(ImageSize.thumbnail.maxWidth, 150);
        expect(ImageSize.thumbnail.quality, 70);
        expect(ImageSize.thumbnail.suffix, 'thumb');

        expect(ImageSize.medium.maxWidth, 400);
        expect(ImageSize.medium.quality, 80);
        expect(ImageSize.medium.suffix, 'medium');

        expect(ImageSize.large.maxWidth, 800);
        expect(ImageSize.large.quality, 85);
        expect(ImageSize.large.suffix, 'large');

        expect(ImageSize.full.maxWidth, 1920);
        expect(ImageSize.full.quality, 90);
        expect(ImageSize.full.suffix, 'full');
      });
    });

    group('ImageFormat enum', () {
      test('deve ter todos os formatos', () {
        expect(ImageFormat.values.length, 3);
        expect(ImageFormat.values, contains(ImageFormat.jpeg));
        expect(ImageFormat.values, contains(ImageFormat.webp));
        expect(ImageFormat.values, contains(ImageFormat.png));
      });
    });

    group('Constantes', () {
      test('deve ter constantes definidas corretamente', () {
        expect(ImageCompressor.profileMaxWidth, 800);
        expect(ImageCompressor.galleryMaxWidth, 1920);
        expect(ImageCompressor.thumbnailMaxWidth, 600);
        expect(ImageCompressor.profileQuality, 85);
        expect(ImageCompressor.galleryQuality, 80);
        expect(ImageCompressor.thumbnailQuality, 75);
        expect(ImageCompressor.webpQuality, 80);
      });
    });

    group('getEstimatedSize', () {
      test('deve retornar string de estimativa', () async {
        // Criar arquivo temporário vazio para teste
        final tempFile = File('${Directory.systemTemp.path}/test_image.jpg');
        await tempFile.writeAsBytes(List<int>.filled(1000, 0));

        final result = await ImageCompressor.getEstimatedSize(tempFile);

        expect(result, isA<String>());
        expect(result.isNotEmpty, true);

        await tempFile.delete();
      });

      test('deve retornar mensagem de erro quando arquivo não existe', () async {
        final nonExistentFile = File('/caminho/inexistente/test.jpg');

        final result = await ImageCompressor.getEstimatedSize(nonExistentFile);

        expect(result, 'Não foi possível estimar');
      });
    });
  });
}
