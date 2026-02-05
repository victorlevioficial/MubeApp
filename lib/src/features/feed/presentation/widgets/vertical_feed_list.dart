import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/analytics/analytics_provider.dart';
import '../../../../design_system/components/patterns/fade_in_slide.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../data/feed_items_provider.dart';
import '../../domain/feed_item.dart';
import 'feed_card_vertical.dart';
import 'feed_loading_more.dart';
import 'feed_item_skeleton.dart';

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
    // Register initial items
    _registerItems();
  }

  @override
  void didUpdateWidget(VerticalFeedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _registerItems();
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

  void _registerItems() {
    if (widget.items.isNotEmpty) {
      // Defer to next frame to avoid building during build (safety)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(feedItemsProvider.notifier).loadItems(widget.items);
        }
      });
    }
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
      // Use centralized skeleton (no external padding, FeedItemSkeleton has margins)
      return Column(
        children: List.generate(6, (index) => const FeedItemSkeleton()),
      );
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
        return _buildItemCard(widget.items[index], index: index);
      },
    );
  }

  /// Build as a SliverList (for CustomScrollView embedding)
  Widget _buildSliverList() {
    // Loading state inicial (quando não tem itens)
    if (widget.isLoading && widget.items.isEmpty) {
      // Use centralized skeleton (sem padding externo, FeedItemSkeleton já tem margens)
      return SliverToBoxAdapter(
        child: Column(
          children: List.generate(6, (index) => const FeedItemSkeleton()),
        ),
      );
    }

    // Empty state
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

    // Sliver list com items + loader no final se necessário
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == widget.items.length) {
          // Último item: mostra loading se está carregando mais
          if (widget.isLoadingMore) {
            return _buildLoadingIndicator();
          }
          // Ou espaço no final se tem mais para carregar
          return widget.hasMore ? const SizedBox(height: 80) : const SizedBox.shrink();
        }
        return _buildItemCard(widget.items[index], index: index);
      }, childCount: widget.items.length + 1),
    );
  }

  Widget _buildItemCard(FeedItem item, {int index = 0}) {
    // Performance: Only animate the first 3 items (visible on initial load).
    // Items loaded during scroll appear instantly to maintain 60fps.
    if (index < 3) {
      return FadeInSlide(
        duration: const Duration(milliseconds: 250),
        delay: Duration(milliseconds: index * 40),
        child: FeedCardVertical(item: item, onTap: () => _onItemTap(item)),
      );
    }
    // No animation for lazy-loaded items
    return FeedCardVertical(item: item, onTap: () => _onItemTap(item));
  }

  Widget _buildLoadingIndicator() {
    return const FeedLoadingMore();
  }
}
