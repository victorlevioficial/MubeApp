import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/application_status.dart';
import '../../domain/gig_application.dart';
import '../controllers/gig_actions_controller.dart';
import '../providers/gig_streams.dart';

enum _ApplicantCardAction { accept, reject }

class GigApplicantsScreen extends ConsumerWidget {
  const GigApplicantsScreen({super.key, required this.gigId});

  final String gigId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(gigApplicationsProvider(gigId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Candidaturas'),
      body: applicationsAsync.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const _ApplicantsListSkeleton(),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma candidatura ainda.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final applicantIdsKey = encodeGigUserIdsKey(
            applications.map((application) => application.applicantId),
          );
          final usersAsync = ref.watch(
            gigUsersByStableIdsProvider(applicantIdsKey),
          );

          return usersAsync.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const _ApplicantsListSkeleton(),
            error: (error, _) => Center(child: Text('Erro: $error')),
            data: (users) {
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemBuilder: (context, index) {
                  final application = applications[index];
                  final user = users[application.applicantId];
                  return _ApplicantCard(
                    gigId: gigId,
                    application: application,
                    user: user,
                  );
                },
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.s12),
                itemCount: applications.length,
              );
            },
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends ConsumerStatefulWidget {
  const _ApplicantCard({
    required this.gigId,
    required this.application,
    required this.user,
  });

  final String gigId;
  final GigApplication application;
  final AppUser? user;

  @override
  ConsumerState<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends ConsumerState<_ApplicantCard> {
  _ApplicantCardAction? _pendingAction;

  bool get _isBusy => _pendingAction != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                size: 48,
                photoUrl: widget.user?.foto,
                name: widget.user?.appDisplayName ?? 'Usuario',
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user?.appDisplayName ?? 'Usuario',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      widget.application.status.label,
                      style: AppTypography.labelMedium.copyWith(
                        color: _statusColor(widget.application.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            widget.application.message.isEmpty
                ? 'Sem mensagem adicional.'
                : widget.application.message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          if (widget.application.status == ApplicationStatus.pending)
            Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    text: 'Aceitar',
                    isLoading: _pendingAction == _ApplicantCardAction.accept,
                    onPressed: _isBusy
                        ? null
                        : () => _handleAction(_ApplicantCardAction.accept),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: AppButton.outline(
                    text: 'Recusar',
                    isLoading: _pendingAction == _ApplicantCardAction.reject,
                    onPressed: _isBusy
                        ? null
                        : () => _handleAction(_ApplicantCardAction.reject),
                  ),
                ),
              ],
            )
          else if (widget.application.status == ApplicationStatus.accepted)
            AppButton.secondary(
              text: 'Enviar mensagem',
              isFullWidth: true,
              onPressed: _isBusy
                  ? null
                  : () => ref
                        .read(gigActionsControllerProvider.notifier)
                        .openConversation(
                          context,
                          otherUserId: widget.application.applicantId,
                        ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(_ApplicantCardAction action) async {
    if (_isBusy) return;

    setState(() => _pendingAction = action);
    try {
      if (action == _ApplicantCardAction.accept) {
        await ref
            .read(gigActionsControllerProvider.notifier)
            .acceptApplication(
              gigId: widget.gigId,
              applicantId: widget.application.applicantId,
            );
      } else {
        await ref
            .read(gigActionsControllerProvider.notifier)
            .rejectApplication(
              gigId: widget.gigId,
              applicantId: widget.application.applicantId,
            );
      }

      if (!mounted) return;
      AppSnackBar.success(
        context,
        action == _ApplicantCardAction.accept
            ? 'Candidatura aceita.'
            : 'Candidatura recusada.',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _pendingAction = null);
      }
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

class _ApplicantsListSkeleton extends StatelessWidget {
  const _ApplicantsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemBuilder: (_, _) => const _ApplicantCardSkeleton(),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemCount: 4,
    );
  }
}

class _ApplicantCardSkeleton extends StatelessWidget {
  const _ApplicantCardSkeleton();

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
              children: [
                SkeletonCircle(size: 48),
                SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 156, height: 16),
                      SizedBox(height: AppSpacing.s8),
                      SkeletonText(width: 92, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s16),
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
          ],
        ),
      ),
    );
  }
}
