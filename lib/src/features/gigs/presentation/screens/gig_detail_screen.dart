import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_chip.dart';
import '../../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../../design_system/components/feedback/app_overlay.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/application_status.dart';
import '../../domain/gig.dart';
import '../../domain/gig_application.dart';
import '../../domain/gig_date_mode.dart';
import '../../domain/gig_draft.dart';
import '../../domain/gig_location_type.dart';
import '../../domain/gig_status.dart';
import '../controllers/gig_actions_controller.dart';
import '../gig_error_message.dart';
import '../providers/gig_streams.dart';
import '../widgets/gig_compensation_chip.dart';
import '../widgets/gig_creator_preview.dart';
import '../widgets/gig_status_badge.dart';
import '../widgets/gig_visuals.dart';

enum _GigDetailPendingAction {
  apply,
  withdraw,
  closeGig,
  cancelGig,
  updateDescription,
}

class GigDetailScreen extends ConsumerStatefulWidget {
  const GigDetailScreen({super.key, required this.gigId});

  final String gigId;

  @override
  ConsumerState<GigDetailScreen> createState() => _GigDetailScreenState();
}

class _GigDetailScreenState extends ConsumerState<GigDetailScreen> {
  _GigDetailPendingAction? _pendingAction;

  @override
  Widget build(BuildContext context) {
    final gigAsync = ref.watch(gigDetailProvider(widget.gigId));
    final appConfigAsync = ref.watch(appConfigProvider);
    final gig = gigAsync.asData?.value;

    final Widget body;
    if (gig == null) {
      body = gigAsync.when(
        loading: () => const _GigDetailSkeleton(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Text(
              resolveGigErrorMessage(error),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        data: (_) => const Center(child: Text('Gig não encontrada.')),
      );
    } else {
      final creatorIdsKey = encodeGigUserIdsKey([gig.creatorId]);
      final creatorAsync = ref.watch(
        gigUsersByStableIdsProvider(creatorIdsKey),
      );
      final creatorsById = creatorAsync.asData?.value;
      final creator = creatorsById?[gig.creatorId];
      final config = appConfigAsync.asData?.value;
      final authUserAsync = ref.watch(authStateChangesProvider);
      final currentUserId = authUserAsync.asData?.value?.uid;
      final isCreator = currentUserId == gig.creatorId;
      final myApplicationAsync = currentUserId == null || isCreator
          ? const AsyncData<GigApplication?>(null)
          : ref.watch(myGigApplicationProvider(gig.id));
      final myApplication = myApplicationAsync.asData?.value;
      final hasPendingDependencies =
          (currentUserId == null && authUserAsync.isLoading) ||
          (creatorsById == null && creatorAsync.isLoading) ||
          (config == null && appConfigAsync.isLoading) ||
          (!isCreator &&
              currentUserId != null &&
              myApplicationAsync.asData == null &&
              myApplicationAsync.isLoading);

      if (hasPendingDependencies) {
        body = const _GigDetailSkeleton();
      } else {
        body = ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Header section ─────────────────────────────────────────
            _GigDetailHeader(gig: gig, creator: creator),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s20,
                AppSpacing.s16,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info card ────────────────────────────────────────
                  _DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Data',
                          value: _dateLabel(gig),
                        ),
                        const _InfoDivider(),
                        _InfoRow(
                          icon: gig.locationType == GigLocationType.remote
                              ? Icons.wifi_tethering_rounded
                              : Icons.location_on_outlined,
                          label: 'Modalidade',
                          value:
                              '${gig.locationType.label} • ${gig.location?['label']?.toString() ?? 'Sem local informado'}',
                        ),
                        const _InfoDivider(),
                        _InfoRow(
                          icon: Icons.groups_outlined,
                          label: 'Vagas',
                          value:
                              '${gig.slotsTotal} totais • ${gig.availableSlots} disponíveis',
                          valueColor:
                              gig.availableSlots <= 2 && gig.availableSlots > 0
                              ? AppColors.primary
                              : null,
                        ),
                        const _InfoDivider(),
                        _InfoRow(
                          icon: Icons.how_to_reg_outlined,
                          label: 'Candidaturas',
                          value: '${gig.applicantCount}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  // ── Description card ─────────────────────────────────
                  _DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: AppRadius.all8,
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s10),
                            Text(
                              'Descrição',
                              style: AppTypography.titleSmall.copyWith(
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          gig.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Requirements card ─────────────────────────────────
                  if (config != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    _DetailCard(
                      child: _RequirementsSection(gig: gig, config: config),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s20),
                  // ── Action panel ──────────────────────────────────────
                  _ActionPanelSection(
                    gig: gig,
                    isCreator: isCreator,
                    myApplication: myApplication,
                    pendingAction: _pendingAction,
                    onApply: () => _showApplyDialog(context, gig.id),
                    onWithdraw: () => _withdraw(context, gig.id),
                    onViewApplicants: () =>
                        context.push(RoutePaths.gigApplicantsById(gig.id)),
                    onCloseGig: () => _confirmCloseGig(context, gig.id),
                    onCancelGig: () => _confirmCancelGig(context, gig.id),
                    onEdit: () =>
                        context.push(RoutePaths.gigCreate, extra: gig),
                    onEditDescriptionOnly: gig.canEditDescriptionOnly
                        ? () => _showEditDescriptionDialog(context, gig)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.s24),
                ],
              ),
            ),
          ],
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Detalhes da gig',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartilhar gig',
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(text: RoutePaths.gigShareUrl(widget.gigId)),
              );
            },
          ),
        ],
      ),
      body: body,
    );
  }

  String _dateLabel(Gig gig) {
    if (gig.dateMode == GigDateMode.fixedDate && gig.gigDate != null) {
      return DateFormat('dd/MM/yyyy HH:mm').format(gig.gigDate!);
    }
    return gig.dateMode.label;
  }

  Future<void> _showApplyDialog(BuildContext context, String gigId) async {
    final controller = TextEditingController();
    final result = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Enviar candidatura'),
        content: AppTextField(
          controller: controller,
          label: 'Mensagem',
          hint: 'Apresente sua experiência e disponibilidade.',
          maxLines: 4,
          minLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    await _runPendingAction(_GigDetailPendingAction.apply, () async {
      try {
        await ref
            .read(gigActionsControllerProvider.notifier)
            .applyToGig(gigId, controller.text);
        if (!context.mounted) return;
        AppSnackBar.success(
          context,
          'Candidatura enviada. A gig agora aparece em Minhas candidaturas.',
        );
      } catch (error) {
        if (!context.mounted) return;
        AppSnackBar.error(context, resolveGigErrorMessage(error));
      }
    });
  }

  Future<void> _withdraw(BuildContext context, String gigId) async {
    await _runPendingAction(_GigDetailPendingAction.withdraw, () async {
      try {
        await ref
            .read(gigActionsControllerProvider.notifier)
            .withdrawApplication(gigId);
        if (!context.mounted) return;
        AppSnackBar.success(context, 'Candidatura retirada com sucesso.');
      } catch (error) {
        if (!context.mounted) return;
        AppSnackBar.error(context, resolveGigErrorMessage(error));
      }
    });
  }

  Future<void> _confirmCloseGig(BuildContext context, String gigId) async {
    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Encerrar gig?',
        message: 'A gig deixará de aceitar novas ações operacionais.',
        confirmText: 'Encerrar',
      ),
    );

    if (confirmed != true) return;
    await _runPendingAction(_GigDetailPendingAction.closeGig, () async {
      try {
        await ref.read(gigActionsControllerProvider.notifier).closeGig(gigId);
        if (!context.mounted) return;
        AppSnackBar.success(context, 'Gig encerrada.');
      } catch (error) {
        if (!context.mounted) return;
        AppSnackBar.error(context, resolveGigErrorMessage(error));
      }
    });
  }

  Future<void> _confirmCancelGig(BuildContext context, String gigId) async {
    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Cancelar gig?',
        message:
            'As candidaturas serão congeladas e os envolvidos notificados.',
        confirmText: 'Cancelar gig',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;
    await _runPendingAction(_GigDetailPendingAction.cancelGig, () async {
      try {
        await ref.read(gigActionsControllerProvider.notifier).cancelGig(gigId);
        if (!context.mounted) return;
        AppSnackBar.success(context, 'Gig cancelada.');
      } catch (error) {
        if (!context.mounted) return;
        AppSnackBar.error(context, resolveGigErrorMessage(error));
      }
    });
  }

  Future<void> _showEditDescriptionDialog(BuildContext context, Gig gig) async {
    final controller = TextEditingController(text: gig.description);
    final result = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Editar descrição'),
        content: AppTextField(
          controller: controller,
          maxLines: 5,
          minLines: 5,
          label: 'Descrição',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != true) return;
    await _runPendingAction(
      _GigDetailPendingAction.updateDescription,
      () async {
        try {
          await ref
              .read(gigActionsControllerProvider.notifier)
              .updateGig(
                gig.id,
                GigUpdate(description: controller.text.trim()),
              );
          if (!context.mounted) return;
          AppSnackBar.success(context, 'Descrição atualizada.');
        } catch (error) {
          if (!context.mounted) return;
          AppSnackBar.error(context, resolveGigErrorMessage(error));
        }
      },
    );
  }

  Future<void> _runPendingAction(
    _GigDetailPendingAction action,
    Future<void> Function() operation,
  ) async {
    if (_pendingAction != null) return;

    setState(() => _pendingAction = action);
    try {
      await operation();
    } finally {
      if (mounted) {
        setState(() => _pendingAction = null);
      }
    }
  }
}

