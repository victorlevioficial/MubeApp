import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/services/image_cache_config.dart';
import '../../../../utils/app_logger.dart';

class GigImagePrecache {
  const GigImagePrecache._();

  static const int avatarCacheDimension = 192;

  static Future<void> precacheCreatorAvatars(
    BuildContext context,
    Iterable<String?> urls, {
    int maxItems = 6,
    Duration timeout = const Duration(milliseconds: 900),
  }) async {
    if (!context.mounted || maxItems <= 0) return;

    final uniqueUrls = <String>[];
    final seenUrls = <String>{};

    for (final rawUrl in urls) {
      final url = rawUrl?.trim();
      if (url == null || url.isEmpty || !seenUrls.add(url)) continue;
      uniqueUrls.add(url);
      if (uniqueUrls.length >= maxItems) break;
    }

    if (uniqueUrls.isEmpty) return;

    await Future.wait<void>(
      uniqueUrls.map((url) {
        return precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: ImageCacheConfig.profileCacheManager,
            maxWidth: avatarCacheDimension,
            maxHeight: avatarCacheDimension,
          ),
          context,
          onError: (error, stackTrace) => AppLogger.logHandledImageError(
            source: 'GigImagePrecache',
            url: url,
            error: error,
            stackTrace: stackTrace,
          ),
        ).catchError((_) {
          // Ignore individual avatar failures to keep the first paint stable.
        });
      }),
    ).timeout(timeout, onTimeout: () => const <void>[]);
  }
}
