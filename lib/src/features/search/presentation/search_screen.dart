import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../feed/domain/feed_item.dart';
import '../../feed/presentation/feed_image_precache_service.dart';
import '../../feed/presentation/widgets/feed_card_vertical.dart';
import '../../feed/presentation/widgets/feed_loading_more.dart';
import '../../feed/presentation/widgets/feed_skeleton.dart';
import '../domain/search_filters.dart';
import 'search_controller.dart' as ctrl;
import 'widgets/active_filters_bar.dart';
import 'widgets/category_tabs.dart';
import 'widgets/filter_modal.dart';
import 'widgets/smart_prefilter_grid.dart';

const double _kPaginationThreshold = 200.0;

/// Main search screen with discovery prefilters and filtered results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  ProviderSubscription<ctrl.SearchPaginationState>? _precacheSubscription;

  String? _activePrefilterLabel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _setupPrecacheListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ctrl.searchControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _precacheSubscription?.close();
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setupPrecacheListener() {
    _precacheSubscription = ref.listenManual<ctrl.SearchPaginationState>(
      ctrl.searchControllerProvider,
      (previous, next) {
        if (!mounted || next.items.isEmpty) return;
        ref
            .read(feedImagePrecacheServiceProvider)
            .precacheItems(context, next.items);
      },
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.position.pixels;
    final max = _scrollController.position.maxScrollExtent;
    if (current >= max - _kPaginationThreshold) {
      final controller = ref.read(ctrl.searchControllerProvider.notifier);
      if (controller.canLoadMore) {
        controller.loadMore();
      }
    }
  }

  bool _isInSearchMode(ctrl.SearchPaginationState state) {
    return state.filters.hasActiveFilters ||
        state.filters.term.isNotEmpty ||
        state.filters.category != SearchCategory.all;
  }

  void _onPrefilterTap(SmartPrefilter prefilter) {
    setState(() => _activePrefilterLabel = prefilter.label);
    final controller = ref.read(ctrl.searchControllerProvider.notifier);
    final filters = prefilter.filters;

    _searchController.value = TextEditingValue(
      text: filters.term,
      selection: TextSelection.collapsed(offset: filters.term.length),
    );
    controller.applyFilters(filters);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearAllFilters() {
    setState(() => _activePrefilterLabel = null);
    _searchController.clear();
    ref.read(ctrl.searchControllerProvider.notifier).reset();
  }

  void _showFilterModal() {
    final state = ref.read(ctrl.searchControllerProvider);
    final controller = ref.read(ctrl.searchControllerProvider.notifier);

    AppOverlay.bottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => FilterModal(
        filters: state.filters,
        onApply: (newFilters) {
          setState(() => _activePrefilterLabel = null);
          controller.applyFilters(newFilters);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ctrl.searchControllerProvider);
    final controller = ref.read(ctrl.searchControllerProvider.notifier);
    final showResults = _isInSearchMode(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Busca',
        showBackButton: false,
        centerTitle: false,
        actions: [
          _FilterIconButton(
            hasActiveFilters: state.filters.hasActiveFilters,
            activeCount: _countActiveFilters(state.filters),
            onTap: _showFilterModal,
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: controller.refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar(controller)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.s12,
                  left: AppSpacing.s4,
                ),
                child: CategoryTabs(
                  selectedCategory: state.filters.category,
                  onCategoryChanged: (category) {
                    setState(() => _activePrefilterLabel = null);
                    controller.setCategory(category);
                  },
                ),
              ),
            ),
            if (showResults)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: ActiveFiltersBar(
                    filters: state.filters,
                    activePrefilterLabel: _activePrefilterLabel,
                    onClearAll: _clearAllFilters,
                    onClearPrefilter: _clearAllFilters,
                    onRemoveGenre: (genre) {
                      controller.setGenres(
                        state.filters.genres
                            .where((item) => item != genre)
                            .toList(),
                      );
                    },
                    onRemoveInstrument: (instrument) {
                      controller.setInstruments(
                        state.filters.instruments
                            .where((item) => item != instrument)
                            .toList(),
                      );
                    },
                    onRemoveRole: (role) {
                      controller.setRoles(
                        state.filters.roles
                            .where((item) => item != role)
                            .toList(),
                      );
                    },
                    onRemoveService: (service) {
                      controller.setServices(
                        state.filters.services
                            .where((item) => item != service)
                            .toList(),
                      );
                    },
                    onClearSubcategory: () =>
                        controller.setProfessionalSubcategory(null),
                    onClearStudioType: () => controller.setStudioType(null),
                    onClearBackingVocal: () =>
                        controller.setBackingVocalFilter(null),
                  ),
                ),
              ),
            if (showResults && state.isShowingRelaxedResults)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    0,
                    AppSpacing.s16,
                    AppSpacing.s12,
                  ),
                  child: _ApproximateResultsNotice(
                    relaxedFilterLabels: _relaxedFilterLabels(
                      state.filters,
                      state.effectiveFilters,
                    ),
                    onAdjust: _showFilterModal,
                  ),
                ),
              ),
            if (!showResults)
              SliverToBoxAdapter(child: _buildDiscoveryContent())
            else
              _buildResultsSliver(state, controller),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s48)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ctrl.SearchController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: AppTextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        label: null,
        hint: 'Buscar musicos, bandas, estudios...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                  controller.setTerm('');
                  setState(() {});
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              )
            : null,
        onChanged: (value) {
          controller.setTerm(value);
          setState(() {
            if (value.isNotEmpty) {
              _activePrefilterLabel = null;
            }
          });
        },
        onSubmitted: (_) => _searchFocusNode.unfocus(),
      ),
    );
  }

  Widget _buildDiscoveryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.s8),
        SmartPrefilterGrid(onPrefilterTap: _onPrefilterTap),
        const SizedBox(height: AppSpacing.s32),
      ],
    );
  }

  Widget _buildResultsSliver(
    ctrl.SearchPaginationState state,
    ctrl.SearchController controller,
  ) {
    return controller.resultsAsyncValue.when(
      data: (items) {
        if (items.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState(state));
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
            final avatarHeroTag = 'search-avatar-${item.uid}-$index';
            return FeedCardVertical(
              item: item,
              avatarHeroTag: avatarHeroTag,
              onTap: () => _onItemTap(item, avatarHeroTag: avatarHeroTag),
            );
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
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text('Erro ao buscar', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.s8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
                child: Text(
                  error.toString(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              GestureDetector(
                onTap: controller.refresh,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s24,
                    vertical: AppSpacing.s12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.pill,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Tentar novamente',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ctrl.SearchPaginationState state) {
    final hasConflict = state.filters.hasConflictingTypeFilters;
    final title = hasConflict
        ? 'Filtros em conflito'
        : 'Nenhum resultado encontrado';
    final description = hasConflict
        ? 'Essa combinacao mistura filtros de profissionais e estudios. Escolha uma categoria especifica ou limpe um dos grupos.'
        : 'Tente ajustar os filtros ou buscar por outros termos';
    final icon = hasConflict
        ? Icons.filter_alt_off_rounded
        : Icons.search_off_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.all20,
              ),
              child: Icon(icon, size: 40, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),
            GestureDetector(
              onTap: hasConflict ? _showFilterModal : _clearAllFilters,
              child: Text(
                hasConflict ? 'Ajustar filtros' : 'Limpar filtros',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countActiveFilters(SearchFilters filters) {
    int count = 0;
    if (filters.professionalSubcategory != null) count++;
    if (filters.genres.isNotEmpty) count++;
    if (filters.instruments.isNotEmpty) count++;
    if (filters.roles.isNotEmpty) count++;
    if (filters.services.isNotEmpty) count++;
    if (filters.studioType != null) count++;
    if (filters.canDoBackingVocal != null) count++;
    return count;
  }

  List<String> _relaxedFilterLabels(
    SearchFilters requested,
    SearchFilters effective,
  ) {
    final labels = <String>[];

    if (requested.genres.isNotEmpty && effective.genres.isEmpty) {
      labels.add('generos');
    }
    if (requested.instruments.isNotEmpty && effective.instruments.isEmpty) {
      labels.add('instrumentos');
    }
    if (requested.roles.isNotEmpty && effective.roles.isEmpty) {
      labels.add('funcoes');
    }
    if (requested.services.isNotEmpty && effective.services.isEmpty) {
      labels.add('servicos');
    }
    if (requested.studioType != null && effective.studioType == null) {
      labels.add('tipo de estudio');
    }
    if (requested.canDoBackingVocal != null &&
        effective.canDoBackingVocal == null) {
      labels.add('backing vocal');
    }

    return labels;
  }

  void _onItemTap(FeedItem item, {String? avatarHeroTag}) {
    context.push(
      RoutePaths.publicProfileById(item.uid),
      extra: avatarHeroTag == null
          ? null
          : {RoutePaths.avatarHeroTagExtraKey: avatarHeroTag},
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final bool hasActiveFilters;
  final int activeCount;
  final VoidCallback onTap;

  const _FilterIconButton({
    required this.hasActiveFilters,
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasActiveFilters
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: AppRadius.all12,
              border: Border.all(
                color: hasActiveFilters
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: hasActiveFilters
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
          if (activeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.pill,
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApproximateResultsNotice extends StatelessWidget {
  final List<String> relaxedFilterLabels;
  final VoidCallback onAdjust;

  const _ApproximateResultsNotice({
    required this.relaxedFilterLabels,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final relaxedSummary = relaxedFilterLabels.isEmpty
        ? 'Sem resultados exatos. Mostrando resultados aproximados.'
        : 'Sem resultados exatos. Mostrando resultados aproximados sem ${relaxedFilterLabels.join(', ')}.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.all12,
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resultados aproximados',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  relaxedSummary,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                GestureDetector(
                  onTap: onAdjust,
                  child: Text(
                    'Refinar filtros',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
