import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/utils/app_logger.dart';

import '../../../core/mixins/pagination_mixin.dart';
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
  static const int initialPrecacheItems = 4;
  static const int incrementalPrecacheItems = 6;
  static const int deferredPrecacheItems = 10;
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
    context.push('/user/${item.uid}', extra: item);
  }

  void _navigateToSectionList(FeedSectionType type) {
    context.push('/feed/list', extra: {'type': type});
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

    if (state.isInitialLoading) {
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
          await controller.refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: FeedConstants.initialCacheExtent,
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
                selectedFilter: state.currentFilter,
                onFilterSelected: controller.onFilterChanged,
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
  final double topPadding;
  final String selectedFilter;
  final Function(String) onFilterSelected;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.topPadding,
    required this.selectedFilter,
    required this.onFilterSelected,
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
      child: SizedBox.expand(
        child: Container(
          color: AppColors.background,
          alignment: Alignment.center,
          child: QuickFilterBar(
            selectedFilter: selectedFilter,
            onFilterSelected: onFilterSelected,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        selectedFilter != oldDelegate.selectedFilter ||
        topPadding != oldDelegate.topPadding;
  }
}
