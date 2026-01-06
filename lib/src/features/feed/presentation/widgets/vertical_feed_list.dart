import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/app_shimmer.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../data/feed_items_provider.dart';
import '../../domain/feed_item.dart';
import 'feed_card_vertical.dart';

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
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) {
      _scrollController.dispose();
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
    if (widget.onItemTap != null) {
      widget.onItemTap!(item);
    } else {
      // Default: navigate to user profile
      context.push('/user/${item.uid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Register items in centralized provider for reactive favorites
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.items.isNotEmpty) {
        ref.read(feedItemsProvider.notifier).loadItems(widget.items);
      }
    });

    if (widget.useSliverMode) {
      return _buildSliverList();
    } else {
      return _buildRegularList();
    }
  }

  /// Build as a regular ListView (for standalone screens)
  Widget _buildRegularList() {
    // Loading state
    if (widget.isLoading && widget.items.isEmpty) {
      return _buildLoadingSkeleton();
    }

    // Empty state
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

    // List with items
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
        return _buildItemCard(widget.items[index]);
      },
    );
  }

  /// Build as a SliverList (for CustomScrollView embedding)
  Widget _buildSliverList() {
    // Loading state
    if (widget.isLoading && widget.items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Empty state
    if (widget.items.isEmpty && !widget.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              widget.emptyMessage,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    // Sliver list with items
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == widget.items.length) {
          return widget.hasMore
              ? _buildLoadingIndicator()
              : const SizedBox(height: 80); // Bottom padding
        }
        return _buildItemCard(widget.items[index]);
      }, childCount: widget.items.length + 1),
    );
  }

  Widget _buildItemCard(FeedItem item) {
    return FeedCardVertical(item: item, onTap: () => _onItemTap(item));
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: widget.padding == EdgeInsets.zero
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
          : widget.padding,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              AppShimmer.circle(size: 80),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmer.text(width: 140, height: 16),
                    const SizedBox(height: 8),
                    AppShimmer.text(width: 100, height: 12),
                    const SizedBox(height: 6),
                    AppShimmer.text(width: 180, height: 24),
                  ],
                ),
              ),
              AppShimmer.circle(size: 24),
            ],
          ),
        );
      },
    );
  }
}
