import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_overlay.dart';
import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/gig_filters.dart';
import '../providers/gig_filters_controller.dart';
import '../providers/gig_streams.dart';
import '../widgets/gig_card.dart';
import '../widgets/gig_filters_sheet.dart';

class GigsScreen extends ConsumerWidget {
  const GigsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gigsAsync = ref.watch(gigsStreamProvider);
    final filters = ref.watch(gigFiltersControllerProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final canCreateGig = profile?.isCadastroConcluido == true;
    final showCreateFab =
        canCreateGig && gigsAsync.asData?.value.isNotEmpty == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Gigs',
        actions: [
          IconButton(
            onPressed: () => _openFilters(context, ref),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded),
                if (filters.hasActiveFilters)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: gigsAsync.when(
        loading: () => const _GigsListSkeleton(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: EmptyStateWidget(
              icon: Icons.cloud_off_rounded,
              title: 'Nao foi possivel carregar as gigs',
              subtitle:
                  'Tente novamente em instantes. Se o erro persistir, verifique sua conexao.',
              actionButton: AppButton.secondary(
                text: 'Tentar novamente',
                onPressed: () => ref.invalidate(gigsStreamProvider),
              ),
            ),
          ),
        ),
        data: (gigs) {
          final creatorIdsKey = encodeGigUserIdsKey(
            gigs.map((gig) => gig.creatorId),
          );
          final creatorsById = creatorIdsKey.isEmpty
              ? const <String, AppUser>{}
              : ref
                        .watch(gigUsersByStableIdsProvider(creatorIdsKey))
                        .asData
                        ?.value ??
                    const <String, AppUser>{};

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

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(gigsStreamProvider);
              await ref.read(gigsStreamProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemBuilder: (context, index) => GigCard(
                gig: gigs[index],
                creator: creatorsById[gigs[index].creatorId],
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
      floatingActionButton: !showCreateFab
          ? null
          : FloatingActionButton.extended(
              heroTag: 'gigs_create_fab',
              onPressed: () => context.push(RoutePaths.gigCreate),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              elevation: 6,
              extendedPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s20,
              ),
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova gig'),
            ),
    );
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

class _GigsListSkeleton extends StatelessWidget {
  const _GigsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.s16),
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
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 220, height: 20),
                      SizedBox(height: AppSpacing.s10),
                      Row(
                        children: [
                          SkeletonBox(width: 72, height: 24, borderRadius: 12),
                          SizedBox(width: AppSpacing.s8),
                          SkeletonBox(width: 92, height: 24, borderRadius: 12),
                          SizedBox(width: AppSpacing.s8),
                          SkeletonBox(width: 88, height: 24, borderRadius: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s16),
            SkeletonText(height: 14),
            SizedBox(height: AppSpacing.s8),
            SkeletonText(width: double.infinity, height: 14),
            SizedBox(height: AppSpacing.s8),
            SkeletonText(width: 180, height: 14),
            SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: AppSpacing.s12,
              runSpacing: AppSpacing.s8,
              children: [
                SkeletonBox(width: 136, height: 32, borderRadius: 12),
                SkeletonBox(width: 128, height: 32, borderRadius: 12),
                SkeletonBox(width: 112, height: 32, borderRadius: 12),
                SkeletonBox(width: 124, height: 32, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
