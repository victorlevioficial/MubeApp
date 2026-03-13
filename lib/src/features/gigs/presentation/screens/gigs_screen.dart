import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_overlay.dart';
import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/gig.dart';
import '../../domain/gig_filters.dart';
import '../../domain/gig_status.dart';
import '../providers/gig_filters_controller.dart';
import '../providers/gig_streams.dart';
import '../utils/gig_image_precache.dart';
import '../widgets/gig_card.dart';
import '../widgets/gig_filters_sheet.dart';

class GigsScreen extends ConsumerStatefulWidget {
  const GigsScreen({super.key});

  @override
  ConsumerState<GigsScreen> createState() => _GigsScreenState();
}

class _GigsScreenState extends ConsumerState<GigsScreen> {
  int _avatarWarmupFingerprint = 0;
  int _avatarWarmupGeneration = 0;
  bool _criticalAvatarsReady = false;
  bool _hasRenderedInitialContent = false;
  bool _isCriticalWarmupInProgress = false;

  bool get _isRunningWidgetTest {
    var isWidgetTest = false;
    assert(() {
      final bindingType = WidgetsBinding.instance.runtimeType.toString();
      isWidgetTest = bindingType.contains('TestWidgetsFlutterBinding');
      return true;
    }());
    return isWidgetTest;
  }