// ── Header section ────────────────────────────────────────────────────────────

class _GigDetailHeader extends StatelessWidget {
  const _GigDetailHeader({required this.gig, this.creator});

  final Gig gig;
  final AppUser? creator;

  @override
  Widget build(BuildContext context) {
    final accent = gigAccentColor(gig.gigType);
    final accentBarColor = accent.withValues(
      alpha: gig.status == GigStatus.open ? 0.7 : 0.42,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(color: accentBarColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s20,
              AppSpacing.s16,
              AppSpacing.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon + title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: AppRadius.all16,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        gigTypeIcon(gig.gigType),
                        size: 24,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gig.title,
                            style: AppTypography.headlineSmall.copyWith(
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            gig.gigType.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s14),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    GigStatusBadge(status: gig.status),
                    GigCompensationChip(gig: gig),
                  ],
                ),
                if (creator != null) ...[
                  const SizedBox(height: AppSpacing.s16),
                  GigCreatorPreview(creator: creator!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail card ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.all8,
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: valueColor != null
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Divider(color: AppColors.border, height: 1, thickness: 1),
    );
  }
}

// ── Requirements section ──────────────────────────────────────────────────────

class _RequirementsSection extends StatelessWidget {
  const _RequirementsSection({required this.gig, required this.config});

