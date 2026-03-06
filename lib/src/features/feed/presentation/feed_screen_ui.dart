part of 'feed_screen.dart';

extension _FeedScreenUi on _FeedScreenState {
  Widget _buildFeedScaffold({
    required BuildContext context,
    required AsyncValue<FeedState> stateAsync,
    required FeedState state,
    required FeedController controller,
  }) {
    final hasError =
        stateAsync.hasError || state.status == PaginationStatus.error;
    final hasVisibleSections = state.sectionItems.values.any(
      (items) => items.isNotEmpty,
    );
    final errorMessage =
        state.errorMessage ??
        stateAsync.error?.toString() ??
        'Erro desconhecido';

    if (hasError && !hasVisibleSections) {
      return _buildErrorState(controller, errorMessage);
    }

    final currentUser = ref.watch(currentUserProfileProvider).asData?.value;
    final spotlightItems = _getSpotlightItems(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppRefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: FeedConstants.initialCacheExtent,
          physics: AppRefreshIndicator.defaultScrollPhysics,
          slivers: [
            FeedHeader(
              currentUser: currentUser,
              isScrolled: _isScrolled,
              onNotificationTap: () {
                context.push(RoutePaths.notifications);
              },
            ),
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
            const SliverToBoxAdapter(child: _FeedMainSectionHeader()),
            if (state.items.isEmpty && !state.isLoading)
              const SliverToBoxAdapter(
                child: EmptyStateWidget(
                  icon: Icons.music_off_rounded,
                  title: 'Nenhum músico encontrado',
                  subtitle: 'Tente ajustar seus filtros ou volte mais tarde',
                ),
              )
            else
              VerticalFeedList(
                useSliverMode: true,
                items: state.items,
                isLoading: state.status == PaginationStatus.loading,
                isLoadingMore: state.status == PaginationStatus.loadingMore,
                hasMore: state.hasMore,
                onLoadMore: controller.loadMoreMainFeed,
                padding: EdgeInsets.zero,
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s48)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(FeedController controller, String errorMessage) {
    return Scaffold(
      body: AppRefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: AppRefreshIndicator.defaultScrollPhysics,
          padding: AppSpacing.all24,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar feed: $errorMessage'),
                  const SizedBox(height: AppSpacing.s16),
                  AppButton.primary(
                    text: 'Tentar novamente',
                    onPressed: controller.loadAllData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedMainSectionHeader extends StatelessWidget {
  const _FeedMainSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
      color: AppColors.background,
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
