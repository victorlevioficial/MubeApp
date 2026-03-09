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
import '../controllers/gig_actions_controller.dart';
import '../providers/gig_streams.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Minhas candidaturas'),
      body: applicationsAsync.when(
        loading: () => const _MyApplicationsListSkeleton(),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (applications) {
          if (applications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.assignment_outlined,
              title: 'Nenhuma candidatura ainda',
              subtitle:
                  'Quando voce se candidatar a uma gig, ela aparecera aqui.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemBuilder: (context, index) {
              final application = applications[index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.all16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.gigTitle ?? 'Gig',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      application.status.label,
                      style: AppTypography.labelMedium.copyWith(
                        color: _statusColor(application.status),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    Text(
                      application.message.isEmpty
                          ? 'Sem mensagem adicional.'
                          : application.message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outline(
                            text: 'Ver gig',
                            onPressed: () => context.push(
                              RoutePaths.gigDetailById(application.gigId),
                            ),
                          ),
                        ),
                        if (application.status == ApplicationStatus.accepted &&
                            application.creatorId != null) ...[
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: AppButton.primary(
                              text: 'Mensagem',
                              onPressed: () => ref
                                  .read(gigActionsControllerProvider.notifier)
                                  .openConversation(
                                    context,
                                    otherUserId: application.creatorId!,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (application.status == ApplicationStatus.accepted ||
                        application.status == ApplicationStatus.pending) ...[
                      const SizedBox(height: AppSpacing.s12),
                      AppButton.outline(
                        text: application.status == ApplicationStatus.accepted
                            ? 'Desistir da gig'
                            : 'Retirar candidatura',
                        isFullWidth: true,
                        onPressed: () async {
                          try {
                            await ref
                                .read(gigActionsControllerProvider.notifier)
                                .withdrawApplication(application.gigId);
                            if (!context.mounted) return;
                            AppSnackBar.success(
                              context,
                              application.status == ApplicationStatus.accepted
                                  ? 'Voce desistiu da gig.'
                                  : 'Candidatura retirada com sucesso.',
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            AppSnackBar.error(
                              context,
                              error.toString().replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
            itemCount: applications.length,
          );
        },
      ),
    );
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

class _MyApplicationsListSkeleton extends StatelessWidget {
  const _MyApplicationsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s16),
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
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonText(width: 190, height: 18),
            SizedBox(height: AppSpacing.s8),
            SkeletonText(width: 84, height: 12),
            SizedBox(height: AppSpacing.s12),
            SkeletonText(height: 14),
            SizedBox(height: AppSpacing.s8),
            SkeletonText(width: 220, height: 14),
            SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 44, borderRadius: 14)),
                SizedBox(width: AppSpacing.s12),
                Expanded(child: SkeletonBox(height: 44, borderRadius: 14)),
              ],
            ),
            SizedBox(height: AppSpacing.s12),
            SkeletonBox(height: 44, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}
