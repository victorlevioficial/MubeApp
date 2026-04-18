part of 'gig_detail_screen.dart';

// ── Header section ────────────────────────────────────────────────────────────

class _GigApplyDialog extends StatefulWidget {
  const _GigApplyDialog();

  @override
  State<_GigApplyDialog> createState() => _GigApplyDialogState();
}

class _GigApplyDialogState extends State<_GigApplyDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: AppRadius.all24,
              border: Border.all(color: AppColors.surfaceHighlight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.background.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  final hasMessage = value.text.trim().isNotEmpty;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: AppRadius.all16,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.s10,
                                    vertical: AppSpacing.s4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: AppRadius.pill,
                                  ),
                                  child: Text(
                                    'Candidatura rápida',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s10),
                                Text(
                                  'Enviar candidatura',
                                  style: AppTypography.headlineSmall,
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                Text(
                                  'Destaque sua experiência, repertório e disponibilidade para o contratante.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          IconButton(
                            tooltip: 'Fechar',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.all16,
                          border: Border.all(color: AppColors.surfaceHighlight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vale incluir',
                              style: AppTypography.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.s10),
                            const Wrap(
                              spacing: AppSpacing.s8,
                              runSpacing: AppSpacing.s8,
                              children: [
                                AppChip.skill(label: 'Experiência'),
                                AppChip.skill(label: 'Disponibilidade'),
                                AppChip.skill(label: 'Repertório'),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s12),
                            Text(
                              hasMessage
                                  ? 'Sua mensagem está pronta para envio.'
                                  : 'Uma mensagem objetiva ajuda o contratante a responder mais rápido.',
                              style: AppTypography.bodySmall.copyWith(
                                color: hasMessage
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s20),
                      AppTextField(
                        controller: _controller,
                        label: 'Mensagem para o contratante',
                        hint:
                            'Ex.: Tenho experiência com eventos ao vivo, equipamento próprio e disponibilidade para ensaios e show.',
                        minLines: 5,
                        maxLines: 6,
                        maxLength: 280,
                        textCapitalization: TextCapitalization.sentences,
                        scrollPadding: const EdgeInsets.only(
                          left: AppSpacing.s16,
                          right: AppSpacing.s16,
                          top: AppSpacing.s16,
                          bottom: 120,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: Text(
                              'Sua candidatura vai aparecer em Minhas candidaturas assim que for enviada.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              text: 'Cancelar',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: AppButton.primary(
                              text: 'Enviar',
                              icon: const Icon(Icons.send_rounded, size: 18),
                              onPressed: hasMessage
                                  ? () => Navigator.of(
                                      context,
                                    ).pop(_controller.text.trim())
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final queuedApplication =
        myApplication != null && myApplication!.id.startsWith('queued:');

    return _ActionPanel(
      gig: gig,
      isCreator: isCreator,
      myApplication: myApplication,
      isQueuedApplication: queuedApplication,
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
    required this.isQueuedApplication,
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
  final bool isQueuedApplication;
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
          AppButton.secondary(
            text: isQueuedApplication
                ? 'Envio pendente (offline)'
                : 'Candidatura enviada',
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
      return '1 pessoa já se candidatou.';
    }
    if (applicantCount <= 25) {
      return '$applicantCount pessoas já se candidataram.';
    }
    return 'Alta procura: mais de 25 pessoas já se candidataram.';
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