  final Gig gig;
  final dynamic config;

  @override
  Widget build(BuildContext context) {
    final genreLabels = _mapLabels(config.genres, gig.genres);
    final instrumentLabels = _mapLabels(
      config.instruments,
      gig.requiredInstruments,
    );
    final roleLabels = _mapLabels(config.crewRoles, gig.requiredCrewRoles);
    final serviceLabels = _mapLabels(
      config.studioServices,
      gig.requiredStudioServices,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: AppRadius.all8,
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: AppColors.info,
                size: 14,
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            Text(
              'Requisitos',
              style: AppTypography.titleSmall.copyWith(letterSpacing: -0.1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s14),
        _RequirementWrap(title: 'Gêneros', items: genreLabels),
        _RequirementWrap(title: 'Instrumentos', items: instrumentLabels),
        _RequirementWrap(title: 'Funções', items: roleLabels),
        _RequirementWrap(title: 'Serviços', items: serviceLabels),
      ],
    );
  }

  List<String> _mapLabels(List items, List<String> ids) {
    final labelsById = {
      for (final item in items) item.id as String: item.label as String,
    };
    return ids
        .map((id) => labelsById[id] ?? id)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class _RequirementWrap extends StatelessWidget {
  const _RequirementWrap({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: items
                .map((item) => AppChip.skill(label: item))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _RequirementsSectionSkeleton extends StatelessWidget {
  const _RequirementsSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 28, height: 28, borderRadius: AppRadius.r8),
              SizedBox(width: AppSpacing.s10),
              SkeletonText(width: 112, height: 16),
            ],
          ),
          SizedBox(height: AppSpacing.s14),
          SkeletonText(width: 88, height: 12),
          SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              SkeletonBox(width: 92, height: 28, borderRadius: 14),
              SkeletonBox(width: 116, height: 28, borderRadius: 14),
              SkeletonBox(width: 84, height: 28, borderRadius: 14),
            ],
          ),
          SizedBox(height: AppSpacing.s12),
          SkeletonText(width: 96, height: 12),
          SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              SkeletonBox(width: 110, height: 28, borderRadius: 14),
              SkeletonBox(width: 138, height: 28, borderRadius: 14),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action panel ──────────────────────────────────────────────────────────────

class _ActionPanelSection extends ConsumerWidget {
  const _ActionPanelSection({
    required this.gig,
    required this.isCreator,
    required this.myApplication,
    required this.pendingAction,
    required this.onApply,
    required this.onWithdraw,
    required this.onViewApplicants,
    required this.onCloseGig,
    required this.onCancelGig,
    required this.onEdit,
    required this.onEditDescriptionOnly,
  });

