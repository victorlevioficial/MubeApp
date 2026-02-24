import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
  final Queue<String> _pendingUrls = Queue<String>();

  static const int _maxTrackedUrls = 200;
  static const int _maxFailureLogs = 5;
  static const int _maxConcurrentPrecaches = 2;
  int _failureLogCount = 0;
  int _activePrecaches = 0;

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
      if (_seenUrls.contains(url) ||
          _inFlightUrls.contains(url) ||
          _pendingUrls.contains(url)) {
        continue;
      }

      urlsToPrecache.add(url);
      if (urlsToPrecache.length >= maxItems) break;
    }

    for (final url in urlsToPrecache) {
      _markAsSeen(url);
      _pendingUrls.addLast(url);
    }

    _drainQueue(context);
  }

  /// Pre-cache blocking path for critical first-paint images.
  /// Used to keep skeleton visible until the first batch is warmed.
  Future<void> precacheCriticalItems(
    BuildContext context,
    List<FeedItem> items, {
    int maxItems = 6,
    Duration timeout = const Duration(milliseconds: 1800),
  }) async {
    if (!context.mounted || items.isEmpty || maxItems <= 0) return;

    final urls = <String>[];
    final seenInBatch = <String>{};

    for (final item in items) {
      final url = item.foto;
      if (url == null || url.isEmpty) continue;
      if (!seenInBatch.add(url)) continue;
      urls.add(url);
      if (urls.length >= maxItems) break;
    }

    if (urls.isEmpty) return;

    await precacheCriticalUrls(
      context,
      urls,
      cacheManager: ImageCacheConfig.profileCacheManager,
      maxWidth: ImageCacheConfig.feedPrecacheMaxDimension,
      maxHeight: ImageCacheConfig.feedPrecacheMaxDimension,
      timeout: timeout,
    );
  }

  Future<void> precacheCriticalUrls(
    BuildContext context,
    List<String> urls, {
    required CacheManager cacheManager,
    int? maxWidth,
    int? maxHeight,
    Duration timeout = const Duration(milliseconds: 1800),
  }) async {
    if (!context.mounted || urls.isEmpty) return;

    final uniqueUrls = <String>[];
    final seenInBatch = <String>{};
    for (final url in urls) {
      if (url.isEmpty) continue;
      if (!seenInBatch.add(url)) continue;
      uniqueUrls.add(url);
    }
    if (uniqueUrls.isEmpty) return;

    final futures = <Future<void>>[];
    for (final url in uniqueUrls) {
      _markAsSeen(url);
      _inFlightUrls.add(url);
      futures.add(
        precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: cacheManager,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          context,
          onError: (error, stackTrace) => _logPrecacheFailure(url, error),
        ).catchError((_) {}).whenComplete(() {
          _inFlightUrls.remove(url);
        }),
      );
    }

    await Future.wait<void>(
      futures,
    ).timeout(timeout, onTimeout: () => const <void>[]);
  }

  void _drainQueue(BuildContext context) {
    if (!context.mounted) return;
    while (_activePrecaches < _maxConcurrentPrecaches &&
        _pendingUrls.isNotEmpty) {
      final nextUrl = _pendingUrls.removeFirst();
      _activePrecaches++;
      _precacheUrl(context, nextUrl).whenComplete(() {
        if (_activePrecaches > 0) _activePrecaches--;
        if (!context.mounted) return;
        _drainQueue(context);
      });
    }
  }

  Future<void> _precacheUrl(BuildContext context, String url) async {
    _inFlightUrls.add(url);

    await precacheImage(
      CachedNetworkImageProvider(
        url,
        cacheManager: ImageCacheConfig.profileCacheManager,
        maxWidth: ImageCacheConfig.feedPrecacheMaxDimension,
        maxHeight: ImageCacheConfig.feedPrecacheMaxDimension,
      ),
      context,
      onError: (error, stackTrace) => _logPrecacheFailure(url, error),
    ).catchError((_) {
      // Errors are handled in onError to avoid noisy uncaught exceptions.
    });
    _inFlightUrls.remove(url);
  }

  void _logPrecacheFailure(String url, Object? error) {
    if (!kDebugMode) return;
    if (_failureLogCount >= _maxFailureLogs) return;
    _failureLogCount++;
    debugPrint(
      'FeedImagePrecacheService: failed to precache $url | error: $error',
    );
  }

  void _markAsSeen(String url) {
    if (_seenUrls.length >= _maxTrackedUrls) {
      _seenUrls.remove(_seenUrls.first);
    }
    _seenUrls.add(url);
  }
}
