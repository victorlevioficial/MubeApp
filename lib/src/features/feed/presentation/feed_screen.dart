import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/utils/app_logger.dart';

import '../../../core/errors/error_message_resolver.dart';
import '../../../core/mixins/pagination_mixin.dart';
import '../../../core/services/image_cache_config.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_refresh_indicator.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_performance_tracker.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../gigs/domain/gig.dart';
import '../../gigs/presentation/providers/gig_streams.dart';
import '../../matchpoint/presentation/widgets/matchpoint_highlight_card.dart';
import '../../splash/presentation/splash_feed_render_tracking.dart';
import '../../stories/domain/story_item.dart';
import '../../stories/domain/story_tray_bundle.dart';
import '../../stories/domain/story_viewer_route_args.dart';
import '../../stories/presentation/controllers/story_tray_controller.dart';
import '../../stories/presentation/widgets/story_tray.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import '../domain/spotlight_rotation.dart';
import 'feed_controller.dart';
import 'feed_image_precache_service.dart';
import 'widgets/featured_spotlight_carousel.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_section_widget.dart';
import 'widgets/feed_skeleton.dart';
import 'widgets/home_gigs_preview_section.dart';
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

enum _CurrentUserStoryAction { view, create }

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  Timer? _deferredPrecacheTimer;
  ProviderSubscription<AsyncValue<FeedState>>? _feedSubscription;
  ProviderSubscription<AsyncValue<List<StoryTrayBundle>>>?
  _storyTraySubscription;
  bool _isScrolled = false;
  int _precacheFingerprint = 0;
  int _storyPrecacheFingerprint = 0;
  int _lastKnownMainItemCount = 0;
  int _lastWarmupAnchor = -1;
  int _criticalWarmupFingerprint = 0;
  int _criticalWarmupGeneration = 0;
  Stopwatch? _initialDependenciesHoldStopwatch;
  bool _hasReleasedInitialLayout = false;
  bool _hasReportedFirstContentVisible = false;
  bool _hasTrackedInitialDependenciesHold = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _setupPrecacheListener();
    _setupStoryPrecacheListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedControllerProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    _finishInitialDependenciesHold(status: 'disposed');
    _feedSubscription?.close();
    _storyTraySubscription?.close();
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

  Future<void> _openStoryCreator() async {
    await context.push(RoutePaths.storyCreate);
    if (!mounted) return;
    ref.invalidate(currentUserPendingStoriesProvider);
    await ref.read(storyTrayControllerProvider.notifier).refresh();
  }

  Future<void> _openStoryViewer(StoryTrayBundle bundle) async {
    final initialStory = bundle.stories.isEmpty
        ? bundle.latestStory
        : bundle.stories.first;
    if (initialStory == null) {
      return;
    }

    if (bundle.isCurrentUser) {
      await context.push(RoutePaths.storyViewerById(initialStory.id));
    } else {
      final bundles = ref.read(storyTrayControllerProvider).asData?.value;
      final viewerBundles = bundles == null || bundles.isEmpty
          ? <StoryTrayBundle>[bundle]
          : bundles;

      await context.push(
        RoutePaths.storyViewerById(initialStory.id),
        extra: StoryViewerRouteArgs(
          bundles: viewerBundles,
          initialOwnerUid: bundle.ownerUid,
          initialStoryId: initialStory.id,
        ),
      );
    }

    if (!mounted) return;
    ref.invalidate(currentUserPendingStoriesProvider);
    await ref.read(storyTrayControllerProvider.notifier).refresh();
  }

  void _runCurrentUserStoryAction(
    _CurrentUserStoryAction action,
    StoryTrayBundle bundle,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (action) {
        case _CurrentUserStoryAction.view:
          unawaited(_openStoryViewer(bundle));
        case _CurrentUserStoryAction.create:
          unawaited(_openStoryCreator());
      }
    });
  }

  Future<void> _openCurrentUserStoryActions(StoryTrayBundle bundle) async {
    final action = await AppOverlay.bottomSheet<_CurrentUserStoryAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.top24),
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              0,
              AppSpacing.s16,
              AppSpacing.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu story',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Escolha o que deseja fazer com seus stories publicados.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Ver story',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Abrir seus stories ativos na visualizacao.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(_CurrentUserStoryAction.view),
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.add_circle_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Publicar novo',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Criar outro story sem sair da bandeja.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(_CurrentUserStoryAction.create),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    _runCurrentUserStoryAction(action, bundle);
  }

  Future<void> _refreshFeedSurface() async {
    ref.invalidate(currentUserPendingStoriesProvider);
    await Future.wait<void>([
      ref.read(feedControllerProvider.notifier).refresh(),
      ref.read(storyTrayControllerProvider.notifier).refresh(),
    ]);
  }

  List<FeedItem> _getSpotlightItems(FeedState state) {
    if (state.featuredItems.isNotEmpty) {
      return state.featuredItems
          .where(SpotlightRotation.isEligible)
          .toList(growable: false);
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
      if (!SpotlightRotation.isEligible(item)) continue;
      uniqueItems[item.uid] = item;
    }
    final sortedItems = uniqueItems.values.toList();
    sortedItems.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return sortedItems.take(5).toList();
  }

  void _setupStoryPrecacheListener() {
    _storyTraySubscription = ref
        .listenManual<AsyncValue<List<StoryTrayBundle>>>(
          storyTrayControllerProvider,
          (previous, next) {
            final bundles = next.value;
            if (bundles == null || bundles.isEmpty || !context.mounted) return;
            final fingerprint = Object.hashAll(bundles.map((b) => b.ownerUid));
            if (fingerprint == _storyPrecacheFingerprint) return;
            _storyPrecacheFingerprint = fingerprint;

            for (final bundle in bundles.take(6)) {
              final firstStory = bundle.stories.isEmpty
                  ? null
                  : bundle.stories.first;
              if (firstStory != null && !firstStory.isVideo) {
                precacheImage(
                  NetworkImage(firstStory.mediaUrl),
                  context,
                  onError: (_, _) {},
                ).ignore();
              }
              final thumb = firstStory?.thumbnailUrl;
              if (thumb != null && thumb.isNotEmpty) {
                precacheImage(
                  NetworkImage(thumb),
                  context,
                  onError: (_, _) {},
                ).ignore();
              }
            }
          },
        );
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

  void _updateInitialDependenciesHoldTracking(bool shouldHold) {
    if (shouldHold) {
      if (_hasTrackedInitialDependenciesHold ||
          _initialDependenciesHoldStopwatch != null) {
        return;
      }

      _initialDependenciesHoldStopwatch = AppPerformanceTracker.startSpan(
        'feed.ui.initial_dependencies_hold',
        data: {'reason': 'current_user_loading'},
      );
      return;
    }

    _finishInitialDependenciesHold(status: 'released');
  }

  void _finishInitialDependenciesHold({required String status}) {
    final stopwatch = _initialDependenciesHoldStopwatch;
    if (stopwatch == null) return;

    _initialDependenciesHoldStopwatch = null;
    _hasTrackedInitialDependenciesHold = true;
    AppPerformanceTracker.finishSpan(
      'feed.ui.initial_dependencies_hold',
      stopwatch,
      data: {'status': status},
    );
  }

  void _scheduleCriticalImageWarmup(FeedState state) {
    if (!mounted) return;

    final urls = _buildCriticalImageUrls(state);
    if (urls.isEmpty) return;

    final fingerprint = Object.hashAll(urls);
    if (fingerprint == _criticalWarmupFingerprint) return;

    _criticalWarmupFingerprint = fingerprint;
    final generation = ++_criticalWarmupGeneration;
    final criticalWarmupStopwatch = AppPerformanceTracker.startSpan(
      'feed.critical_image_warmup',
      data: {'urls': urls.length},
    );

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
            AppPerformanceTracker.finishSpan(
              'feed.critical_image_warmup',
              criticalWarmupStopwatch,
              data: {
                'urls': urls.length,
                'status': generation == _criticalWarmupGeneration
                    ? 'done'
                    : 'stale',
              },
            );
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

  void _reportFirstContentVisible({
    required FeedState state,
    required AsyncValue<AppUser?> currentUserAsync,
    required AsyncValue<List<Gig>> gigsPreviewAsync,
  }) {
    if (_hasReportedFirstContentVisible) return;
    _hasReportedFirstContentVisible = true;

    finishSplashToFeedRenderTracking(
      data: {
        'items': state.items.length,
        'sections': state.sectionItems.length,
        'feed_status': state.status.name,
        'has_current_user': currentUserAsync.hasValue,
        'has_gigs_preview': gigsPreviewAsync.hasValue,
      },
    );

    AppPerformanceTracker.mark(
      'feed.ui.first_content_visible',
      data: {
        'items': state.items.length,
        'sections': state.sectionItems.length,
        'feed_status': state.status.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(feedControllerProvider);
    final state = stateAsync.value ?? const FeedState();
    final controller = ref.read(feedControllerProvider.notifier);
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final gigsPreviewAsync = ref.watch(homeGigsPreviewProvider);
    final storyTrayAsync = ref.watch(storyTrayControllerProvider);
    final hasRenderableFeedContent =
        state.items.isNotEmpty ||
        state.sectionItems.values.any((items) => items.isNotEmpty) ||
        state.featuredItems.isNotEmpty;
    final shouldHoldForInitialDependencies =
        !_hasReleasedInitialLayout &&
        !stateAsync.hasError &&
        state.status != PaginationStatus.error &&
        !hasRenderableFeedContent &&
        (currentUserAsync.asData == null && currentUserAsync.isLoading);

    if (state.isInitialLoading || shouldHoldForInitialDependencies) {
      _updateInitialDependenciesHoldTracking(shouldHoldForInitialDependencies);
      return const FeedScreenSkeleton();
    }

    _updateInitialDependenciesHoldTracking(false);
    _releaseInitialLayout(
      state: state,
      currentUserAsync: currentUserAsync,
      gigsPreviewAsync: gigsPreviewAsync,
    );

    return _buildFeedScaffold(
      context: context,
      stateAsync: stateAsync,
      state: state,
      controller: controller,
      currentUser: currentUserAsync.asData?.value,
      gigsPreviewAsync: gigsPreviewAsync,
      storyTrayAsync: storyTrayAsync,
    );
  }

  void _releaseInitialLayout({
    required FeedState state,
    required AsyncValue<AppUser?> currentUserAsync,
    required AsyncValue<List<Gig>> gigsPreviewAsync,
  }) {
    if (_hasReleasedInitialLayout) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasReleasedInitialLayout) return;
      setState(() => _hasReleasedInitialLayout = true);
      _reportFirstContentVisible(
        state: state,
        currentUserAsync: currentUserAsync,
        gigsPreviewAsync: gigsPreviewAsync,
      );
    });
  }
}
