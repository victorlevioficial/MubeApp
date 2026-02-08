import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_config.dart';
import '../domain/feed_item.dart';
import 'feed_controller.dart'; // Using FeedController instead of FeedItemsProvider

/// Provider for the Feed Image Precache Service.
final feedImagePrecacheServiceProvider = Provider<FeedImagePrecacheService>((
  ref,
) {
  return FeedImagePrecacheService(ref);
});

/// Service responsible for pre-caching images in the feed to prevent pop-in
/// and improve scrolling smoothness.
class FeedImagePrecacheService {
  final Ref _ref;
  final Set<String> _cachedUrls = {};

  // Maximum number of images to keep tracking (simple LRU limit logic could be added)
  static const int _maxCacheTrack = 100;

  FeedImagePrecacheService(this._ref) {
    _listenToFeedItems();
  }

  void _listenToFeedItems() {
    // Correctly listening to FeedController which provides AsyncValue<FeedState>
    _ref.listen<AsyncValue<FeedState>>(feedControllerProvider, (
      previous,
      next,
    ) {
      next.whenData((state) {
        // Pre-cache main feed items
        if (state.items.isNotEmpty) {
          // Pre-cache the next batch
          final itemsToCache = state.items
              .skip(_cachedUrls.length)
              .take(10);
          for (final item in itemsToCache) {
            _precacheItemImages(item);
          }
        }
      });
    });
  }

  /// Manually trigger pre-caching for a list of items (e.g. from pagination)
  void precacheItems(BuildContext context, List<FeedItem> items) {
    for (final item in items) {
      final url = item.foto;
      if (url != null && url.isNotEmpty && !_cachedUrls.contains(url)) {
        precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: ImageCacheConfig.profileCacheManager,
          ),
          context,
        );
        _markAsCached(url);
      }
    }
  }

  void _precacheItemImages(FeedItem item) {
    final url = item.foto;
    if (url == null || url.isEmpty || _cachedUrls.contains(url)) return;

    // Actual precaching needs a context, which we don't have here seamlessly without a global key.
    // However, precacheItems() is the public API intended to be called from UI.
    // This internal method just tracks or prepares.

    // For now, we will rely on precacheItems being called from UI or
    // just track URLs to avoid redundant logic if we add more complex prefetching later.
  }

  void _markAsCached(String url) {
    if (_cachedUrls.length >= _maxCacheTrack) {
      _cachedUrls.remove(_cachedUrls.first);
    }
    _cachedUrls.add(url);
  }
}
