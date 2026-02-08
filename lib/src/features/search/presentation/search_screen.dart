import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../feed/domain/feed_item.dart';
import '../../feed/presentation/feed_image_precache_service.dart';
import '../../feed/presentation/widgets/feed_card_vertical.dart';
import '../../feed/presentation/widgets/feed_loading_more.dart';
import '../../feed/presentation/widgets/feed_skeleton.dart';

import '../domain/search_filters.dart';
import 'search_controller.dart' as ctrl;
import 'widgets/category_tabs.dart';
import 'widgets/filter_modal.dart';
import 'widgets/search_filter_bar.dart';

/// Main search screen with category tabs, dynamic filters, and results list.
abstract final class SearchConstants {
  static const double paginationThreshold = 200.0;
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final currentScroll = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;

      if (currentScroll >= maxScroll - SearchConstants.paginationThreshold) {
        final controller = ref.read(ctrl.searchControllerProvider.notifier);
        if (controller.canLoadMore) {
          controller.loadMore();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ctrl.searchControllerProvider);
    final controller = ref.read(ctrl.searchControllerProvider.notifier);

    ref.listen(ctrl.searchControllerProvider, (previous, next) {
      if (next.items.isNotEmpty && context.mounted) {
        ref
            .read(feedImagePrecacheServiceProvider)
            .precacheItems(context, next.items);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Busca', showBackButton: false),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: controller.refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s8,
                  AppSpacing.s16,
                  AppSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _searchController,
                            label: null, // Remove space-consuming empty label
                            hint: 'Buscar por nome...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            onChanged: controller.setTerm,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        // Filter Button
                        _buildFilterButton(context, state, controller),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s16),

                    // Category Tabs
                    CategoryTabs(
                      selectedCategory: state.filters.category,
                      onCategoryChanged: controller.setCategory,
                    ),

                    const SizedBox(height: AppSpacing.s12),

                    // Dynamic Filter Chips
                    SearchFilterBar(
                      filters: state.filters,
                      onSubcategoryChanged:
                          controller.setProfessionalSubcategory,
                      onGenresChanged: controller.setGenres,
                      onInstrumentsChanged: controller.setInstruments,
                      onRolesChanged: controller.setRoles,
                      onServicesChanged: controller.setServices,
                      onStudioTypeChanged: controller.setStudioType,
                      onOpenGenres: () =>
                          _showFilterModal(context, state.filters, controller),
                    ),
                  ],
                ),
              ),
            ),

            // Results
            _buildResultsSliver(state, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    ctrl.SearchPaginationState state,
    ctrl.SearchController controller,
  ) {
    final hasActiveFilters = state.filters.hasActiveFilters;

    return GestureDetector(
      onTap: () => _showFilterModal(context, state.filters, controller),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasActiveFilters ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.all12,
        ),
        child: Icon(
          Icons.tune,
          color: hasActiveFilters
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showFilterModal(
    BuildContext context,
    SearchFilters filters,
    ctrl.SearchController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => FilterModal(
        filters: filters,
        onApply: (newFilters) {
          controller.setGenres(newFilters.genres);
          controller.setInstruments(newFilters.instruments);
          controller.setRoles(newFilters.roles);
          controller.setServices(newFilters.services);
          if (newFilters.studioType != filters.studioType) {
            controller.setStudioType(newFilters.studioType);
          }
          if (newFilters.canDoBackingVocal != filters.canDoBackingVocal) {
            controller.setBackingVocalFilter(newFilters.canDoBackingVocal);
          }
        },
      ),
    );
  }

  Widget _buildResultsSliver(
    ctrl.SearchPaginationState state,
    ctrl.SearchController controller,
  ) {
    return controller.resultsAsyncValue.when(
      data: (items) {
        if (items.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index >= items.length) {
              if (state.isLoadingMore) {
                return const FeedLoadingMore();
              }
              return state.hasMore
                  ? const SizedBox(height: AppSpacing.s48)
                  : const SizedBox.shrink();
            }

            final item = items[index];
            // FeedCardVertical already has internal margin (16h, 8v)
            return FeedCardVertical(item: item, onTap: () => _onItemTap(item));
          }, childCount: items.length + (state.hasMore ? 1 : 0)),
        );
      },
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const FeedItemSkeleton(),
          childCount: 5,
        ),
      ),
      error: (error, _) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.s16),
              Text('Erro ao buscar', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.s8),
              Text(
                error.toString(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Nenhum resultado encontrado',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Tente ajustar os filtros',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTap(FeedItem item) {
    context.push('/user/${item.uid}');
  }
}
