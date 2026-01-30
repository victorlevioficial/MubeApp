import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/feed_section.dart';
import 'feed_controller.dart';
import 'feed_image_precache_service.dart';
import 'widgets/feed_header.dart';
import 'widgets/feed_section_widget.dart';
import 'widgets/feed_skeleton.dart';
import 'widgets/quick_filter_bar.dart';
import 'widgets/vertical_feed_list.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

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
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 200) {
        ref.read(feedControllerProvider.notifier).loadMoreMainFeed();
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
          ...state.mainItems,
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
        color: AppColors.brandPrimary,
        backgroundColor: AppColors.surface,
        onRefresh: () => controller.loadAllData(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Pro Max: SliverAppBar with Glassmorphism (Refactored to FeedHeader)
            FeedHeader(currentUser: currentUser, onNotificationTap: () {}),

            // Pre-cache Service Integration (Just watching keeps it alive)
            // Pre-cache Service Integration (Just watching keeps it alive)
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
                      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                      child: FeedSectionWidget(
                        title: _getSectionTitle(entry.key),
                        items: entry.value,
                        onSeeAllTap: () {
                          context.push(
                            '/feed/list/${entry.key.name}',
                            extra: entry.key,
                          );
                        },
                        onItemTap: (item) {
                          context.push('/user/${item.uid}', extra: item);
                        },
                      ),
                    );
                  },
                ),
              ),

            // Opaque Filter Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 52.0, // Reduced to match chip height (44) + padding
                maxHeight: 52.0,
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

            // Vertical List (Animated)
            VerticalFeedList(
              useSliverMode: true,
              items: state.mainItems,
              isLoading: state.isLoadingMain,
              hasMore: state.hasMoreMain,
              onLoadMore: () {},
              padding: AppSpacing.h16,
            ),

            // Bottom Loader
            if (state.isLoadingMain && state.mainItems.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
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
