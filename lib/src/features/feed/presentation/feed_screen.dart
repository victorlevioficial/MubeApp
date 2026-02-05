import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mixins/pagination_mixin.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import 'feed_controller.dart';
import 'feed_image_precache_service.dart';
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
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isScrolled = false;

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
    _searchController.dispose();
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
    } catch (_) {
      return type.name.toUpperCase();
    }
  }

  void _navigateToUser(FeedItem item) {
    context.push('/user/${item.uid}', extra: item);
  }

  void _navigateToSectionList(FeedSectionType type) {
    context.push('/feed/list/${type.name}', extra: type);
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(feedControllerProvider);
    final state = stateAsync.value ?? const FeedState();
    final controller = ref.read(feedControllerProvider.notifier);

    // Precache logic listener
    ref.listen(feedControllerProvider, (previous, next) {
      next.whenData((state) {
        // Precache all images as soon as data arrives (during skeleton phase)
        final allItems = [
          ...state.items,
          ...state.sectionItems.values.expand((list) => list),
        ];

        if (allItems.isNotEmpty && context.mounted) {
          // Use precache service to decode images into memory
          ref
              .read(feedImagePrecacheServiceProvider)
              .precacheItems(context, allItems);
        }
      });
    });

    if (state.isInitialLoading) {
      return const FeedScreenSkeleton();
    }

    if (stateAsync.hasError && state.sectionItems.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro ao carregar feed: ${stateAsync.error}'),
              const SizedBox(height: AppSpacing.s16),
              ElevatedButton(
                onPressed: () => controller.loadAllData(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final currentUser = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => controller.loadAllData(),
        child: CustomScrollView(
          controller: _scrollController,
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

            // Horizontal Sections (Lazy Load)
            if (state.sectionItems.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(top: AppSpacing.s24),
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
                  AppSpacing.s16,
                  AppSpacing.s24,
                  AppSpacing.s16,
                  AppSpacing.s12,
                ),
                child: Text(
                  'Destaques',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                padding: EdgeInsets.zero, // Remove padding duplo, o skeleton já tem
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
