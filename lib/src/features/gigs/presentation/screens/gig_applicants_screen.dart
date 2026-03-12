import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';
import '../../domain/application_status.dart';
import '../../domain/gig_application.dart';
import '../controllers/gig_actions_controller.dart';
import '../gig_error_message.dart';
import '../providers/gig_streams.dart';

enum _ApplicantCardAction { accept, reject }

class GigApplicantsScreen extends ConsumerWidget {
  const GigApplicantsScreen({super.key, required this.gigId});

  final String gigId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final gigAsync = ref.watch(gigDetailProvider(gigId));
    final currentUserId = authAsync.asData?.value?.uid;
    final gig = gigAsync.asData?.value;

    final Widget body;
    if (authAsync.isLoading || gigAsync.isLoading) {
      body = const _ApplicantsListSkeleton();
    } else if (authAsync.hasError) {
      body = _GigApplicantsErrorState(
        title: 'Não foi possível validar seu acesso',
        message: resolveGigErrorMessage(authAsync.error!),
      );
    } else if (gigAsync.hasError) {
      body = _GigApplicantsErrorState(
        title: 'Não foi possível carregar a gig',
        message: resolveGigErrorMessage(gigAsync.error!),
      );
    } else if (currentUserId == null) {
      body = const _GigApplicantsErrorState(
        title: 'Sessão encerrada',
        message: 'Faça login novamente para ver as candidaturas.',
      );
    } else if (gig == null) {
      body = const _GigApplicantsErrorState(
        title: 'Gig não encontrada',
        message: 'Não foi possível localizar a gig solicitada.',
      );
    } else if (gig.creatorId != currentUserId) {
      body = const _GigApplicantsErrorState(
        title: 'Acesso indisponivel',
        message: 'Apenas o criador da gig pode ver as candidaturas.',
      );
    } else {
      final applicationsAsync = ref.watch(gigApplicationsProvider(gigId));
      body = applicationsAsync.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const _ApplicantsListSkeleton(),
        error: (error, _) => _GigApplicantsErrorState(
          title: 'Não foi possível carregar as candidaturas',
          message: resolveGigErrorMessage(error),
        ),
        data: (applications) {
          if (applications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: 'Nenhuma candidatura ainda',
              subtitle: 'As candidaturas aparecerão aqui quando chegarem.',
            );
          }

          final applicantIdsKey = encodeGigUserIdsKey(
            applications.map((application) => application.applicantId),
          );
          final usersAsync = ref.watch(
            gigUsersByStableIdsProvider(applicantIdsKey),
          );

          // Summary counts
          final pendingCount = applications
              .where((a) => a.status == ApplicationStatus.pending)
              .length;
          final acceptedCount = applications
              .where((a) => a.status == ApplicationStatus.accepted)
              .length;

          return usersAsync.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const _ApplicantsListSkeleton(),
            error: (error, _) => _GigApplicantsErrorState(
              title: 'Não foi possível carregar os candidatos',
              message: resolveGigErrorMessage(error),
            ),
            data: (users) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s8,
                  AppSpacing.s16,
                  AppSpacing.s24,
                ),
                children: [
                  // Summary bar
                  if (applications.length > 1) ...[
                    _ApplicantsSummaryBar(
                      total: applications.length,
                      pending: pendingCount,
                      accepted: acceptedCount,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                  ],
                  // Applicant cards
                  for (var index = 0; index < applications.length; index++) ...[
                    _ApplicantCard(
                      gigId: gigId,
                      application: applications[index],
                      user: users[applications[index].applicantId],
                    ),
                    if (index < applications.length - 1)
                      const SizedBox(height: AppSpacing.s12),
                  ],
                ],
              );
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Candidaturas'),
      body: body,
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _ApplicantsSummaryBar extends StatelessWidget {
  const _ApplicantsSummaryBar({
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

// ── Error state ───────────────────────────────────────────────────────────────

class _GigApplicantsErrorState extends StatelessWidget {
  final String title;
  final String message;

  const _GigApplicantsErrorState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: EmptyStateWidget(
          icon: Icons.assignment_late_outlined,
          title: title,
          subtitle: message,
          actionButton: AppButton.secondary(
            text: 'Voltar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

// ── Applicant card ────────────────────────────────────────────────────────────

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
    final statusColor = _statusColor(widget.application.status);
    final displayName = widget.user?.appDisplayName ?? 'Usuário';
    final categoryLabel = _categoryLabel(widget.user);

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
                  // ── User header ──────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.24),
                            width: 2,
                          ),
                        ),
                        child: UserAvatar(
                          size: 44,
                          photoUrl: widget.user?.foto,
                          name: displayName,
                          showBorder: false,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTypography.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (categoryLabel.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.s2),
                              Text(
                                categoryLabel,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      _StatusBadge(
                        label: widget.application.status.label,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  // ── Message ──────────────────────────────────────────
                  if (widget.application.message.isNotEmpty) ...[
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
                        widget.application.message,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Sem mensagem adicional.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s14),
                  // ── Actions ──────────────────────────────────────────
                  if (widget.application.status == ApplicationStatus.pending)
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.primary(
                            text: 'Aceitar',
                            isLoading:
                                _pendingAction == _ApplicantCardAction.accept,
                            onPressed: _isBusy
                                ? null
                                : () => _handleAction(
                                    _ApplicantCardAction.accept,
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: AppButton.outline(
                            text: 'Recusar',
                            isLoading:
                                _pendingAction == _ApplicantCardAction.reject,
                            onPressed: _isBusy
                                ? null
                                : () => _handleAction(
                                    _ApplicantCardAction.reject,
                                  ),
                          ),
                        ),
                      ],
                    )
                  else if (widget.application.status ==
                      ApplicationStatus.accepted)
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
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(AppUser? user) {
    if (user == null) return '';
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return 'Perfil Individual';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Estúdio';
      case AppUserType.contractor:
        return 'Contratante';
      case null:
        return '';
    }
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
      AppSnackBar.error(context, resolveGigErrorMessage(error));
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

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _ApplicantsListSkeleton extends StatelessWidget {
  const _ApplicantsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
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
                      SkeletonCircle(size: 48),
                      SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(width: 140, height: 16),
                            SizedBox(height: AppSpacing.s4),
                            SkeletonText(width: 90, height: 12),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.s8),
                      SkeletonBox(width: 70, height: 22, borderRadius: 11),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s12),
                  SkeletonBox(height: 60, borderRadius: AppRadius.r12),
                  SizedBox(height: AppSpacing.s14),
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
