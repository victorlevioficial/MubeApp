import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/services/image_cache_config.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';

/// Enum para definir o tamanho da imagem a ser carregada
enum ImageResolution {
  /// Thumbnail pequeno (150px) - para avatares em listas
  thumbnail(150),

  /// Médio (400px) - para cards e previews
  medium(400),

  /// Grande (800px) - para perfil e visualização
  large(800),

  /// Original/Full - para visualização completa
  full(null);

  final int? maxDimension;
  const ImageResolution(this.maxDimension);
}

/// Widget de imagem otimizado com cache, shimmer e placeholder.
///
/// Features:
/// - Carregamento com shimmer animado
/// - Cache automático (memória e disco)
/// - Suporte a múltiplas resoluções
/// - Lazy loading com placeholder
/// - Imagem de erro quando falha
/// - Fade-in animation suave
/// - Suporte a bordas arredondadas
/// - Otimização de memória com limites de cache
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final Map<String, String>? headers;

  /// Resolução máxima para otimização de cache
  final ImageResolution resolution;

  /// Se deve usar placeholder de skeleton durante o loading
  final bool useSkeletonPlaceholder;

  /// Cor de fundo do placeholder
  final Color? placeholderColor;

  /// Cache manager customizado (opcional)
  final CacheManager? cacheManager;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.headers,
    this.resolution = ImageResolution.medium,
    this.useSkeletonPlaceholder = true,
    this.placeholderColor,
    this.cacheManager,
  });

  /// Factory para avatar circular pequeno (lista)
  factory OptimizedImage.avatarSmall({
    Key? key,
    required String? imageUrl,
    double size = 40,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedImage(
      key: key,
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      resolution: ImageResolution.thumbnail,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: placeholder ?? _buildAvatarPlaceholder(size),
      errorWidget: errorWidget ?? _buildAvatarError(size),
    );
  }

  /// Factory para avatar circular médio (perfil)
  factory OptimizedImage.avatarMedium({
    Key? key,
    required String? imageUrl,
    double size = 80,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedImage(
      key: key,
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      resolution: ImageResolution.large,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: placeholder ?? _buildAvatarPlaceholder(size),
      errorWidget: errorWidget ?? _buildAvatarError(size),
    );
  }

  /// Factory para avatar circular grande (header)
  factory OptimizedImage.avatarLarge({
    Key? key,
    required String? imageUrl,
    double size = 120,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedImage(
      key: key,
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      resolution: ImageResolution.large,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: placeholder ?? _buildAvatarPlaceholder(size),
      errorWidget: errorWidget ?? _buildAvatarError(size),
    );
  }

  /// Factory para card retangular (galeria)
  factory OptimizedImage.card({
    Key? key,
    required String? imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    ImageResolution resolution = ImageResolution.medium,
  }) {
    return OptimizedImage(
      key: key,
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      resolution: resolution,
      borderRadius: borderRadius ?? AppRadius.all12,
    );
  }

  /// Factory para imagem em tamanho completo
  factory OptimizedImage.fullscreen({
    Key? key,
    required String? imageUrl,
    BoxFit fit = BoxFit.contain,
  }) {
    return OptimizedImage(
      key: key,
      imageUrl: imageUrl,
      fit: fit,
      resolution: ImageResolution.full,
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }

  static Widget _buildAvatarPlaceholder(double size) {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight.withValues(alpha: 0.5),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.surfaceHighlight,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  static Widget _buildAvatarError(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.textTertiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    // Calcula dimensões de cache baseadas na resolução e tamanho do widget
    final cacheWidth = _calculateCacheWidth(context);
    final cacheHeight = _calculateCacheHeight(context);
    final effectiveCacheManager = cacheManager ?? _resolveCacheManager();
    final maxWidthDiskCache = resolution == ImageResolution.full
        ? null
        : cacheWidth;
    final maxHeightDiskCache = resolution == ImageResolution.full
        ? null
        : cacheHeight;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 100),
      httpHeaders: headers,
      cacheManager: effectiveCacheManager,
      placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      // Limita cache em memória para otimizar performance
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      // Limita cache em disco
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  /// Calcula a largura do cache baseada na resolução e tamanho do widget
  int? _calculateCacheWidth(BuildContext context) {
    return _calculateCacheDimension(
      context: context,
      logicalSize: width,
      maxResolution: resolution.maxDimension,
    );
  }

  /// Calcula a altura do cache baseada na resolução e tamanho do widget
  int? _calculateCacheHeight(BuildContext context) {
    return _calculateCacheDimension(
      context: context,
      logicalSize: height,
      maxResolution: resolution.maxDimension,
    );
  }

  int? _calculateCacheDimension({
    required BuildContext context,
    required double? logicalSize,
    required int? maxResolution,
  }) {
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final scaledSize = logicalSize != null
        ? (logicalSize * pixelRatio).round()
        : null;

    if (resolution == ImageResolution.full) {
      if (scaledSize == null || scaledSize <= 0) return null;
      return scaledSize;
    }

    if (scaledSize != null && scaledSize > 0 && maxResolution != null) {
      return scaledSize
          .clamp(ImageCacheConfig.minDecodeDimensionPx, maxResolution)
          .toInt();
    }

    if (scaledSize != null && scaledSize > 0) {
      return scaledSize;
    }

    return maxResolution;
  }

  CacheManager _resolveCacheManager() {
    switch (resolution) {
      case ImageResolution.thumbnail:
        return ImageCacheConfig.thumbnailCacheManager;
      case ImageResolution.medium:
      case ImageResolution.large:
      case ImageResolution.full:
        return ImageCacheConfig.optimizedCacheManager;
    }
  }

  Widget _buildShimmerPlaceholder() {
    if (!useSkeletonPlaceholder) {
      return Container(
        width: width,
        height: height,
        color: placeholderColor ?? AppColors.surfaceHighlight,
      );
    }

    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight.withValues(alpha: 0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: placeholderColor ?? AppColors.surfaceHighlight,
          borderRadius: borderRadius ?? AppRadius.all8,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: borderRadius ?? AppRadius.all8,
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: AppColors.textTertiary,
          size: (width ?? 48) * 0.3,
        ),
      ),
    );
  }
}

/// Extensão para gerenciar cache de imagens
extension OptimizedImageCache on OptimizedImage {
  /// Limpa o cache de uma URL específica
  static Future<void> clearCache(String imageUrl) async {
    await CachedNetworkImage.evictFromCache(imageUrl);
  }

  /// Limpa todo o cache de imagens
  static Future<void> clearAllCache() async {
    await ImageCacheConfig.clearAllCaches();
  }

  /// Pré-carrega uma lista de URLs para cache
  static Future<void> preloadImages(
    BuildContext context,
    List<String> urls, {
    ImageResolution resolution = ImageResolution.medium,
  }) async {
    final filteredUrls = urls.where((url) => url.isNotEmpty).toList();
    if (filteredUrls.isEmpty) return;

    final maxDimension =
        resolution.maxDimension ?? ImageCacheConfig.feedPrecacheMaxDimension;
    final cacheManager = resolution == ImageResolution.thumbnail
        ? ImageCacheConfig.thumbnailCacheManager
        : ImageCacheConfig.optimizedCacheManager;
    const batchSize = 3;

    for (var i = 0; i < filteredUrls.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, filteredUrls.length);
      final batch = filteredUrls.sublist(i, end);

      await Future.wait(
        batch.map((url) async {
          try {
            await precacheImage(
              CachedNetworkImageProvider(
                url,
                cacheManager: cacheManager,
                maxWidth: maxDimension,
                maxHeight: maxDimension,
              ),
              context,
            );
          } catch (_) {
            // Ignore individual image failures to keep preload pipeline flowing.
          }
        }),
      );

      if (end < filteredUrls.length) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }
  }
}

/// Widget para exibir imagens em lista com lazy loading otimizado
class OptimizedImageList extends StatelessWidget {
  final List<String> imageUrls;
  final ScrollController? scrollController;
  final EdgeInsets padding;
  final double spacing;
  final int crossAxisCount;
  final double childAspectRatio;
  final ImageResolution resolution;
  final Widget Function(BuildContext, String, int)? itemBuilder;

  const OptimizedImageList({
    super.key,
    required this.imageUrls,
    this.scrollController,
    this.padding = AppSpacing.all16,
    this.spacing = AppSpacing.s8,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1,
    this.resolution = ImageResolution.thumbnail,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final url = imageUrls[index];

        if (itemBuilder != null) {
          return itemBuilder!(context, url, index);
        }

        return OptimizedImage.card(imageUrl: url, resolution: resolution);
      },
    );
  }
}

/// Hero wrapper para transições suaves entre imagens
class OptimizedImageHero extends StatelessWidget {
  final String tag;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final ImageResolution resolution;

  const OptimizedImageHero({
    super.key,
    required this.tag,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.resolution = ImageResolution.large,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: OptimizedImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        resolution: resolution,
      ),
    );
  }
}
