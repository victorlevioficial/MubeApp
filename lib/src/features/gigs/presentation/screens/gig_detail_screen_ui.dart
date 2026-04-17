part of 'gig_detail_screen.dart';

extension _GigDetailScreenUi on _GigDetailScreenState {
  Widget _buildGigDetailScreen(BuildContext context) {
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
                    onApply: () => _showApplyDialog(context, gig.id, gig.title),
                    onWithdraw: () => _withdraw(context, myApplication),
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
}
