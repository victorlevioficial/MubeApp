import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/feedback/app_refresh_indicator.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/components/loading/app_skeleton.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
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
      orElse: () => const FeedSection(
        type: FeedSectionType.technicians,
        title: 'Resultados',
      ),
    );
    return section.title;
  }

  Future<void> _refreshFeedList() async {
    final refreshFuture = ref.refresh(
      feedListControllerProvider(widget.sectionType).future,
    );
    await refreshFuture;
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      feedListControllerProvider(widget.sectionType),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: _getTitle(), showBackButton: true),
      body: AppRefreshIndicator(
        onRefresh: _refreshFeedList,
        child: stateAsync.when(
          loading: () => const FeedListSkeleton(itemCount: 4),
          error: (err, stack) => ListView(
            physics: AppRefreshIndicator.defaultScrollPhysics,
            padding: AppSpacing.all24,
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.68,
                child: EmptyStateWidget(
                  icon: Icons.error_outline_rounded,
                  title: 'Erro ao carregar resultados',
                  subtitle: 'Puxe para atualizar ou tente novamente.',
                  actionButton: TextButton(
                    onPressed: _refreshFeedList,
                    child: const Text('Tentar novamente'),
                  ),
                ),
              ),
            ],
          ),
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
