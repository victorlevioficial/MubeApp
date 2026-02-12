import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_config.dart';
import '../domain/feed_item.dart';

/// Provider for the Feed Image Precache Service.
final feedImagePrecacheServiceProvider = Provider<FeedImagePrecacheService>((
  ref,
) {
  return FeedImagePrecacheService();
});

/// Service responsible for pre-caching images in the feed to prevent pop-in
/// and improve scrolling smoothness.
class FeedImagePrecacheService {
  final Set<String> _seenUrls = {};
  final Set<String> _inFlightUrls = {};

  static const int _maxTrackedUrls = 200;
  static const int _maxFailureLogs = 5;
  int _failureLogCount = 0;

  /// Trigger pre-caching for a list of items.
  ///
  /// [maxItems] limits the amount of work per call to avoid startup jank.
  void precacheItems(
    BuildContext context,
    List<FeedItem> items, {
    int maxItems = 10,
  }) {
    if (items.isEmpty || maxItems <= 0) return;

    final urlsToPrecache = <String>[];
    for (final item in items) {
      final url = item.foto;
      if (url == null || url.isEmpty) continue;
      if (_seenUrls.contains(url) || _inFlightUrls.contains(url)) continue;

      urlsToPrecache.add(url);
      if (urlsToPrecache.length >= maxItems) break;
    }

    for (final url in urlsToPrecache) {
      _precacheUrl(context, url);
    }
  }

  void _precacheUrl(BuildContext context, String url) {
    _inFlightUrls.add(url);
    _markAsSeen(url);

    precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: ImageCacheConfig.profileCacheManager,
          ),
          context,
          onError: (error, stackTrace) => _logPrecacheFailure(url),
        )
        .catchError((_) {
          // Errors are handled in onError to avoid noisy uncaught exceptions.
        })
        .whenComplete(() {
          _inFlightUrls.remove(url);
        });
  }

  void _logPrecacheFailure(String url) {
    if (!kDebugMode) return;
    if (_failureLogCount >= _maxFailureLogs) return;
    _failureLogCount++;
    debugPrint('FeedImagePrecacheService: failed to precache $url');
  }

  void _markAsSeen(String url) {
    if (_seenUrls.length >= _maxTrackedUrls) {
      _seenUrls.remove(_seenUrls.first);
    }
    _seenUrls.add(url);
  }
}
