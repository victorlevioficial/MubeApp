import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../../moderation/data/moderation_repository.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta o stream de IDs bloqueados do Firebase
    final blockedUsersAsync = ref.watch(blockedUsersProvider);
    final currentUserAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Usuários Bloqueados'),
      body: blockedUsersAsync.when(
        data: (blockedIds) {
          final currentUser = currentUserAsync.value;

          if (currentUser == null) {
            return const Center(child: Text('Erro ao carregar seu perfil.'));
          }

          // Merge IDs bloqueados antigos (do doc principal) com os do subcollection
          final combinedIds = {
            ...currentUser.blockedUsers,
            ...blockedIds,
          }.toList();

          if (combinedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.block,
                    size: 64,
                    color: AppColors.surfaceHighlight,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Nenhum usuário bloqueado',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Busca os dados completos dos usuários baseado na lista de IDs
          final usersDataAsync = ref.watch(membersListProvider(combinedIds));

          return usersDataAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const Center(
                  child: Text('Os usuários bloqueados não foram encontrados.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                itemCount: users.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: AppColors.surfaceHighlight, height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          user.foto != null && user.foto!.isNotEmpty
                          ? NetworkImage(user.foto!)
                          : null,
                      child: user.foto == null || user.foto!.isEmpty
                          ? Text(
                              user.appDisplayName.isNotEmpty
                                  ? user.appDisplayName[0].toUpperCase()
                                  : '?',
                            )
                          : null,
                    ),
                    title: Text(
                      user.appDisplayName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                          color: AppColors.surfaceHighlight,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: () =>
                          _unblockUser(context, ref, currentUser.uid, user.uid),
                      child: Text(
                        'Desbloquear',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erro: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Future<void> _unblockUser(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    String blockedUserId,
  ) async {
    // Mostra loading
    // ignore: unawaited_futures
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ref
        .read(moderationRepositoryProvider)
        .unblockUser(
          currentUserId: currentUserId,
          blockedUserId: blockedUserId,
        );

    // Remove loading
    if (context.mounted) Navigator.of(context).pop();

    result.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      (_) {
        // Sucesso - Além de remover da collection 'blocked',
        // remover também do array 'blockedUsers' legado se existir.
        // ignore: unawaited_futures
        _removeLegacyBlock(ref, currentUserId, blockedUserId);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Usuário desbloqueado')));
        }
      },
    );
  }

  Future<void> _removeLegacyBlock(
    WidgetRef ref,
    String currentUserId,
    String blockedUserId,
  ) async {
    final authNotif = ref.read(authRepositoryProvider);
    final user = authNotif.currentUser;
    if (user != null) {
      // O provider 'currentUserProfileProvider' escuta as mudanças no firestore,
      // então ideal é pegar o AppUser
      final appUser = ref.read(currentUserProfileProvider).value;
      if (appUser != null && appUser.blockedUsers.contains(blockedUserId)) {
        final updatedBlocked = List<String>.from(appUser.blockedUsers)
          ..remove(blockedUserId);
        await authNotif.updateUser(
          appUser.copyWith(blockedUsers: updatedBlocked),
        );
      }
    }
  }
}
