import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../domain/gig_status.dart';
import '../gig_error_message.dart';
import '../providers/gig_streams.dart';
import '../widgets/gig_card.dart';

class MyGigsScreen extends ConsumerWidget {
  const MyGigsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gigsAsync = ref.watch(myGigsStreamProvider);
    final body = gigsAsync.when(
      loading: () => const _MyGigsListSkeleton(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: EmptyStateWidget(
          icon: Icons.cloud_off_rounded,
          title: 'Não foi possível carregar seus gigs',
          subtitle: resolveGigErrorMessage(error),
        ),
      ),
      data: (gigs) {
        if (gigs.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.library_music_outlined,
            title: 'Você ainda não publicou gigs',
            subtitle: 'Quando publicar, elas aparecerão aqui.',
          );
        }

        // Summary
        final openCount = gigs.where((g) => g.status == GigStatus.open).length;
        final totalApplicants = gigs.fold<int>(
          0,
          (sum, g) => sum + g.applicantCount,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s24,
          ),
          children: [
            // Summary chips
            if (gigs.length > 1) ...[
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.work_outline_rounded,
                    label: '$openCount abertas',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  _MiniStat(
                    icon: Icons.how_to_reg_outlined,
                    label: '$totalApplicants candidaturas',
                    color: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
            for (var index = 0; index < gigs.length; index++) ...[
              GigCard(
                gig: gigs[index],
                onTap: () =>
                    context.push(RoutePaths.gigDetailById(gigs[index].id)),
              ),
              if (index < gigs.length - 1)
                const SizedBox(height: AppSpacing.s12),
            ],
          ],
        );
      },
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Meus gigs'),
      body: body,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.s8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _MyGigsListSkeleton extends StatelessWidget {
  const _MyGigsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
      children: const [
        SkeletonShimmer(
          child: Row(
            children: [
              _MiniStatSkeleton(width: 122),
              SizedBox(width: AppSpacing.s8),
              _MiniStatSkeleton(width: 146),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.s16),
        _MyGigCardSkeleton(),
        SizedBox(height: AppSpacing.s12),
        _MyGigCardSkeleton(),
        SizedBox(height: AppSpacing.s12),
        _MyGigCardSkeleton(),
      ],
    );
  }
}

class _MiniStatSkeleton extends StatelessWidget {
  const _MiniStatSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonCircle(size: 14),
          SizedBox(width: AppSpacing.s8),
          Expanded(child: SkeletonText(height: 12)),
        ],
      ),
    );
  }
}

class _MyGigCardSkeleton extends StatelessWidget {
  const _MyGigCardSkeleton();

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
                      SkeletonBox(
                        width: 64,
                        height: 24,
                        borderRadius: AppRadius.rPill,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s12),
                  SkeletonText(height: 14),
                  SizedBox(height: AppSpacing.s8),
                  SkeletonText(width: 180, height: 14),
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
