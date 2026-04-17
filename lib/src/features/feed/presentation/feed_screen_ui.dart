part of 'feed_screen.dart';

extension _FeedScreenUi on _FeedScreenState {
  Widget _buildFeedScaffold({
    required BuildContext context,
    required AsyncValue<FeedState> stateAsync,
    required FeedState state,
    required FeedController controller,
    required AppUser? currentUser,
    required AsyncValue<List<Gig>> gigsPreviewAsync,
    required AsyncValue<List<StoryTrayBundle>> storyTrayAsync,
  }) {
    final hasError =
        stateAsync.hasError || state.status == PaginationStatus.error;
    final hasVisibleSections = state.sectionItems.values.any(
      (items) => items.isNotEmpty,
    );
    final errorMessage = _resolveFeedErrorMessage(stateAsync, state);

    if (hasError && !hasVisibleSections) {
      return _buildErrorState(controller, errorMessage);
    }

    final spotlightItems = _getSpotlightItems(state);
    final showGigsPreview =
        gigsPreviewAsync.isLoading ||
        gigsPreviewAsync.asData?.value.isNotEmpty == true;
    final pendingStoriesAsync = ref.watch(currentUserPendingStoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppRefreshIndicator(
        onRefresh: _refreshFeedSurface,
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: FeedConstants.initialCacheExtent,
          physics: AppRefreshIndicator.defaultScrollPhysics,
          slivers: [
            FeedHeader(
              currentUser: currentUser,
              isScrolled: _isScrolled,
              isStaleData: state.isStaleData,
              dataUpdatedAt: state.dataUpdatedAt,
              onNotificationTap: () {
                context.push(RoutePaths.notifications);
              },
            ),
            if (currentUser != null)
              SliverToBoxAdapter(
                child: _buildStoryTraySection(
                  currentUser: currentUser,
                  storyTrayAsync: storyTrayAsync,
                  pendingStoriesAsync: pendingStoriesAsync,
                ),
              ),
            if (spotlightItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s12),
                  child: FeaturedSpotlightCarousel(
                    items: spotlightItems,
                    onItemTap: _navigateToUser,
                  ),
                ),
              ),
            if (showGigsPreview)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.s16,
                    bottom: AppSpacing.s8,
                  ),
                  child: HomeGigsPreviewSection(
                    gigsAsync: gigsPreviewAsync,
                    onSeeAllTap: () => context.go(RoutePaths.gigs),
                    onGigTap: (gig) {
                      context.push(
                        RoutePaths.gigDetailById(gig.id),
                        extra: gig,
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  AppSpacing.s8,
                  AppSpacing.s20,
                  AppSpacing.s8,
                ),
                child: MatchpointHighlightCard(
                  user: currentUser,
                  onTap: () => context.push(RoutePaths.matchpoint),
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

  Widget _buildStoryTraySection({
    required AppUser currentUser,
    required AsyncValue<List<StoryTrayBundle>> storyTrayAsync,
    required AsyncValue<List<StoryItem>> pendingStoriesAsync,
  }) {
    final storyBundles = storyTrayAsync.value ?? const <StoryTrayBundle>[];
    final pendingStories =
        pendingStoriesAsync.asData?.value ?? const <StoryItem>[];
    final trayError = storyTrayAsync.error;
    final trayErrorMessage = storyTrayAsync.hasError && trayError != null
        ? resolveErrorMessage(trayError)
        : null;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoryTray(
            currentUser: currentUser,
            storyBundles: storyBundles,
            pendingProcessingCount: pendingStories.length,
            onCreateStory: () => unawaited(_openStoryCreator()),
            onOpenStoryBundle: (bundle) => unawaited(_openStoryViewer(bundle)),
            onOpenCurrentUserStoryOptions: (bundle) =>
                unawaited(_openCurrentUserStoryActions(bundle)),
          ),
          if (pendingStories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                0,
                AppSpacing.s20,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: AppSpacing.all12,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.all12,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pendingStories.length == 1
                                ? 'Seu video esta sendo processado'
                                : '${pendingStories.length} stories estao sendo processados',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            'Ele vai aparecer na bandeja assim que o processamento terminar.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    AppButton.ghost(
                      text: 'Atualizar',
                      size: AppButtonSize.small,
                      onPressed: () async {
                        ref.invalidate(currentUserPendingStoriesProvider);
                        await ref
                            .read(storyTrayControllerProvider.notifier)
                            .refresh();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (trayErrorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                0,
                AppSpacing.s20,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: AppSpacing.all12,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.all12,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nao foi possivel carregar os stories',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            trayErrorMessage,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    AppButton.ghost(
                      text: 'Tentar novamente',
                      size: AppButtonSize.small,
                      onPressed: () => ref
                          .read(storyTrayControllerProvider.notifier)
                          .refresh(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
              child: EmptyStateWidget(
                icon: Icons.feed_outlined,
                title: 'Nao foi possivel carregar o feed',
                subtitle: errorMessage,
                actionButton: AppButton.primary(
                  text: 'Tentar novamente',
                  onPressed: controller.loadAllData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveFeedErrorMessage(
    AsyncValue<FeedState> stateAsync,
    FeedState state,
  ) {
    final stateMessage = state.errorMessage?.trim();
    if (stateMessage != null && stateMessage.isNotEmpty) {
      return resolveErrorMessage(stateMessage);
    }
    if (stateAsync.hasError && stateAsync.error != null) {
      return resolveErrorMessage(stateAsync.error!);
    }
    return 'Algo deu errado. Tente novamente.';
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
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryPressed],
              ),
              borderRadius: AppRadius.all8,
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
