import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_confirmation_dialog.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../feed/domain/feed_item.dart';
import '../../search/data/search_repository.dart';
import '../../search/domain/search_filters.dart';
import '../data/invites_repository.dart';

// Helper for UI polishing - Skeleton
class _MemberSkeleton extends StatelessWidget {
  const _MemberSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.surfaceHighlight,
            shape: BoxShape.circle,
          ),
        ),
        title: Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          width: 80,
          height: 12,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class ManageMembersScreen extends ConsumerStatefulWidget {
  const ManageMembersScreen({super.key});

  @override
  ConsumerState<ManageMembersScreen> createState() =>
      _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: const MubeAppBar(title: 'Gerenciar Integrantes'),
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brandPrimary, // More distinct primary color
        child: const Icon(Icons.person_add, color: AppColors.textPrimary),
        onPressed: () {
          final user = userAsync.value;
          if (user != null) {
            _showSearchModal(context, user.uid);
          }
        },
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          return SingleChildScrollView(
            padding: AppSpacing.all16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user.members.isEmpty) ...[
                  // Empty State Inline
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          'Você ainda não tem integrantes.',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          'Convide músicos para ativar sua banda!',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text('Integrantes', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.s12),
                  ref
                      .watch(membersListProvider(user.members))
                      .when(
                        data: (members) => Column(
                          children: members
                              .map((m) => _MemberCard(member: m))
                              .toList(),
                        ),
                        loading: () => ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: user.members.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.s12),
                          itemBuilder: (context, index) =>
                              const _MemberSkeleton(),
                        ),
                        error: (err, st) =>
                            Text('Erro ao carregar membros: $err'),
                      ),
                ],
                const SizedBox(height: AppSpacing.s24),
                _SentInvitesList(bandId: user.uid),
              ],
            ),
          );
        },
        // Fancy Skeleton Loading
        loading: () => ListView.separated(
          padding: AppSpacing.all16,
          itemCount: 3,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.s12),
          itemBuilder: (context, index) => const _MemberSkeleton(),
        ),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  void _showSearchModal(BuildContext context, String myUid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background, // Darker background as requested
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SearchMembersModal(bandId: myUid),
    );
  }
}

