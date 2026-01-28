import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/app_refresh_indicator.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../domain/feed_section.dart';
import 'feed_view_controller.dart';
import 'widgets/vertical_feed_list.dart';

/// Full-screen list view for a feed section with pagination.
/// Uses the reusable VerticalFeedList widget.
class FeedListScreen extends ConsumerStatefulWidget {
  final FeedSectionType sectionType;

  const FeedListScreen({super.key, required this.sectionType});

  @override
  ConsumerState<FeedListScreen> createState() => _FeedListScreenState();
}

class _FeedListScreenState extends ConsumerState<FeedListScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getTitle() {
    final section = FeedSection.homeSections.firstWhere(
      (s) => s.type == widget.sectionType,
      orElse: () =>
          const FeedSection(type: FeedSectionType.artists, title: 'Resultados'),
    );
    return section.title;
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      feedListControllerProvider(widget.sectionType),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MubeAppBar(title: _getTitle(), showBackButton: true),
      body: AppRefreshIndicator(
        onRefresh: () =>
            ref.refresh(feedListControllerProvider(widget.sectionType).future),
        child: stateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erro: $err')),
          data: (state) {
            return VerticalFeedList(
              items: state.items,
              isLoading: false, // Initial loading handled by AsyncValue
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: () => ref
                  .read(feedListControllerProvider(widget.sectionType).notifier)
                  .loadMore(),
              scrollController: _scrollController,
              padding: AppSpacing.v8,
            );
          },
        ),
      ),
    );
  }
}
