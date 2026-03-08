import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_overlay.dart';
import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/data/auth_repository.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro ao carregar gigs: $error')),
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
                onTap: () => context.push(
                  RoutePaths.gigDetailById(gigs[index].id),
                  extra: gigs[index],
                ),
              ),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
              itemCount: gigs.length,
            ),
          );
        },
      ),
      floatingActionButton: profile == null || !profile.isCadastroConcluido
          ? null
          : AppButton.primary(
              text: 'Nova gig',
              onPressed: () => context.push(RoutePaths.gigCreate),
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