  @override
  Widget build(BuildContext context) {
    final isCompactWidth = MediaQuery.sizeOf(context).width < 380;
    final gigsAsync = ref.watch(gigsStreamProvider);
    final filters = ref.watch(gigFiltersControllerProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final canCreateGig = profile?.isCadastroConcluido == true;
    final showCreateFab =
        canCreateGig && gigsAsync.asData?.value.isNotEmpty == true;
    final shouldDeferInitialContent = !_isRunningWidgetTest;

    final activeCount = filters.activeFilterCount;
    final showHeroSkeleton =
        gigsAsync.isLoading ||
        (shouldDeferInitialContent &&
            !_hasRenderedInitialContent &&
            gigsAsync.asData?.value.isNotEmpty == true &&
            !_criticalAvatarsReady);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            expandedHeight: isCompactWidth ? 236 : 172,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _GigsHeroHeader(
                gigsAsync: gigsAsync,
                activeFilterCount: activeCount,
                isCompactLayout: isCompactWidth,
                showSummarySkeleton: showHeroSkeleton,
                onFiltersTap: () => _openFilters(context, ref),
              ),
            ),
            title: Text(
              'Gigs',
              style: AppTypography.headlineMedium.copyWith(fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: IconButton(
                  onPressed: () => _openFilters(context, ref),
                  tooltip: 'Filtros',
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.tune_rounded),
                      if (activeCount > 0)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s4,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Center(
                              child: Text(
                                '$activeCount',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        body: gigsAsync.when(
          loading: () => const _GigsListSkeleton(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: EmptyStateWidget(
                icon: Icons.cloud_off_rounded,
                title: 'Não foi possível carregar as gigs',
                subtitle:
                    'Tente novamente em instantes. Se o erro persistir, verifique sua conexão.',
                actionButton: AppButton.secondary(
                  text: 'Tentar novamente',
                  onPressed: () => ref.invalidate(gigsStreamProvider),
                ),
              ),
            ),
          ),
          data: (gigs) {
            if (gigs.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.storefront_outlined,
                title: 'Nenhuma gig encontrada',
                subtitle:
                    'Ajuste seus filtros ou publique a primeira oportunidade.',
                actionButton: profile == null || !profile.isCadastroConcluido
                    ? null
                    : AppButton.primary(
                        text: 'Criar gig',
                        onPressed: () => context.push(RoutePaths.gigCreate),
                      ),
              );
            }

            final creatorIdsKey = encodeGigUserIdsKey(
              gigs.map((gig) => gig.creatorId),
            );
            final creatorsAsync = creatorIdsKey.isEmpty
                ? const AsyncData(<String, AppUser>{})
                : ref.watch(gigUsersByStableIdsProvider(creatorIdsKey));
            final creatorsById = creatorsAsync.asData?.value;

            if (creatorsById == null && creatorsAsync.isLoading) {
              return const _GigsListSkeleton();
            }

            final resolvedCreators = creatorsById ?? const <String, AppUser>{};
            if (shouldDeferInitialContent) {
              _scheduleCriticalAvatarWarmup(gigs, resolvedCreators);
            }

            final shouldHoldForCriticalAvatars =
                shouldDeferInitialContent &&
                !_hasRenderedInitialContent &&
                gigs.isNotEmpty &&
                !_criticalAvatarsReady;

            if (shouldHoldForCriticalAvatars) {
              return const _GigsListSkeleton();
            }

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface2,
              onRefresh: () async {
                ref.invalidate(gigsStreamProvider);
                await ref.read(gigsStreamProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s8,
                  AppSpacing.s16,
                  AppSpacing.s48,
                ),
                itemBuilder: (context, index) => GigCard(
                  gig: gigs[index],
                  creator: resolvedCreators[gigs[index].creatorId],
                  onTap: () => context.push(
                    RoutePaths.gigDetailById(gigs[index].id),
                    extra: gigs[index],
                  ),
                ),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.s12),
                itemCount: gigs.length,
              ),
            );
          },
        ),
      ),
      floatingActionButton: !showCreateFab
          ? null
          : FloatingActionButton.extended(
              heroTag: 'gigs_create_fab',
              onPressed: () => context.push(RoutePaths.gigCreate),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              elevation: 8,
              extendedPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
              ),
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Nova gig',
                style: AppTypography.buttonPrimary.copyWith(fontSize: 14),
              ),
            ),
    );
  }

  void _scheduleCriticalAvatarWarmup(
    List<Gig> gigs,
    Map<String, AppUser> creatorsById,
  ) {
    if (!mounted) return;

    final urls = _buildCriticalAvatarUrls(gigs, creatorsById);
    if (urls.isEmpty) {
      if (_criticalAvatarsReady && _hasRenderedInitialContent) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _criticalAvatarsReady = true;
          _hasRenderedInitialContent = true;
          _isCriticalWarmupInProgress = false;
        });
      });
      return;
    }

    final fingerprint = Object.hashAll(urls);
    if (fingerprint == _avatarWarmupFingerprint &&
        (_criticalAvatarsReady || _isCriticalWarmupInProgress)) {
      return;
    }

    _avatarWarmupFingerprint = fingerprint;
    final generation = ++_avatarWarmupGeneration;
    _isCriticalWarmupInProgress = true;

    if (_hasRenderedInitialContent) {
      _criticalAvatarsReady = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _avatarWarmupGeneration) return;
        setState(() => _criticalAvatarsReady = false);
      });
    }

    unawaited(
      GigImagePrecache.precacheCreatorAvatars(context, urls).whenComplete(() {
        if (!mounted || generation != _avatarWarmupGeneration) return;
        setState(() {
          _criticalAvatarsReady = true;
          _hasRenderedInitialContent = true;
          _isCriticalWarmupInProgress = false;
        });
      }),
    );
  }

  List<String> _buildCriticalAvatarUrls(
    List<Gig> gigs,
    Map<String, AppUser> creatorsById,
  ) {
    final urls = <String>[];
    final seenUrls = <String>{};

    for (final gig in gigs.take(6)) {
      final url = creatorsById[gig.creatorId]?.foto?.trim();
      if (url == null || url.isEmpty || !seenUrls.add(url)) continue;
      urls.add(url);
    }

    return urls;
  }

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final config = await ref.read(appConfigProvider.future);
    if (!context.mounted) return;

    final result = await AppOverlay.bottomSheet(
      context: context,
      builder: (_) => GigFiltersSheet(
        initialFilters: ref.read(gigFiltersControllerProvider),
        config: config,
      ),
    );

    if (result is GigFilters && context.mounted) {
      ref.read(gigFiltersControllerProvider.notifier).updateFilters(result);
    }
  }
}

// ── Hero header with summary stats ────────────────────────────────────────────

class _GigsHeroHeader extends StatelessWidget {
  const _GigsHeroHeader({
    required this.gigsAsync,
    required this.activeFilterCount,
    required this.isCompactLayout,
    required this.showSummarySkeleton,
    required this.onFiltersTap,
  });

  final AsyncValue<List<Gig>> gigsAsync;
  final int activeFilterCount;
  final bool isCompactLayout;
  final bool showSummarySkeleton;
  final VoidCallback onFiltersTap;

