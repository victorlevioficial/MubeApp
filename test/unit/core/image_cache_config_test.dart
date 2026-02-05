import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/image_cache_config.dart';

void main() {
  group('ImageCacheConfig', () {
    test('deve ter constantes definidas corretamente', () {
      expect(ImageCacheConfig.maxMemoryCacheCount, 200);
      expect(ImageCacheConfig.maxDiskCacheSize, 100 * 1024 * 1024);
      expect(ImageCacheConfig.maxFileSize, 10 * 1024 * 1024);
      expect(ImageCacheConfig.cacheDuration, const Duration(days: 7));
    });
  });

  group('ImageCacheType', () {
    test('deve ter todos os valores', () {
      expect(ImageCacheType.values.length, 4);
      expect(ImageCacheType.values, contains(ImageCacheType.thumbnail));
      expect(ImageCacheType.values, contains(ImageCacheType.profile));
      expect(ImageCacheType.values, contains(ImageCacheType.general));
      expect(ImageCacheType.values, contains(ImageCacheType.default_));
    });
  });
}
