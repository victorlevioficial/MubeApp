import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/interactions/app_popup_menu_button.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../feed/domain/feed_item.dart';
import '../../search/data/search_repository.dart';
import '../../search/domain/search_filters.dart';
import '../data/invites_repository.dart';
import '../domain/band_activation_rules.dart';

class _MemberSkeleton extends StatelessWidget {
  const _MemberSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: AppRadius.all4,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Container(
                  width: 88,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: AppRadius.all4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
          ),
        ],
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
    final currentUser = userAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(
        title: 'Gerenciar Integrantes',
        showBackButton: true,
      ),
      bottomNavigationBar: currentUser == null
          ? null
          : _InviteActionBar(
              hasMembers: currentUser.members.isNotEmpty,
              onPressed: () => _showSearchModal(context, currentUser.uid),
            ),
      body: SafeArea(
        top: false,
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const EmptyStateWidget(
                icon: Icons.groups_outlined,
                title: 'Banda não encontrada',
                subtitle: 'Não foi possível carregar os dados da banda agora.',
              );
            }

            final sentInvitesAsync = ref.watch(sentInvitesProvider(user.uid));
            final sentInvites =
                sentInvitesAsync.asData?.value ??
                const <Map<String, dynamic>>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
                176,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BandManagementIntroCard(
                    acceptedMembers: user.members.length,
                    pendingInvites: sentInvites.length,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _buildMembersSection(user),
                  const SizedBox(height: AppSpacing.s16),
                  _SentInvitesList(
                    invites: sentInvites,
                    isLoading:
                        sentInvitesAsync.isLoading && sentInvites.isEmpty,
                    hasError: sentInvitesAsync.hasError && sentInvites.isEmpty,
                  ),
                ],
              ),
            );
          },
          loading: _buildLoadingState,
          error: (err, _) => EmptyStateWidget(
            icon: Icons.error_outline,
            title: 'Não foi possível carregar a banda',
            subtitle: 'Erro: $err',
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        176,
      ),
      children: const [
        _LoadingPanel(height: 172),
        SizedBox(height: AppSpacing.s16),
        _LoadingPanel(height: 228),
        SizedBox(height: AppSpacing.s16),
        _LoadingPanel(height: 188),
      ],
    );
  }

  Widget _buildMembersSection(AppUser user) {
    if (user.members.isEmpty) {
      return _ManagementSectionCard(
        title: 'Integrantes confirmados',
        subtitle:
            'Perfis que já aceitaram o convite e fazem parte da formação atual.',
        trailing: const _SectionCountBadge(label: '0'),
        child: _SectionEmptyState(
          icon: Icons.group_add_outlined,
          title: 'Nenhum integrante confirmado ainda',
          subtitle:
              'Convide pelo menos $minimumBandMembersForActivation integrantes para liberar a visibilidade da banda no app.',
          action: AppButton.secondary(
            text: 'Buscar integrantes',
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
            isFullWidth: true,
            onPressed: () => _showSearchModal(context, user.uid),
          ),
        ),
      );
    }

    final membersAsync = ref.watch(membersListProvider(user.members));

    return _ManagementSectionCard(
      title: 'Integrantes confirmados',
      subtitle:
          'Perfis que já aceitaram o convite e fazem parte da formação atual.',
      trailing: _SectionCountBadge(label: '${user.members.length}'),
      child: membersAsync.when(
        data: (members) => ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.s12),
          itemBuilder: (context, index) => _MemberCard(member: members[index]),
        ),
        loading: () => ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: user.members.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.s12),
          itemBuilder: (context, index) => const _MemberSkeleton(),
        ),
        error: (err, _) => _SectionEmptyState(
          icon: Icons.error_outline,
          title: 'Não foi possível carregar os integrantes',
          subtitle: '$err',
        ),
      ),
    );
  }

  void _showSearchModal(BuildContext context, String myUid) {
    AppOverlay.bottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.top24),
      builder: (context) => _SearchMembersModal(bandId: myUid),
    );
  }
}

class _BandManagementIntroCard extends StatelessWidget {
  const _BandManagementIntroCard({
    required this.acceptedMembers,
    required this.pendingInvites,
  });

  final int acceptedMembers;
  final int pendingInvites;