  final Gig gig;
  final bool isCreator;
  final GigApplication? myApplication;
  final _GigDetailPendingAction? pendingAction;
  final VoidCallback onApply;
  final VoidCallback onWithdraw;
  final VoidCallback onViewApplicants;
  final VoidCallback onCloseGig;
  final VoidCallback onCancelGig;
  final VoidCallback onEdit;
  final VoidCallback? onEditDescriptionOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ActionPanel(
      gig: gig,
      isCreator: isCreator,
      myApplication: myApplication,
      pendingAction: pendingAction,
      onApply: onApply,
      onWithdraw: myApplication == null ? null : onWithdraw,
      onViewApplicants: onViewApplicants,
      onCloseGig: onCloseGig,
      onCancelGig: onCancelGig,
      onEdit: onEdit,
      onEditDescriptionOnly: onEditDescriptionOnly,
      onOpenChat: () {
        final application = myApplication;
        if (application == null) return;
        final otherUserId = isCreator ? application.applicantId : gig.creatorId;
        ref
            .read(gigActionsControllerProvider.notifier)
            .openConversation(context, otherUserId: otherUserId);
      },
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.gig,
    required this.isCreator,
    required this.myApplication,
    required this.pendingAction,
    required this.onApply,
    required this.onWithdraw,
    required this.onViewApplicants,
    required this.onCloseGig,
    required this.onCancelGig,
    required this.onEdit,
    required this.onEditDescriptionOnly,
    required this.onOpenChat,
  });

  final Gig gig;
  final bool isCreator;
  final GigApplication? myApplication;
  final _GigDetailPendingAction? pendingAction;
  final VoidCallback onApply;
  final VoidCallback? onWithdraw;
  final VoidCallback onViewApplicants;
  final VoidCallback onCloseGig;
  final VoidCallback onCancelGig;
  final VoidCallback onEdit;
  final VoidCallback? onEditDescriptionOnly;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final isBusy = pendingAction != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: _buildContent(isBusy),
    );
  }

  Widget _buildContent(bool isBusy) {
    if (isCreator) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gig.applicantCount > 0) ...[
            Text(
              _candidateSocialProof(gig.applicantCount),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          AppButton.primary(
            text: _creatorApplicantsLabel(gig.applicantCount),
            isFullWidth: true,
            onPressed: isBusy ? null : onViewApplicants,
          ),
          const SizedBox(height: AppSpacing.s10),
          if (gig.canEditAllFields)
            AppButton.outline(
              text: 'Editar gig',
              isFullWidth: true,
              onPressed: isBusy ? null : onEdit,
            )
          else if (onEditDescriptionOnly != null)
            AppButton.outline(
              text: 'Editar descricao',
              isFullWidth: true,
              isLoading:
                  pendingAction == _GigDetailPendingAction.updateDescription,
              onPressed: isBusy ? null : onEditDescriptionOnly,
            ),
          const SizedBox(height: AppSpacing.s10),
          AppButton.secondary(
            text: 'Encerrar gig',
            isFullWidth: true,
            isLoading: pendingAction == _GigDetailPendingAction.closeGig,
            onPressed: isBusy
                ? null
                : (gig.status == GigStatus.open ? onCloseGig : null),
          ),
          const SizedBox(height: AppSpacing.s10),
          AppButton.ghost(
            text: 'Cancelar gig',
            isFullWidth: true,
            isLoading: pendingAction == _GigDetailPendingAction.cancelGig,
            onPressed: isBusy
                ? null
                : (gig.status == GigStatus.cancelled ? null : onCancelGig),
          ),
        ],
      );
    }

    final applicationStatus = myApplication?.status;

    if (applicationStatus == ApplicationStatus.accepted) {
      return Column(
        children: [
          AppButton.primary(
            text: 'Enviar mensagem',
            isFullWidth: true,
            onPressed: isBusy ? null : onOpenChat,
          ),
          const SizedBox(height: AppSpacing.s10),
          AppButton.outline(
            text: 'Desistir da gig',
            isFullWidth: true,
            isLoading: pendingAction == _GigDetailPendingAction.withdraw,
            onPressed: isBusy ? null : onWithdraw,
          ),
        ],
      );
    }

    if (applicationStatus == ApplicationStatus.pending) {
      return Column(
        children: [
          const AppButton.secondary(
            text: 'Candidatura enviada',
            isFullWidth: true,
            onPressed: null,
          ),
          const SizedBox(height: AppSpacing.s10),
          AppButton.outline(
            text: 'Retirar candidatura',
            isFullWidth: true,
            isLoading: pendingAction == _GigDetailPendingAction.withdraw,
            onPressed: isBusy ? null : onWithdraw,
          ),
        ],
      );
    }

    if (applicationStatus == ApplicationStatus.rejected) {
      return const AppButton.secondary(
        text: 'Candidatura recusada',
        isFullWidth: true,
        onPressed: null,
      );
    }

    if (applicationStatus == ApplicationStatus.gigCancelled) {
      return const AppButton.secondary(
        text: 'Gig cancelada',
        isFullWidth: true,
        onPressed: null,
      );
    }

    final canApply = gig.status == GigStatus.open && !gig.isFull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _candidateSocialProof(gig.applicantCount),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        AppButton.primary(
          text: canApply ? 'Candidatar-se' : 'Sem vagas disponíveis',
          isFullWidth: true,
          isLoading: pendingAction == _GigDetailPendingAction.apply,
          onPressed: isBusy ? null : (canApply ? onApply : null),
        ),
      ],
    );
  }

  String _creatorApplicantsLabel(int applicantCount) {
    if (applicantCount == 0) return 'Ver candidaturas';
    if (applicantCount == 1) return 'Ver 1 candidatura';
    return 'Ver $applicantCount candidaturas';
  }

  String _candidateSocialProof(int applicantCount) {
    if (applicantCount <= 0) {
      return 'Seja a primeira pessoa a se candidatar.';
    }
    if (applicantCount == 1) {
      return '1 pessoa ja se candidatou.';
    }
    if (applicantCount <= 25) {
      return '$applicantCount pessoas ja se candidataram.';
    }
    return 'Alta procura: mais de 25 pessoas ja se candidataram.';
  }
}

