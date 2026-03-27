import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../domain/application_status.dart';
import '../../domain/gig_application.dart';
import '../controllers/gig_actions_controller.dart';
import '../gig_error_message.dart';
import '../providers/gig_streams.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);
    final body = applicationsAsync.when(
      loading: () => const _MyApplicationsListSkeleton(),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: EmptyStateWidget(
            icon: Icons.cloud_off_rounded,
            title: 'Não foi possível carregar suas candidaturas',
            subtitle: resolveGigErrorMessage(error),
            actionButton: AppButton.secondary(
              text: 'Tentar novamente',
              onPressed: () => ref.invalidate(myApplicationsProvider),
            ),
          ),
        ),
      ),
      data: (applications) {
        if (applications.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.assignment_outlined,
            title: 'Nenhuma candidatura ainda',
            subtitle:
                'Quando você se candidatar a uma gig, ela aparecerá aqui.',
          );
        }

        // Summary
        final pendingCount = applications
            .where((a) => a.status == ApplicationStatus.pending)
            .length;
        final acceptedCount = applications
            .where((a) => a.status == ApplicationStatus.accepted)
            .length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s24,
          ),
          children: [
            if (applications.length > 1) ...[
              _ApplicationsSummaryBar(
                total: applications.length,
                pending: pendingCount,
                accepted: acceptedCount,
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
            for (var index = 0; index < applications.length; index++) ...[
              _ApplicationCard(
                application: applications[index],
                onViewGig: () => context.push(
                  RoutePaths.gigDetailById(applications[index].gigId),
                ),
                onMessage:
                    applications[index].status == ApplicationStatus.accepted &&
                        applications[index].creatorId != null
                    ? () => ref
                          .read(gigActionsControllerProvider.notifier)
                          .openConversation(
                            context,
                            otherUserId: applications[index].creatorId!,
                          )
                    : null,
                onWithdraw:
                    (applications[index].status == ApplicationStatus.accepted ||
                        applications[index].status == ApplicationStatus.pending)
                    ? () async {
                        try {
                          await ref
                              .read(gigActionsControllerProvider.notifier)
                              .withdrawApplication(applications[index].gigId);
                          if (!context.mounted) return;
                          AppSnackBar.success(
                            context,
                            applications[index].status ==
                                    ApplicationStatus.accepted
                                ? 'Você desistiu da gig.'
                                : 'Candidatura retirada com sucesso.',
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          AppSnackBar.error(
                            context,
                            resolveGigErrorMessage(error),
                          );
                        }
                      }
                    : null,
              ),
              if (index < applications.length - 1)
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
      appBar: const AppAppBar(title: 'Minhas candidaturas'),
      body: body,
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _ApplicationsSummaryBar extends StatelessWidget {
  const _ApplicationsSummaryBar({
    required this.total,
    required this.pending,
    required this.accepted,
  });

  final int total;
  final int pending;
  final int accepted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _SummaryItem(
            value: '$total',
            label: 'total',
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.s16),
          Container(width: 1, height: 28, color: AppColors.border),
          const SizedBox(width: AppSpacing.s16),
          _SummaryItem(
            value: '$pending',
            label: 'pendentes',
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.s16),
          Container(width: 1, height: 28, color: AppColors.border),
          const SizedBox(width: AppSpacing.s16),
          _SummaryItem(
            value: '$accepted',
            label: 'aceitas',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Application card ──────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onViewGig,
    this.onMessage,
    this.onWithdraw,
  });

  final GigApplication application;
  final VoidCallback onViewGig;
  final VoidCallback? onMessage;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(application.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title + status ────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: AppRadius.all12,
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          _statusIcon(application.status),
                          size: 18,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              application.gigTitle ?? 'Gig',
                              style: AppTypography.titleMedium.copyWith(
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              application.status.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  // ── Message ───────────────────────────────────────────
                  if (application.message.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.s12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: AppRadius.all12,
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        application.message,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    Text(
                      'Sem mensagem adicional.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s16),
                  // ── Actions ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.outline(
                          text: 'Ver gig',
                          onPressed: onViewGig,
                        ),
                      ),
                      if (onMessage != null) ...[
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: AppButton.primary(
                            text: 'Mensagem',
                            onPressed: onMessage,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (onWithdraw != null) ...[
                    const SizedBox(height: AppSpacing.s10),
                    AppButton.ghost(
                      text: application.status == ApplicationStatus.accepted
                          ? 'Desistir da gig'
                          : 'Retirar candidatura',
                      isFullWidth: true,
                      onPressed: onWithdraw,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.schedule_rounded;
      case ApplicationStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case ApplicationStatus.rejected:
        return Icons.block_rounded;
      case ApplicationStatus.gigCancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.accepted:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.gigCancelled:
        return AppColors.textSecondary;
    }
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _MyApplicationsListSkeleton extends StatelessWidget {
  const _MyApplicationsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
      itemBuilder: (_, _) => const _MyApplicationCardSkeleton(),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemCount: 4,
    );
  }
}

class _MyApplicationCardSkeleton extends StatelessWidget {
  const _MyApplicationCardSkeleton();

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
          // Status bar
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.r16),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: SkeletonShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBox(
                        width: 36,
                        height: 36,
                        borderRadius: AppRadius.r12,
                      ),
                      SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(width: 190, height: 18),
                            SizedBox(height: AppSpacing.s8),
                            SkeletonText(width: 80, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s12),
                  SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                  SizedBox(height: AppSpacing.s16),
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonBox(height: 44, borderRadius: 24),
                      ),
                      SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: SkeletonBox(height: 44, borderRadius: 24),
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
