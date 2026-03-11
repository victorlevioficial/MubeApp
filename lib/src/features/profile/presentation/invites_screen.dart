import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/errors/error_message_resolver.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/data_display/user_avatar.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/components/loading/app_skeleton.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../bands/data/invites_repository.dart';

typedef _InvitesInitialContent = ({
  List<Map<String, dynamic>> invites,
  List<Map<String, dynamic>> bands,
});

enum _InviteAction { accept, decline }

final _invitesInitialContentProvider = FutureProvider.autoDispose
    .family<_InvitesInitialContent, String>((ref, uid) async {
      final invites = await ref.watch(invitesStreamProvider(uid).future);
      final bands = await ref.watch(userBandsProvider(uid).future);
      return (invites: invites, bands: bands);
    });

final _inviteActionProvider = StateProvider.autoDispose
    .family<_InviteAction?, String>((ref, inviteId) => null);

final _leaveBandLoadingProvider = StateProvider.autoDispose
    .family<bool, String>((ref, bandId) => false);

class InvitesScreen extends ConsumerWidget {
  const InvitesScreen({super.key});

  String _bandDisplayName(Map<String, dynamic> band) {
    final bandData = band['banda'] as Map<String, dynamic>? ?? const {};

    for (final candidate in [
      bandData['nomeBanda'],
      bandData['nomeArtistico'],
      bandData['nome'],
    ]) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return 'Banda';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    if (user == null) {
      if (!userAsync.isLoading) {
        return const Scaffold(
          body: Center(child: Text('Faça login novamente.')),
        );
      }
      return const Scaffold(
        body: SkeletonShimmer(child: UserListSkeleton(itemCount: 4)),
      );
    }

    final initialContentAsync = ref.watch(
      _invitesInitialContentProvider(user.uid),
    );
    final initialContent = initialContentAsync.value;
    if (initialContentAsync.isLoading && initialContent == null) {
      return const Scaffold(
        appBar: AppAppBar(title: 'Minhas Bandas'),
        backgroundColor: AppColors.background,
        body: SkeletonShimmer(child: UserListSkeleton(itemCount: 4)),
      );
    }
    if (initialContentAsync.hasError && initialContent == null) {
      return Scaffold(
        appBar: const AppAppBar(title: 'Minhas Bandas'),
        backgroundColor: AppColors.background,
        body: _buildErrorState(
          ref,
          user.uid,
          initialContentAsync.error!,
          title: 'Nao foi possivel carregar convites e bandas',
        ),
      );
    }
    final resolvedInitialContent = initialContent!;

    final invitesAsync = ref.watch(invitesStreamProvider(user.uid));
    final bandsAsync = ref.watch(userBandsProvider(user.uid));
    final invites = invitesAsync.value ?? resolvedInitialContent.invites;
    final bands = bandsAsync.value ?? resolvedInitialContent.bands;

    return Scaffold(
      appBar: const AppAppBar(title: 'Minhas Bandas'),
      backgroundColor: AppColors.background,
      body: Builder(
        builder: (context) {
          if (invitesAsync.hasError && invites.isEmpty) {
            return _buildErrorState(
              ref,
              user.uid,
              invitesAsync.error!,
              title: 'Nao foi possivel carregar seus convites',
            );
          }
          if (bandsAsync.hasError && bands.isEmpty) {
            return _buildErrorState(
              ref,
              user.uid,
              bandsAsync.error!,
              title: 'Nao foi possivel carregar suas bandas',
            );
          }
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
                _buildSectionHeader('Convites Pendentes (${invites.length})'),
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
      ),
    );
  }

  Widget _buildErrorState(
    WidgetRef ref,
    String uid,
    Object error, {
    required String title,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: EmptyStateWidget(
          icon: Icons.cloud_off_rounded,
          title: title,
          subtitle: resolveErrorMessage(error),
          actionButton: AppButton.secondary(
            text: 'Tentar novamente',
            onPressed: () {
              ref.invalidate(_invitesInitialContentProvider(uid));
              ref.invalidate(invitesStreamProvider(uid));
              ref.invalidate(userBandsProvider(uid));
            },
          ),
        ),
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
    final inviteId = invite['id'] as String;
    final action = ref.watch(_inviteActionProvider(inviteId));
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
                    child: AppButton.outline(
                      text: 'Recusar',
                      isLoading: action == _InviteAction.decline,
                      onPressed: action == null
                          ? () => _respond(
                              context,
                              ref,
                              inviteId,
                              _InviteAction.decline,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: AppButton.primary(
                      text: 'Aceitar',
                      isLoading: action == _InviteAction.accept,
                      onPressed: action == null
                          ? () => _respond(
                              context,
                              ref,
                              inviteId,
                              _InviteAction.accept,
                            )
                          : null,
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
    final bandId = band['id'] as String;
    final isLeaving = ref.watch(_leaveBandLoadingProvider(bandId));
    final bandName = _bandDisplayName(band);
    final photoUrl = band['foto'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

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
                  backgroundColor: AppColors.surfaceHighlight,
                  child: hasPhoto
                      ? UserAvatar(
                          size: 40,
                          photoUrl: photoUrl,
                          name: bandName,
                          showBorder: false,
                        )
                      : const Icon(
                          Icons.groups,
                          size: 20,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bandName,
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
                onPressed: isLeaving
                    ? null
                    : () => _confirmLeave(context, ref, bandId, bandName),
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
                    if (isLeaving) ...[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                    ] else ...[
                      const Icon(Icons.exit_to_app, size: 18),
                      const SizedBox(width: AppSpacing.s8),
                    ],
                    Text(
                      isLeaving ? 'Saindo...' : 'Sair da banda',
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
    _InviteAction action,
  ) async {
    final notifier = ref.read(_inviteActionProvider(inviteId).notifier);
    notifier.state = action;
    try {
      final message = await ref
          .read(invitesRepositoryProvider)
          .respondToInvite(
            inviteId: inviteId,
            accept: action == _InviteAction.accept,
          );
      if (context.mounted) {
        AppSnackBar.success(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, resolveErrorMessage(e));
      }
    } finally {
      notifier.state = null;
    }
  }

  void _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    String bandId,
    String? bandName,
  ) async {
    final confirm = await AppOverlay.dialog<bool>(
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
      final loadingNotifier = ref.read(
        _leaveBandLoadingProvider(bandId).notifier,
      );
      loadingNotifier.state = true;
      try {
        final uid = ref.read(currentUserProfileProvider).value!.uid;
        final message = await ref
            .read(invitesRepositoryProvider)
            .leaveBand(bandId: bandId, uid: uid);
        if (context.mounted) {
          AppSnackBar.success(context, message);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, resolveErrorMessage(e));
        }
      } finally {
        loadingNotifier.state = false;
      }
    }
  }
}

final invitesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, uid) {
      return ref.watch(invitesRepositoryProvider).getIncomingInvites(uid);
    });