// ── Skeletons ─────────────────────────────────────────────────────────────────

class _ActionPanelSkeleton extends StatelessWidget {
  const _ActionPanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: const SkeletonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonText(width: 220, height: 12),
            SizedBox(height: AppSpacing.s12),
            SkeletonBox(width: double.infinity, height: 48, borderRadius: 24),
            SizedBox(height: AppSpacing.s10),
            SkeletonBox(width: double.infinity, height: 48, borderRadius: 24),
          ],
        ),
      ),
    );
  }
}

class _GigDetailSkeleton extends StatelessWidget {
  const _GigDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header skeleton with accent bar
        Container(
          decoration: const BoxDecoration(color: AppColors.surface),
          child: Column(
            children: [
              Container(
                height: 3,
                color: AppColors.border.withValues(alpha: 0.4),
              ),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: SkeletonShimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(
                            width: 48,
                            height: 48,
                            borderRadius: AppRadius.r16,
                          ),
                          SizedBox(width: AppSpacing.s14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonText(width: 240, height: 22),
                                SizedBox(height: AppSpacing.s8),
                                SkeletonText(width: 100, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.s14),
                      Row(
                        children: [
                          SkeletonBox(width: 80, height: 26, borderRadius: 13),
                          SizedBox(width: AppSpacing.s8),
                          SkeletonBox(width: 110, height: 26, borderRadius: 13),
                        ],
                      ),
                      SizedBox(height: AppSpacing.s16),
                      SkeletonBox(height: 52, borderRadius: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Column(
            children: [
              _DetailCard(
                child: SkeletonShimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(height: 14),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonText(height: 14),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonText(height: 14),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonText(width: 96, height: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.s12),
              _DetailCard(
                child: SkeletonShimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonBox(
                            width: 28,
                            height: 28,
                            borderRadius: AppRadius.r8,
                          ),
                          SizedBox(width: AppSpacing.s10),
                          SkeletonText(width: 112, height: 16),
                        ],
                      ),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonText(height: 14),
                      SizedBox(height: AppSpacing.s8),
                      SkeletonText(height: 14),
                      SizedBox(height: AppSpacing.s8),
                      SkeletonText(width: 220, height: 14),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.s12),
              _DetailCard(child: _RequirementsSectionSkeleton()),
              SizedBox(height: AppSpacing.s20),
              _ActionPanelSkeleton(),
            ],
          ),
        ),
      ],
    );
  }
}
