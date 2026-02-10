import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_skeleton.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../bands/data/invites_repository.dart';

class InvitesScreen extends ConsumerWidget {
  const InvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    if (user == null) {
      return const Scaffold(
        body: SkeletonShimmer(child: UserListSkeleton(itemCount: 4)),
      );
    }

    final invitesAsync = ref.watch(invitesStreamProvider(user.uid));
    final bandsAsync = ref.watch(userBandsProvider(user.uid));

    return Scaffold(
      appBar: const AppAppBar(title: 'Minhas Bandas'),
      backgroundColor: AppColors.background,
      body: invitesAsync.when(
        loading: () => const UserListSkeleton(itemCount: 4),
        error: (err, _) => Center(child: Text('Erro: $err')),
        data: (invites) {
          return bandsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, _) => Center(child: Text('Erro: $err')),
            data: (bands) {
              if (invites.isEmpty && bands.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.music_note_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        'Você ainda não participa de nenhuma banda.',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: AppSpacing.all16,
                children: [
                  if (invites.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Convites Pendentes (${invites.length})',
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    ...invites.map(
                      (invite) => _buildInviteCard(context, ref, invite),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],

                  if (bands.isNotEmpty) ...[
                    _buildSectionHeader('Minhas Bandas (${bands.length})'),
                    const SizedBox(height: AppSpacing.s12),
                    ...bands.map(
                      (band) => _buildBandCard(context, ref, band, user.uid),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _buildInviteCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> invite,
  ) {
    final bandName = invite['band_name'] ?? 'Banda Desconhecida';
    final sentAt = invite['created_at'] != null
        ? (invite['created_at'] as dynamic).toDate()
        : DateTime.now();

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Padding(
        padding: AppSpacing.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: AppRadius.all8,
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Convite para: $bandName',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.buttonPrimary.fontWeight,
                        ),
                      ),
                      Text(
                        'Recebido ${timeago.format(sentAt, locale: 'pt_BR')}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () =>
                          _respond(context, ref, invite['id'], false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textPrimary),
                        foregroundColor: AppColors.textPrimary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.pill,
                        ),
                      ),
                      child: Text(
                        'Recusar',
                        style: AppTypography.buttonSecondary.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.buttonPrimary.fontWeight,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: AppButton.primary(
                      text: 'Aceitar',
                      onPressed: () =>
                          _respond(context, ref, invite['id'], true),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> band,
    String uid,
  ) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      band['foto'] != null && band['foto'].isNotEmpty
                      ? NetworkImage(band['foto'])
                      : null,
                  backgroundColor: AppColors.surfaceHighlight,
                  child: band['foto'] == null || band['foto'].isEmpty
                      ? const Icon(
                          Icons.groups,
                          size: 20,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        band['nome'] ?? band['displayName'] ?? 'Banda',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: AppTypography.buttonPrimary.fontWeight,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Membro',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () =>
                    _confirmLeave(context, ref, band['id'], band['nome']),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.pill,
                  ),
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.exit_to_app, size: 18),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'Sair da banda',
                      style: AppTypography.buttonSecondary.copyWith(
                        color: AppColors.error,
                        fontWeight: AppTypography.buttonPrimary.fontWeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String inviteId,
    bool accept,
  ) async {
    try {
      await ref
          .read(invitesRepositoryProvider)
          .respondToInvite(inviteId: inviteId, accept: accept);
      if (context.mounted) {
        AppSnackBar.success(
          context,
          accept ? 'Bem-vindo à banda!' : 'Convite recusado.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, e.toString(), isError: true);
      }
    }
  }

  void _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    String bandId,
    String? bandName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmationDialog(
        title: 'Sair da Banda?',
        message:
            'Tem certeza que deseja sair de "${bandName ?? 'Banda'}"?\nVocê precisará de um novo convite para entrar novamente.',
        confirmText: 'Sair',
        isDestructive: true,
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final uid = ref.read(currentUserProfileProvider).value!.uid;
        await ref
            .read(invitesRepositoryProvider)
            .leaveBand(bandId: bandId, uid: uid);
        if (context.mounted) {
          AppSnackBar.success(context, 'Você saiu da banda.');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.show(context, e.toString(), isError: true);
        }
      }
    }
  }
}

final invitesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, uid) {
      return ref.watch(invitesRepositoryProvider).getIncomingInvites(uid);
    });
