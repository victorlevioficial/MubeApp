part of 'manage_members_screen.dart';

class _SearchMembersModal extends ConsumerStatefulWidget {
  const _SearchMembersModal({required this.bandId});

  final String bandId;

  @override
  ConsumerState<_SearchMembersModal> createState() =>
      _SearchMembersModalState();
}

class _SearchMembersModalState extends ConsumerState<_SearchMembersModal> {
  final _searchController = TextEditingController();

  List<FeedItem> _results = const [];
  bool _isLoading = false;
  String? _invitingUid;
  int _searchRequestId = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _inviteErrorMessage(Object error) {
    const exceptionPrefix = 'Exception: ';
    final message = error.toString().trim();
    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length).trim();
    }
    return message.isEmpty
        ? 'Não foi possível enviar o convite agora.'
        : message;
  }

  Future<void> _search(String term) async {
    final normalizedTerm = term.trim();
    if (normalizedTerm.length < 3) {
      _searchRequestId++;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _results = const [];
      });
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() => _isLoading = true);

    final repo = ref.read(searchRepositoryProvider);
    final result = await repo.searchUsers(
      filters: SearchFilters(
        term: normalizedTerm,
        category: SearchCategory.professionals,
      ),
      requestId: requestId,
      getCurrentRequestId: () => _searchRequestId,
    );

    if (!mounted || requestId != _searchRequestId) return;

    result.fold(
      (_) {
        setState(() {
          _isLoading = false;
          _results = const [];
        });
        AppSnackBar.show(
          context,
          'Não foi possível buscar perfis agora.',
          isError: true,
        );
      },
      (response) {
        setState(() {
          _isLoading = false;
          _results = response.items;
        });
      },
    );
  }

  Future<void> _invite(FeedItem item) async {
    final uid = item.uid;
    if (_invitingUid != null) return;

    setState(() => _invitingUid = uid);
    try {
      final message = await ref
          .read(invitesRepositoryProvider)
          .sendInvite(
            bandId: widget.bandId,
            targetUid: uid,
            targetName: item.displayName,
            targetPhoto: item.foto ?? '',
            targetInstrument: item.skills.isNotEmpty ? item.skills.first : '',
          );
      if (mounted) {
        AppSnackBar.success(context, message);
        Navigator.pop(context);
      }
    } catch (e, stack) {
      AppLogger.error('Falha ao enviar convite para ${item.uid}', e, stack);
      if (mounted) {
        AppSnackBar.show(context, _inviteErrorMessage(e), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _invitingUid = null);
      }
    }
  }

  Widget _buildResultItem(FeedItem item, List<String> pendingInviteUids) {
    final isInvited = pendingInviteUids.contains(item.uid);
    final isInviting = _invitingUid == item.uid;
    final skills = item.skills.isNotEmpty
        ? item.skills.take(3).join(', ')
        : 'Perfil profissional';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceHighlight,
            backgroundImage: item.foto != null && item.foto!.isNotEmpty
                ? CachedNetworkImageProvider(item.foto!)
                : null,
            child: (item.foto == null || item.foto!.isEmpty)
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.titleSmall.fontWeight,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  skills,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          SizedBox(
            width: 104,
            child: isInvited
                ? const AppButton.secondary(
                    onPressed: null,
                    text: 'Pendente',
                    size: AppButtonSize.small,
                  )
                : AppButton.primary(
                    onPressed: isInviting ? null : () => _invite(item),
                    text: isInviting ? 'Enviando' : 'Convidar',
                    size: AppButtonSize.small,
                    isLoading: isInviting,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(sentInvitesProvider(widget.bandId));
    final pendingUids =
        invitesAsync.asData?.value
            .map((inv) => inv['target_uid'] as String)
            .toList() ??
        const <String>[];
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasSearchQuery = _searchController.text.trim().length >= 3;

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.s16,
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        bottom: keyboardHeight + AppSpacing.s16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.78,
          minHeight: screenHeight * 0.46,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Convidar integrante',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Encontre perfis profissionais ativos para enviar um convite diretamente para a banda.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              controller: _searchController,
              label: 'Buscar integrante',
              hint: 'Nome ou instrumento',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              onChanged: _search,
            ),
            const SizedBox(height: AppSpacing.s16),
            Expanded(
              child: _isLoading
                  ? ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: 4,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (context, index) => const _MemberSkeleton(),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: _SectionEmptyState(
                          icon: hasSearchQuery
                              ? Icons.search_off_outlined
                              : Icons.search_rounded,
                          title: hasSearchQuery
                              ? 'Nenhum perfil encontrado'
                              : 'Busque musicos para sua banda',
                          subtitle: hasSearchQuery
                              ? 'Tente outro nome ou instrumento para ampliar a busca.'
                              : 'Digite pelo menos 3 caracteres para pesquisar por nome ou instrumento.',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (context, index) =>
                          _buildResultItem(_results[index], pendingUids),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
