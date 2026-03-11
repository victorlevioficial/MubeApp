import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_message_resolver.dart';
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

part 'manage_members_components.dart';
part 'manage_members_search_modal.dart';

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