class _SentInvitesList extends ConsumerWidget {
  final String bandId;
  const _SentInvitesList({required this.bandId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref
        .watch(invitesRepositoryProvider)
        .getSentInvites(bandId);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: invitesAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final invites = snapshot.data!;
        if (invites.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Text(
                'Convites Enviados',
                style: AppTypography.titleMedium,
              ),
            ),
            ...invites.map(
              (invite) => Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: AppSpacing.s12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        backgroundImage:
                            invite['target_photo'] != null &&
                                invite['target_photo'].isNotEmpty
                            ? CachedNetworkImageProvider(invite['target_photo'])
                            : null,
                        backgroundColor: AppColors.surfaceHighlight,
                        radius: 20,
                        child: invite['target_photo']?.isEmpty ?? true
                            ? const Icon(
                                Icons.person,
                                color: AppColors.textSecondary,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.s12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              invite['target_name'] ?? 'Usuário',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              invite['target_instrument'] ?? 'Músico',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Status & Action
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHighlight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Aguardando',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              try {
                                await ref
                                    .read(invitesRepositoryProvider)
                                    .cancelInvite(invite['id']);
                                if (context.mounted) {
                                  AppSnackBar.success(
                                    context,
                                    'Convite cancelado',
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppSnackBar.show(
                                    context,
                                    'Erro ao cancelar',
                                    isError: true,
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cancelar',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemberCard extends ConsumerWidget {
  final AppUser member;
  const _MemberCard({required this.member});

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    String memberName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: 'Remover Integrante',
        message: 'Tem certeza que deseja remover $memberName da banda?',
        confirmText: 'Remover',
        isDestructive: true,
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final currentUser = ref.read(currentUserProfileProvider).value;
        if (currentUser == null) return;

        // Use 'leaveBand' logic: Band (owner) removes Member (uid) from self
        await ref
            .read(invitesRepositoryProvider)
            .leaveBand(bandId: currentUser.uid, uid: member.uid);

        if (context.mounted) {
          AppSnackBar.success(context, '$memberName removido da banda.');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.show(context, 'Erro ao remover: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instrument =
        member.dadosProfissional?['skills'] is List &&
            (member.dadosProfissional!['skills'] as List).isNotEmpty
        ? (member.dadosProfissional!['skills'] as List).first as String
        : 'Membro';

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/user/${member.uid}'),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceHighlight,
            backgroundImage: member.foto != null && member.foto!.isNotEmpty
                ? CachedNetworkImageProvider(member.foto!)
                : null,
            radius: 20,
            child: (member.foto == null || member.foto!.isEmpty)
                ? const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 20,
                  )
                : null,
          ),
          title: Text(
            member.nome ?? 'Sem nome',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            instrument,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            color: AppColors.surfaceHighlight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                unawaited(context.push('/user/${member.uid}'));
              } else if (value == 'remove') {
                await _confirmRemoveMember(
                  context,
                  ref,
                  member.nome ?? 'Membro',
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text('Ver Perfil', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Remover da Banda',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchMembersModal extends ConsumerStatefulWidget {
  final String bandId;
  const _SearchMembersModal({required this.bandId});

  @override
  ConsumerState<_SearchMembersModal> createState() =>
      _SearchMembersModalState();
}

class _SearchMembersModalState extends ConsumerState<_SearchMembersModal> {
  final _searchController = TextEditingController();
  List<FeedItem> _results = [];
  bool _isLoading = false;

  void _search(String term) async {
    if (term.length < 3) return;

    setState(() => _isLoading = true);

    final repo = ref.read(searchRepositoryProvider);
    int reqId = 0;

    final result = await repo.searchUsers(
      filters: SearchFilters(
        term: term,
        category: SearchCategory.professionals, // Only musicians
      ),
      requestId: ++reqId,
      getCurrentRequestId: () => reqId,
    );

    result.fold(
      (l) => AppSnackBar.show(context, 'Erro ao buscar', isError: true),
      (r) {
        if (mounted) setState(() => _results = r);
      },
    );

    if (mounted) setState(() => _isLoading = false);
  }

  void _invite(FeedItem item) async {
    final uid = item.uid;
    try {
      await ref
          .read(invitesRepositoryProvider)
          .sendInvite(
            bandId: widget.bandId,
            targetUid: uid,
            targetName: item.displayName,
            targetPhoto: item.foto ?? '',
            targetInstrument: item.skills.isNotEmpty ? item.skills.first : '',
          );
      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.success(context, 'Convite enviado com sucesso!');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, e.toString(), isError: true);
    }
  }

  Widget _buildResultItem(FeedItem item, List<String> pendingInviteUids) {
    final isInvited = pendingInviteUids.contains(item.uid);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceHighlight,
              backgroundImage: item.foto != null && item.foto!.isNotEmpty
                  ? CachedNetworkImageProvider(item.foto!)
                  : null,
              child: (item.foto == null || item.foto!.isEmpty)
                  ? const Icon(Icons.person, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.s12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.skills.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.skills.take(3).join(', '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),

            // Action Button
            SizedBox(
              height: 32,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 80, maxWidth: 100),
                child: isInvited
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceHighlight,
                          disabledBackgroundColor: AppColors.surfaceHighlight,
                          disabledForegroundColor: AppColors.textTertiary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Aguardando',
                          style: TextStyle(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _invite(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Convidar',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch sent invites to filter search results status
    final invitesAsync = ref.watch(sentInvitesProvider(widget.bandId));

    // Extract pending UIDs safely
    final List<String> pendingUids =
        invitesAsync.asData?.value
            .map((inv) => inv['target_uid'] as String)
            .toList() ??
        [];

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.s16,
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        bottom: keyboardHeight + AppSpacing.s16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.7, // Max 70% of screen
          minHeight: screenHeight * 0.4, // Min 40%
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content
          children: [
            Text(
              'Convidar Integrante',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              controller: _searchController,
              label: '',
              hint: 'Busque por nome, instrumento...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              onChanged: (v) => _search(v),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Busque músicos para sua banda',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.s8),
                      itemBuilder: (context, index) {
                        return _buildResultItem(_results[index], pendingUids);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} // End SearchMembersModal
