import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/image_cache_config.dart';

void main() {
  group('ImageCacheConfig', () {
    test('deve expor apenas limites aplicados pelo cache de imagens', () {
      expect(ImageCacheConfig.maxMemoryCacheCount, 200);
      expect(ImageCacheConfig.maxMemoryCacheSizeBytes, 120 * 1024 * 1024);
      expect(ImageCacheConfig.minDecodeDimensionPx, 64);
      expect(ImageCacheConfig.feedPrecacheMaxDimension, 720);
      expect(ImageCacheConfig.cacheDuration, const Duration(days: 7));
    });
  });
}