  @override
  Widget build(BuildContext context) {
    final gigs = gigsAsync.asData?.value ?? [];
    final openCount = gigs.where((g) => g.status == GigStatus.open).length;
    final totalSlots = gigs.fold<int>(0, (sum, g) => sum + g.availableSlots);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s20,
        MediaQuery.of(context).padding.top + (isCompactLayout ? 40 : 48),
        AppSpacing.s20,
        isCompactLayout ? AppSpacing.s12 : AppSpacing.s14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface.withValues(alpha: 0.92),
            AppColors.background,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Oportunidades em tempo real',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (showSummarySkeleton)
            _HeroSummarySkeleton(isCompactLayout: isCompactLayout)
          else if (isCompactLayout) ...[
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.work_outline_rounded,
                    value: '$openCount',
                    label: 'abertas',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: _StatChip(
                    icon: Icons.groups_outlined,
                    value: '$totalSlots',
                    label: 'vagas',
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s10),
            _StatChip(
              icon: Icons.tune_rounded,
              value: activeFilterCount > 0 ? '$activeFilterCount' : '—',
              label: 'filtros',
              color: AppColors.primary,
              onTap: onFiltersTap,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.work_outline_rounded,
                    value: '$openCount',
                    label: 'abertas',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: _StatChip(
                    icon: Icons.groups_outlined,
                    value: '$totalSlots',
                    label: 'vagas',
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: _StatChip(
                    icon: Icons.tune_rounded,
                    value: activeFilterCount > 0 ? '$activeFilterCount' : '—',
                    label: 'filtros',
                    color: AppColors.primary,
                    onTap: onFiltersTap,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroSummarySkeleton extends StatelessWidget {
  const _HeroSummarySkeleton({required this.isCompactLayout});

  final bool isCompactLayout;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          if (isCompactLayout) ...[
            const Row(
              children: [
                Expanded(child: _HeroStatSkeleton()),
                SizedBox(width: AppSpacing.s10),
                Expanded(child: _HeroStatSkeleton()),
              ],
            ),
            const SizedBox(height: AppSpacing.s10),
            const _HeroStatSkeleton(),
          ] else
            const Row(
              children: [
                Expanded(child: _HeroStatSkeleton()),
                SizedBox(width: AppSpacing.s10),
                Expanded(child: _HeroStatSkeleton()),
                SizedBox(width: AppSpacing.s10),
                Expanded(child: _HeroStatSkeleton()),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroStatSkeleton extends StatelessWidget {
  const _HeroStatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 26, height: 26, borderRadius: AppRadius.r8),
          SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonText(width: 28, height: 14),
                SizedBox(height: AppSpacing.s4),
                SkeletonText(width: 42, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.all12,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
          boxShadow: AppEffects.subtleShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: AppRadius.all8,
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: AppSpacing.s8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 9,
                    ),
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

// ── Skeletons ─────────────────────────────────────────────────────────────────

class _GigsListSkeleton extends StatelessWidget {
  const _GigsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (_, _) => const _GigCardSkeleton(),
    );
  }
}

class _GigCardSkeleton extends StatelessWidget {
  const _GigCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Accent bar skeleton
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.r16),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s14,
              AppSpacing.s16,
              AppSpacing.s16,
            ),
            child: SkeletonShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 40,
                        height: 40,
                        borderRadius: AppRadius.r12,
                      ),
                      SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(width: 200, height: 18),
                            SizedBox(height: AppSpacing.s8),
                            SkeletonText(width: 140, height: 12),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.s8),
                      SkeletonBox(
                        width: 64,
                        height: 24,
                        borderRadius: AppRadius.rPill,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      SkeletonCircle(size: 22),
                      SizedBox(width: AppSpacing.s8),
                      SkeletonText(width: 120, height: 12),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s12),
                  SkeletonText(height: 14),
                  SizedBox(height: AppSpacing.s8),
                  SkeletonText(width: 200, height: 14),
                  SizedBox(height: AppSpacing.s14),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      SkeletonBox(
                        width: 100,
                        height: 30,
                        borderRadius: AppRadius.rPill,
                      ),
                      SkeletonBox(
                        width: 90,
                        height: 30,
                        borderRadius: AppRadius.rPill,
                      ),
                      SkeletonBox(
                        width: 70,
                        height: 30,
                        borderRadius: AppRadius.rPill,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
