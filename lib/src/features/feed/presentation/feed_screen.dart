import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/utils/app_logger.dart';

import '../../../core/mixins/pagination_mixin.dart';
import '../../../core/services/image_cache_config.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_refresh_indicator.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_performance_tracker.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import 'feed_controller.dart';
import 'feed_image_precache_service.dart';
import 'widgets/featured_spotlight_carousel.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_section_widget.dart';
import 'widgets/feed_skeleton.dart';
import 'widgets/quick_filter_bar.dart';
import 'widgets/vertical_feed_list.dart';

part 'feed_screen_ui.dart';

/// Constants for the Feed screen layout and behavior
abstract final class FeedConstants {
  static const double filterBarHeight = 52.0;
  static const double paginationThreshold = 200.0;
  static const double bottomPadding = 80.0;
  static const int criticalPrecacheItems = 6;
  static const int initialPrecacheItems = 4;
  static const int incrementalPrecacheItems = 6;
  static const int deferredPrecacheItems = 10;
  static const Duration criticalPrecacheTimeout = Duration(milliseconds: 1200);
  static const Duration deferredPrecacheDelay = Duration(milliseconds: 1400);
  static const double initialCacheExtent = 400.0;
}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  Timer? _deferredPrecacheTimer;
  ProviderSubscription<AsyncValue<FeedState>>? _feedSubscription;
  bool _isScrolled = false;
  int _precacheFingerprint = 0;
  int _lastKnownMainItemCount = 0;
  int _lastWarmupAnchor = -1;
  int _criticalWarmupFingerprint = 0;
  int _criticalWarmupGeneration = 0;
  bool _criticalImagesReady = false;
  bool _hasRenderedFeedContent = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _setupPrecacheListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedControllerProvider.notifier).loadAllData();
    });
  }

  @override
  void dispose() {
    _feedSubscription?.close();
    _deferredPrecacheTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final currentScroll = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Update header animation state
      final shouldScroll = currentScroll > 50;
      if (shouldScroll != _isScrolled) {
        setState(() => _isScrolled = shouldScroll);
      }

      // Pagination
      if (currentScroll >= maxScroll - FeedConstants.paginationThreshold) {
        final controller = ref.read(feedControllerProvider.notifier);
        if (controller.canLoadMore) {
          controller.loadMoreMainFeed();
        }
      }

      _warmUpcomingMainFeedWindow();
    }
  }

  String _getSectionTitle(FeedSectionType type) {
    try {
      return FeedSection.homeSections.firstWhere((s) => s.type == type).title;
    } catch (e) {
      AppLogger.debug('Seção não encontrada, usando fallback: ${type.name}');
      return type.name.toUpperCase();
    }
  }

  void _navigateToUser(FeedItem item) {
    context.push(RoutePaths.publicProfileById(item.uid), extra: item);
  }

  void _navigateToSectionList(FeedSectionType type) {
    context.push(RoutePaths.feedList, extra: {'type': type});
  }

  List<FeedItem> _getSpotlightItems(FeedState state) {
    if (state.featuredItems.isNotEmpty) {
      return state.featuredItems;
    }

    final allItems = <FeedItem>[];
    for (final items in state.sectionItems.values) {
      allItems.addAll(items);
    }
    if (allItems.isEmpty) {
      allItems.addAll(state.items);
    }
    final uniqueItems = <String, FeedItem>{};
    for (final item in allItems) {
      uniqueItems[item.uid] = item;
    }
    final sortedItems = uniqueItems.values.toList();
    sortedItems.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return sortedItems.take(5).toList();
  }

  void _setupPrecacheListener() {
    _feedSubscription = ref.listenManual<AsyncValue<FeedState>>(
      feedControllerProvider,
      (previous, next) {
        next.whenData((state) {
          final allItems = [
            ...state.items,
            ...state.sectionItems.values.expand((list) => list),
          ];

          final fingerprint = Object.hashAll(allItems.map((item) => item.uid));
          if (fingerprint == _precacheFingerprint) return;
          _precacheFingerprint = fingerprint;

          if (allItems.isEmpty || !context.mounted) return;

          final precacheService = ref.read(feedImagePrecacheServiceProvider);
          _scheduleCriticalImageWarmup(state);
          precacheService.precacheItems(
            context,
            allItems,
            maxItems: FeedConstants.initialPrecacheItems,
          );

          if (state.items.length > _lastKnownMainItemCount) {
            final newItems = state.items.skip(_lastKnownMainItemCount).toList();
            if (newItems.isNotEmpty) {
              precacheService.precacheItems(
                context,
                newItems,
                maxItems: FeedConstants.incrementalPrecacheItems,
              );
            }
          }
          _lastKnownMainItemCount = state.items.length;

          _deferredPrecacheTimer?.cancel();
          if (allItems.length > FeedConstants.initialPrecacheItems) {
            _deferredPrecacheTimer = Timer(
              FeedConstants.deferredPrecacheDelay,
              () {
                if (!mounted) return;
                precacheService.precacheItems(
                  context,
                  allItems.skip(FeedConstants.initialPrecacheItems).toList(),
                  maxItems: FeedConstants.deferredPrecacheItems,
                );
              },
            );
          }
        });
      },
    );
  }

  void _scheduleCriticalImageWarmup(FeedState state) {
    if (!mounted) return;

    final urls = _buildCriticalImageUrls(state);
    if (urls.isEmpty) {
      if (_criticalImagesReady && _hasRenderedFeedContent) return;
      setState(() {
        _criticalImagesReady = true;
        _hasRenderedFeedContent = true;
      });
      return;
    }

    final fingerprint = Object.hashAll(urls);
    if (fingerprint == _criticalWarmupFingerprint && _criticalImagesReady) {
      return;
    }

    _criticalWarmupFingerprint = fingerprint;
    final generation = ++_criticalWarmupGeneration;
    final criticalWarmupStopwatch = AppPerformanceTracker.startSpan(
      'feed.critical_image_warmup',
      data: {'urls': urls.length},
    );

    if (_hasRenderedFeedContent) {
      _criticalImagesReady = true;
    } else {
      setState(() {
        _criticalImagesReady = false;
      });
    }

    final precacheService = ref.read(feedImagePrecacheServiceProvider);
    unawaited(
      precacheService
          .precacheCriticalUrls(
            context,
            urls,
            cacheManager: ImageCacheConfig.profileCacheManager,
            maxWidth: ImageCacheConfig.feedPrecacheMaxDimension,
            maxHeight: ImageCacheConfig.feedPrecacheMaxDimension,
            timeout: FeedConstants.criticalPrecacheTimeout,
          )
          .whenComplete(() {
            if (!mounted || generation != _criticalWarmupGeneration) return;
            AppPerformanceTracker.finishSpan(
              'feed.critical_image_warmup',
              criticalWarmupStopwatch,
              data: {'urls': urls.length},
            );
            setState(() {
              _criticalImagesReady = true;
              _hasRenderedFeedContent = true;
            });
          }),
    );
  }

  List<String> _buildCriticalImageUrls(FeedState state) {
    final urls = <String>[];
    final seenUrls = <String>{};

    void addUrl(String? url) {
      if (url == null || url.isEmpty || !seenUrls.add(url)) return;
      urls.add(url);
    }

    addUrl(ref.read(currentUserProfileProvider).asData?.value?.foto);

    for (final item in _getSpotlightItems(state).take(2)) {
      addUrl(item.foto);
    }

    final visibleSectionEntries = state.sectionItems.entries.take(2);
    for (final entry in visibleSectionEntries) {
      for (final item in entry.value.take(2)) {
        addUrl(item.foto);
      }
    }

    for (final item in state.items.take(FeedConstants.criticalPrecacheItems)) {
      addUrl(item.foto);
    }

    return urls;
  }

  void _warmUpcomingMainFeedWindow() {
    if (!mounted || !_scrollController.hasClients) return;
    final mainItems = ref.read(feedControllerProvider).value?.items;
    if (mainItems == null || mainItems.isEmpty) return;

    const estimatedCardExtent = 168.0;
    final anchor = (_scrollController.position.pixels / estimatedCardExtent)
        .floor()
        .clamp(0, mainItems.length - 1);

    if (_lastWarmupAnchor >= 0 && (anchor - _lastWarmupAnchor).abs() < 3) {
      return;
    }
    _lastWarmupAnchor = anchor;

    final start = (anchor + 1).clamp(0, mainItems.length);
    final end = (start + 14).clamp(start, mainItems.length);
    if (end <= start) return;

    final upcomingItems = mainItems.sublist(start, end);
    ref
        .read(feedImagePrecacheServiceProvider)
        .precacheItems(context, upcomingItems, maxItems: upcomingItems.length);
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(feedControllerProvider);
    final state = stateAsync.value ?? const FeedState();
    final controller = ref.read(feedControllerProvider.notifier);
    final shouldHoldForCriticalImages =
        !_hasRenderedFeedContent &&
        state.items.isNotEmpty &&
        !_criticalImagesReady;

    if (state.isInitialLoading || shouldHoldForCriticalImages) {
      return const FeedScreenSkeleton();
    }

    return _buildFeedScaffold(
      context: context,
      stateAsync: stateAsync,
      state: state,
      controller: controller,
    );
  }
}
