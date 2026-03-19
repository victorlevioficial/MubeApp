import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_message_resolver.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_refresh_indicator.dart';
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

part 'search_screen_ui.dart';

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
      body: AppRefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: AppRefreshIndicator.defaultScrollPhysics,
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
                    onClearRemoteRecording: () =>
                        controller.setOffersRemoteRecording(null),
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

  void _clearSearchTerm(ctrl.SearchController controller) {
    _searchController.clear();
    controller.setTerm('');
    setState(() {});
  }

  void _handleSearchTermChanged(
    ctrl.SearchController controller,
    String value,
  ) {
    controller.setTerm(value);
    setState(() {
      if (value.isNotEmpty) {
        _activePrefilterLabel = null;
      }
    });
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
    if (filters.offersRemoteRecording == true) count++;
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
    if (requested.offersRemoteRecording == true &&
        effective.offersRemoteRecording != true) {
      labels.add('gravação remota');
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
