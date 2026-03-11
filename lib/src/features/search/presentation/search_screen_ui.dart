part of 'search_screen.dart';

extension _SearchScreenUi on _SearchScreenState {
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
                onTap: () => _clearSearchTerm(controller),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              )
            : null,
        onChanged: (value) => _handleSearchTermChanged(controller, value),
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
                  resolveErrorMessage(error),
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
