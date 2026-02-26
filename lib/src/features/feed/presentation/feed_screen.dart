import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/utils/app_logger.dart';

import '../../../core/mixins/pagination_mixin.dart';
import '../../../core/services/image_cache_config.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
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

/// Constants for the Feed screen layout and behavior
abstract final class FeedConstants {
  static const double filterBarHeight = 52.0;
  static const double paginationThreshold = 200.0;
  static const double bottomPadding = 80.0;
}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  Timer? _deferredPrecacheTimer;
  bool _isScrolled = false;
  int _precacheFingerprint = 0;
  int _criticalWarmupFingerprint = 0;
  bool _criticalWarmupInProgress = false;
  bool _isInitialBatchWarmed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedControllerProvider.notifier).loadAllData();
    });
  }

  @override
  void dispose() {
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
    context.push('/user/${item.uid}', extra: item);
  }

  void _navigateToSectionList(FeedSectionType type) {
    context.push('/feed/list', extra: {'type': type});
  }

  void _maybeWarmCriticalBatch(FeedState state) {
    if (!mounted) return;

    if (state.isInitialLoading) {
      _criticalWarmupFingerprint = 0;
      _criticalWarmupInProgress = false;
      _isInitialBatchWarmed = false;
      return;
    }

    if (_isInitialBatchWarmed || _criticalWarmupInProgress) return;

    final criticalItems = state.items.take(10).toList();
    final spotlightUrls = _getSpotlightItems(state)
        .map((item) => item.foto)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .take(3)
        .toList();

    if (criticalItems.isEmpty && spotlightUrls.isEmpty) {
      _isInitialBatchWarmed = true;
      return;
    }

    final fingerprint = Object.hashAll([
      ...criticalItems.map((item) => item.uid),
      ...spotlightUrls,
    ]);
    if (fingerprint == _criticalWarmupFingerprint) return;
    _criticalWarmupFingerprint = fingerprint;
    _criticalWarmupInProgress = true;

    final precacheService = ref.read(feedImagePrecacheServiceProvider);
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final spotlightWidth =
        (MediaQuery.sizeOf(context).width * 0.92 * pixelRatio)
            .round()
            .clamp(300, 1400)
            .toInt();
    final spotlightHeight = (200 * pixelRatio).round().clamp(200, 900).toInt();

    unawaited(
      Future.wait<void>([
        precacheService.precacheCriticalItems(
          context,
          criticalItems,
          maxItems: 10,
          timeout: const Duration(milliseconds: 2200),
        ),
        if (spotlightUrls.isNotEmpty)
          precacheService.precacheCriticalUrls(
            context,
            spotlightUrls,
            cacheManager: ImageCacheConfig.optimizedCacheManager,
            maxWidth: spotlightWidth,
            maxHeight: spotlightHeight,
            timeout: const Duration(milliseconds: 2200),
          ),
      ]).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _criticalWarmupInProgress = false;
          _isInitialBatchWarmed = true;
        });
      }),
    );
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

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(feedControllerProvider);
    final state = stateAsync.value ?? const FeedState();
    final controller = ref.read(feedControllerProvider.notifier);

    // Precache logic listener
    ref.listen(feedControllerProvider, (previous, next) {
      next.whenData((state) {
        _maybeWarmCriticalBatch(state);

        // Precache in phases to reduce startup contention.
        final allItems = [
          ...state.items,
          ...state.sectionItems.values.expand((list) => list),
        ];

        final fingerprint = Object.hashAll(allItems.map((item) => item.uid));
        if (fingerprint == _precacheFingerprint) return;
        _precacheFingerprint = fingerprint;

        if (allItems.isNotEmpty && context.mounted) {
          final precacheService = ref.read(feedImagePrecacheServiceProvider);

          // First wave: keep startup light.
          precacheService.precacheItems(context, allItems, maxItems: 4);

          // Second wave: deferred so first frames stay responsive.
          _deferredPrecacheTimer?.cancel();
          if (allItems.length > 4) {
            _deferredPrecacheTimer = Timer(
              const Duration(milliseconds: 900),
              () {
                if (!mounted) return;
                precacheService.precacheItems(
                  context,
                  allItems.skip(4).toList(),
                  maxItems: 8,
                );
              },
            );
          }
        }
      });
    });

    final shouldKeepSkeletonForWarmup =
        !state.isInitialLoading &&
        !_isInitialBatchWarmed &&
        state.items.isNotEmpty;

    if (state.isInitialLoading || shouldKeepSkeletonForWarmup) {
      return const FeedScreenSkeleton();
    }

    final hasError =
        stateAsync.hasError || state.status == PaginationStatus.error;
    final errorMessage =
        state.errorMessage ??
        stateAsync.error?.toString() ??
        'Erro desconhecido';

    if (hasError && state.sectionItems.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro ao carregar feed: $errorMessage'),
              const SizedBox(height: AppSpacing.s16),
              AppButton.primary(
                text: 'Tentar novamente',
                onPressed: () => controller.loadAllData(),
              ),
            ],
          ),
        ),
      );
    }

    final currentUser = ref.watch(currentUserProfileProvider).value;
    final spotlightItems = _getSpotlightItems(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          setState(() {
            _criticalWarmupFingerprint = 0;
            _criticalWarmupInProgress = false;
            _isInitialBatchWarmed = false;
          });
          await controller.loadAllData();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Pro Max: SliverAppBar with Glassmorphism (Refactored to FeedHeader)
            FeedHeader(
              currentUser: currentUser,
              isScrolled: _isScrolled,
              onNotificationTap: () {
                context.push('/notifications');
              },
            ),

            // Pre-cache Service Integration (keeps provider alive)
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, _) {
                  ref.watch(feedImagePrecacheServiceProvider);
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Spotlight carousel with top trending items
            if (spotlightItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s8),
                  child: FeaturedSpotlightCarousel(
                    items: spotlightItems,
                    onItemTap: _navigateToUser,
                  ),
                ),
              ),

            // Horizontal Sections (Lazy Load)
            if (state.sectionItems.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(top: AppSpacing.s8),
                sliver: SliverList.builder(
                  itemCount: state.sectionItems.length,
                  itemBuilder: (context, index) {
                    final entry = state.sectionItems.entries.elementAt(index);
                    if (entry.value.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      key: ValueKey('section_${entry.key.name}'),
                      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                      child: FeedSectionWidget(
                        title: _getSectionTitle(entry.key),
                        items: entry.value,
                        onSeeAllTap: () => _navigateToSectionList(entry.key),
                        onItemTap: _navigateToUser,
                      ),
                    );
                  },
                ),
              ),

            // Opaque Filter Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: FeedConstants.filterBarHeight,
                maxHeight: FeedConstants.filterBarHeight,
                topPadding: MediaQuery.of(context).padding.top,
                child: Container(
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: QuickFilterBar(
                    selectedFilter: state.currentFilter,
                    onFilterSelected: controller.onFilterChanged,
                  ),
                ),
              ),
            ),

            // Section Title: Principais / Destaques
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  AppSpacing.s24,
                  AppSpacing.s20,
                  AppSpacing.s16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryPressed],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'Principais Perfis',
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Empty State or Vertical List
            if (state.items.isEmpty && !state.isLoading)
              const SliverToBoxAdapter(
                child: EmptyStateWidget(
                  icon: Icons.music_off_rounded,
                  title: 'Nenhum músico encontrado',
                  subtitle: 'Tente ajustar seus filtros ou volte mais tarde',
                ),
              )
            else
              // Vertical List (Animated) - já inclui loading interno
              VerticalFeedList(
                useSliverMode: true,
                items: state.items,
                isLoading: state.status == PaginationStatus.loading,
                isLoadingMore: state.status == PaginationStatus.loadingMore,
                hasMore: state.hasMore,
                onLoadMore: controller.loadMoreMainFeed,
                padding:
                    EdgeInsets.zero, // Remove padding duplo, o skeleton já tem
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s48)),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  final double topPadding;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    required this.topPadding,
  });

  @override
  double get minExtent => minHeight + topPadding;
  @override
  double get maxExtent => maxHeight + topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background, // Ensure background covers the status bar
      padding: EdgeInsets.only(top: topPadding),
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child ||
        topPadding != oldDelegate.topPadding;
  }
}
