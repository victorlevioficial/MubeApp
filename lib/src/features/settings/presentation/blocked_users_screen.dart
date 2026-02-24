import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../feed/presentation/feed_controller.dart';
import '../../matchpoint/presentation/controllers/matchpoint_controller.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../../moderation/data/moderation_repository.dart';
import '../../search/presentation/search_controller.dart' as search_ctrl;

final blockedUsersDetailsByKeyProvider = FutureProvider.autoDispose
    .family<List<AppUser>, String>((ref, String idsKey) async {
      if (idsKey.isEmpty) return <AppUser>[];
      final ids = idsKey.split(',');
      final result = await ref.watch(authRepositoryProvider).getUsersByIds(ids);
      return result.fold((failure) => throw failure.message, (users) => users);
    });

String _buildIdsKey(Iterable<String> ids) {
  final normalized =
      ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList()
        ..sort();
  return normalized.join(',');
}

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta o stream de IDs bloqueados do Firebase
    final blockedUsersAsync = ref.watch(blockedUsersProvider);
    final authUser = ref.watch(authStateChangesProvider).value;
    final legacyBlockedUsers =
        ref.watch(currentUserProfileProvider).value?.blockedUsers ??
        const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Usuários Bloqueados'),
      body: authUser == null
          ? const Center(child: Text('Faça login novamente.'))
          : blockedUsersAsync.when(
              data: (blockedIds) {
                // Merge IDs bloqueados antigos (do doc principal) com os do subcollection
                final combinedIds = {...legacyBlockedUsers, ...blockedIds};

                final idsKey = _buildIdsKey(combinedIds);

                if (idsKey.isEmpty) {
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
                final usersDataAsync = ref.watch(
                  blockedUsersDetailsByKeyProvider(idsKey),
                );

                return usersDataAsync.when(
                  data: (users) {
                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'Os usuários bloqueados não foram encontrados.',
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s8,
                      ),
                      itemCount: users.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: AppColors.surfaceHighlight,
                        height: 1,
                      ),
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
                            onPressed: () => _unblockUser(
                              context,
                              ref,
                              authUser.uid,
                              user.uid,
                            ),
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
    final result = await ref
        .read(moderationRepositoryProvider)
        .unblockUser(
          currentUserId: currentUserId,
          blockedUserId: blockedUserId,
        );

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
        // Recarrega listas afetadas por bloqueio/desbloqueio.
        unawaited(ref.read(feedControllerProvider.notifier).loadAllData());
        ref.invalidate(search_ctrl.searchControllerProvider);
        ref.invalidate(matchpointCandidatesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Usuário desbloqueado')));
        }
      },
    );
  }
}
