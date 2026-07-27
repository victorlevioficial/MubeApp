import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Configuração otimizada para cache de imagens do AppMube.
///
/// Esta configuração define limites de cache em disco e memória,
/// além de políticas de expiração para otimizar performance.
class ImageCacheConfig {
  /// Número máximo de objetos em cache na memória
  static const int maxMemoryCacheCount = 200;
  static const int maxMemoryCacheSizeBytes = 120 * 1024 * 1024;

  /// Lower bound used when calculating decoded image dimensions.
  static const int minDecodeDimensionPx = 64;
  static const int feedPrecacheMaxDimension = 720;

  /// Tempo de expiração do cache em disco (7 dias)
  static const Duration cacheDuration = Duration(days: 7);

  /// Cache manager customizado para imagens
  static final CacheManager optimizedCacheManager = _MubeImageCacheManager(
    Config(
      'optimized_image_cache',
      stalePeriod: cacheDuration,
      maxNrOfCacheObjects: 500,
      fileService: HttpFileService(),
    ),
  );

  /// Cache manager para thumbnails (mais agressivo)
  static final CacheManager thumbnailCacheManager = _MubeImageCacheManager(
    Config(
      'thumbnail_cache',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 1000,
      fileService: HttpFileService(),
    ),
  );

  /// Cache manager para imagens de perfil (persistente)
  static final CacheManager profileCacheManager = _MubeImageCacheManager(
    Config(
      'profile_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
      fileService: HttpFileService(),
    ),
  );

  /// Limpa todo o cache de imagens
  static Future<void> clearAllCaches() async {
    await optimizedCacheManager.emptyCache();
    await thumbnailCacheManager.emptyCache();
    await profileCacheManager.emptyCache();
    await DefaultCacheManager().emptyCache();
  }

  /// Configura limites do cache de imagens em memoria do Flutter.
  /// Deve ser chamado no bootstrap do app.
  static void configureFlutterImageCache({
    int? maximumSize,
    int? maximumSizeBytes,
  }) {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = maximumSize ?? maxMemoryCacheCount;
    imageCache.maximumSizeBytes = maximumSizeBytes ?? maxMemoryCacheSizeBytes;
  }
}

/// Cache manager com suporte a resize em disco para `maxWidth/maxHeight`.
class _MubeImageCacheManager extends CacheManager with ImageCacheManager {
  _MubeImageCacheManager(super.config);
}
