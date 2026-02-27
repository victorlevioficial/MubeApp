import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/analytics/analytics_provider.dart';
import '../../../../design_system/components/patterns/fade_in_slide.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/feed_item.dart';
import 'feed_card_vertical.dart';
import 'feed_item_skeleton.dart';
import 'feed_loading_more.dart';

/// A reusable vertical feed list widget with pagination, shimmer loading,
/// and empty state. Used across the app for "Ver Mais" screens and any
/// vertical list of feed items.
class VerticalFeedList extends ConsumerStatefulWidget {
  /// List of feed items to display
  final List<FeedItem> items;

  /// Whether the initial load is happening
  final bool isLoading;

  /// Whether more items can be loaded
  final bool hasMore;

  /// Whether pagination is currently loading
  final bool isLoadingMore;

  /// Callback to load more items (pagination)
  final VoidCallback? onLoadMore;

  /// Callback when tapping an item (default: navigate to profile)
  final void Function(FeedItem item)? onItemTap;

  /// Empty state message
  final String emptyMessage;

  /// Scroll controller for pagination detection
  final ScrollController? scrollController;

  /// Whether to use sliver mode (for CustomScrollView)
  final bool useSliverMode;

  /// Padding around the list
  final EdgeInsets padding;

  const VerticalFeedList({
    super.key,
    required this.items,
    this.isLoading = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onItemTap,
    this.emptyMessage = 'Nenhum resultado encontrado.',
    this.scrollController,
    this.useSliverMode = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  ConsumerState<VerticalFeedList> createState() => _VerticalFeedListState();
}

class _VerticalFeedListState extends ConsumerState<VerticalFeedList> {
  late ScrollController _scrollController;
  bool _ownsScrollController = false;

  @override
  void initState() {
    super.initState();
    if (!widget.useSliverMode) {
      if (widget.scrollController != null) {
        _scrollController = widget.scrollController!;
      } else {
        _scrollController = ScrollController();
        _ownsScrollController = true;
      }
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (!widget.useSliverMode) {
      _scrollController.removeListener(_onScroll);
      if (_ownsScrollController) {
        _scrollController.dispose();
      }
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore?.call();
    }
  }

  void _onItemTap(FeedItem item) {
    ref.read(analyticsServiceProvider).logFeedPostView(postId: item.uid);
    if (widget.onItemTap != null) {
      widget.onItemTap!(item);
    } else {
      // Default: navigate to user profile
      context.push('/user/${item.uid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 600;

    if (widget.useSliverMode) {
      return _buildSliverLayout(isWide);
    } else {
      return _buildRegularLayout(isWide);
    }
  }

  /// Build as a regular adaptive list/grid
  Widget _buildRegularLayout(bool isWide) {
    if (widget.isLoading && widget.items.isEmpty) {
      return Column(
        children: List.generate(
          6,
          (index) => FeedItemSkeleton(
            margin: isWide
                ? const EdgeInsets.symmetric(vertical: AppSpacing.s4)
                : null,
          ),
        ),
      );
    }

    if (widget.items.isEmpty && !widget.isLoading) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (!isWide) {
      return ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: widget.padding,
        itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return _buildLoadingIndicator();
          }
          return _buildItemCard(widget.items[index], index: index);
        },
      );
    }

    // Wide Grid Layout
    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding.add(const EdgeInsets.all(AppSpacing.s8)),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 450,
        mainAxisExtent: 130, // Fixed height for feed cards
        crossAxisSpacing: AppSpacing.s8,
        mainAxisSpacing: AppSpacing.s8,
      ),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return _buildLoadingIndicator();
        }
        return _buildItemCard(widget.items[index], index: index, isGrid: true);
      },
    );
  }

  /// Build as a Sliver adaptive layout
  Widget _buildSliverLayout(bool isWide) {
    if (widget.isLoading && widget.items.isEmpty) {
      return SliverToBoxAdapter(
        child: Column(
          children: List.generate(
            6,
            (index) => FeedItemSkeleton(
              margin: isWide
                  ? const EdgeInsets.symmetric(vertical: AppSpacing.s4)
                  : null,
            ),
          ),
        ),
      );
    }

    if (widget.items.isEmpty && !widget.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: Center(
            child: Text(
              widget.emptyMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    if (!isWide) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == widget.items.length) {
            return widget.isLoadingMore
                ? _buildLoadingIndicator()
                : (widget.hasMore
                      ? const SizedBox(height: AppSpacing.s48)
                      : const SizedBox.shrink());
          }
          return _buildItemCard(widget.items[index], index: index);
        }, childCount: widget.items.length + 1),
      );
    }

    // Wide Sliver Grid Layout
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 450,
          mainAxisExtent: 130,
          crossAxisSpacing: AppSpacing.s12,
          mainAxisSpacing: AppSpacing.s4,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= widget.items.length) return null;
          return _buildItemCard(
            widget.items[index],
            index: index,
            isGrid: true,
          );
        }, childCount: widget.items.length),
      ),
    );
  }

  Widget _buildItemCard(FeedItem item, {int index = 0, bool isGrid = false}) {
    // In grid mode, we remove the horizontal margin of the card
    // since the grid handles spacing.
    final card = FeedCardVertical(
      item: item,
      onTap: () => _onItemTap(item),
      margin: isGrid
          ? const EdgeInsets.symmetric(vertical: AppSpacing.s4)
          : null,
    );

    if (index < 6) {
      return FadeInSlide(
        duration: const Duration(milliseconds: 300),
        delay: Duration(milliseconds: index * 50),
        direction: isGrid ? FadeInSlideDirection.btt : FadeInSlideDirection.rtl,
        child: card,
      );
    }
    return card;
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
      child: FeedLoadingMore(),
    );
  }
}