  @override
  Widget build(BuildContext context) {
    final missingMembers = missingBandMembersForActivation(acceptedMembers);
    final isBandReady = isBandEligibleForActivation(acceptedMembers);
    final subtitle = isBandReady
        ? 'A formação mínima já foi concluída. Acompanhe convites e ajuste integrantes quando precisar.'
        : missingMembers == 1
        ? 'Falta 1 integrante confirmado para ativar a banda e liberar sua visibilidade no app.'
        : 'Faltam $missingMembers integrantes confirmados para ativar a banda e liberar sua visibilidade no app.';

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.all16,
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surface2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  'Formação e convites',
                  style: AppTypography.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Confirmados',
                  value: '$acceptedMembers/$minimumBandMembersForActivation',
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _SummaryMetricTile(
                  label: 'Pendentes',
                  value: '$pendingInvites',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.35),
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteActionBar extends StatelessWidget {
  const _InviteActionBar({required this.hasMembers, required this.onPressed});

  final bool hasMembers;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.surfaceHighlight)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adicionar integrante', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.s4),
            Text(
              hasMembers
                  ? 'Pesquise músicos ativos e envie convites para evoluir a formação da banda.'
                  : 'Comece buscando o primeiro integrante para montar a formação da banda.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            AppButton.primary(
              text: hasMembers
                  ? 'Buscar e convidar integrante'
                  : 'Buscar primeiro integrante',
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              isFullWidth: true,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementSectionCard extends StatelessWidget {
  const _ManagementSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.s12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

class _SectionCountBadge extends StatelessWidget {
  const _SectionCountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.all12,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.s4),
          Text(
            label,
            style: AppTypography.chipLabel.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.s16),
            action!,
          ],
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all4,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Container(
            width: 240,
            height: 14,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all4,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight.withValues(alpha: 0.75),
                borderRadius: AppRadius.all12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentInvitesList extends ConsumerWidget {
  const _SentInvitesList({
    required this.invites,
    required this.isLoading,
    required this.hasError,
  });

  final List<Map<String, dynamic>> invites;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ManagementSectionCard(
      title: 'Convites em andamento',
      subtitle:
          'Acompanhe quem ainda não respondeu e cancele convites se precisar ajustar a formação.',
      trailing: _SectionCountBadge(label: '${invites.length}'),
      child: isLoading
          ? ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) => const _MemberSkeleton(),
            )
          : hasError
          ? const _SectionEmptyState(
              icon: Icons.error_outline,
              title: 'Não foi possível carregar os convites',
              subtitle: 'Tente novamente em instantes.',
            )
          : invites.isEmpty
          ? const _SectionEmptyState(
              icon: Icons.mark_email_unread_outlined,
              title: 'Nenhum convite pendente',
              subtitle:
                  'Quando novos convites forem enviados, eles aparecerão aqui para acompanhamento.',
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invites.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) =>
                  _InviteCard(invite: invites[index]),
            ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  const _InviteCard({required this.invite});

  final Map<String, dynamic> invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetPhoto = invite['target_photo'] as String? ?? '';
    final targetName = invite['target_name'] as String? ?? 'Usuário';
    final targetInstrument = invite['target_instrument'] as String? ?? 'Músico';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.9),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceHighlight,
            backgroundImage: targetPhoto.isNotEmpty
                ? CachedNetworkImageProvider(targetPhoto)
                : null,
            child: targetPhoto.isEmpty
                ? const Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  targetName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.titleSmall.fontWeight,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  targetInstrument,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _StatusBadge(
                label: 'Pendente',
                color: AppColors.info,
                icon: Icons.schedule_rounded,
              ),
              const SizedBox(height: AppSpacing.s8),
              AppButton.ghost(
                text: 'Cancelar',
                size: AppButtonSize.small,
                onPressed: () async {
                  try {
                    final message = await ref
                        .read(invitesRepositoryProvider)
                        .cancelInvite(invite['id']);
                    if (context.mounted) {
                      AppSnackBar.success(context, message);
                    }
                  } catch (_) {
                    if (context.mounted) {
                      AppSnackBar.show(
                        context,
                        'Não foi possível cancelar o convite agora.',
                        isError: true,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({required this.member});

  final AppUser member;

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    String memberName,
  ) async {
    final confirm = await AppOverlay.dialog<bool>(
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

        final message = await ref
            .read(invitesRepositoryProvider)
            .leaveBand(bandId: currentUser.uid, uid: member.uid);

        if (context.mounted) {
          AppSnackBar.success(context, message);
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
    final memberName = member.appDisplayName;
    final instrument =
        member.dadosProfissional?['skills'] is List &&
            (member.dadosProfissional!['skills'] as List).isNotEmpty
        ? (member.dadosProfissional!['skills'] as List).first as String
        : 'Membro';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.9),
        ),
      ),
      child: InkWell(
        onTap: () => context.push(RoutePaths.publicProfileById(member.uid)),
        borderRadius: AppRadius.all16,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceHighlight,
                backgroundImage: member.foto != null && member.foto!.isNotEmpty
                    ? CachedNetworkImageProvider(member.foto!)
                    : null,
                child: (member.foto == null || member.foto!.isEmpty)
                    ? const Icon(
                        Icons.person_outline,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppTypography.titleSmall.fontWeight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      instrument,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              const _StatusBadge(
                label: 'Confirmado',
                color: AppColors.success,
                icon: Icons.check_circle_outline_rounded,
              ),
              AppPopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textSecondary,
                ),
                menuColor: AppColors.surfaceHighlight,
                onSelected: (value) async {
                  if (value == 'profile') {
                    unawaited(
                      context.push(RoutePaths.publicProfileById(member.uid)),
                    );
                  } else if (value == 'remove') {
                    await _confirmRemoveMember(context, ref, memberName);
                  }
                },
                items: const [
                  AppPopupMenuAction<String>(
                    value: 'profile',
                    label: 'Ver Perfil',
                    icon: Icons.person_outline,
                  ),
                  AppPopupMenuAction<String>(
                    value: 'remove',
                    label: 'Remover da Banda',
                    icon: Icons.logout,
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
