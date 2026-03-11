import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../core/errors/error_message_resolver.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/data_display/user_avatar.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../../moderation/data/moderation_repository.dart';

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

typedef _BlockedUsersInitialContent = ({
  firebase_auth.User? authUser,
  List<String> legacyBlockedUsers,
  List<String> blockedIds,
  String idsKey,
  List<AppUser> users,
});

final _blockedUsersInitialContentProvider =
    FutureProvider.autoDispose<_BlockedUsersInitialContent>((ref) async {
      final authUser = await ref.watch(authStateChangesProvider.future);
      if (authUser == null) {
        return (
          authUser: null,
          legacyBlockedUsers: const <String>[],
          blockedIds: const <String>[],
          idsKey: '',
          users: const <AppUser>[],
        );
      }

      final currentUser = await ref.watch(currentUserProfileProvider.future);
      final blockedIds = await ref.watch(blockedUsersProvider.future);
      final legacyBlockedUsers = currentUser?.blockedUsers ?? const <String>[];
      final idsKey = _buildIdsKey({...legacyBlockedUsers, ...blockedIds});
      final users = idsKey.isEmpty
          ? const <AppUser>[]
          : await ref.watch(blockedUsersDetailsByKeyProvider(idsKey).future);

      return (
        authUser: authUser,
        legacyBlockedUsers: legacyBlockedUsers,
        blockedIds: blockedIds,
        idsKey: idsKey,
        users: users,
      );
    });

final _unblockLoadingProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, userId) => false,
);

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialContentAsync = ref.watch(_blockedUsersInitialContentProvider);
    final initialContent = initialContentAsync.value;

    if (initialContentAsync.isLoading && initialContent == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppAppBar(title: 'Usuários Bloqueados'),
        body: Center(child: AppLoadingIndicator()),
      );
    }

    if (initialContentAsync.hasError && initialContent == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppAppBar(title: 'Usuários Bloqueados'),
        body: _BlockedUsersErrorState(
          title: 'Não foi possível carregar usuários bloqueados',
          message: resolveErrorMessage(initialContentAsync.error!),
          onRetry: () => _retryBlockedUsersLoad(ref),
        ),
      );
    }
    final resolvedInitialContent = initialContent!;

    final authAsync = ref.watch(authStateChangesProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final blockedUsersAsync = ref.watch(blockedUsersProvider);
    final authUser = authAsync.value ?? resolvedInitialContent.authUser;
    final legacyBlockedUsers =
        profileAsync.value?.blockedUsers ??
        resolvedInitialContent.legacyBlockedUsers;
    final blockedIds =
        blockedUsersAsync.value ?? resolvedInitialContent.blockedIds;
    final idsKey = _buildIdsKey({...legacyBlockedUsers, ...blockedIds});
    final usersDataAsync = idsKey.isEmpty
        ? const AsyncData<List<AppUser>>(<AppUser>[])
        : ref.watch(blockedUsersDetailsByKeyProvider(idsKey));
    final fallbackUsers = idsKey == resolvedInitialContent.idsKey
        ? resolvedInitialContent.users
        : const <AppUser>[];
    final users = usersDataAsync.value ?? fallbackUsers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Usuários Bloqueados'),
      body: Builder(
        builder: (context) {
          if (authUser == null) {
            return const Center(child: Text('Faça login novamente.'));
          }

          if (blockedUsersAsync.hasError && idsKey.isEmpty) {
            return _BlockedUsersErrorState(
              title: 'Não foi possível carregar usuários bloqueados',
              message: resolveErrorMessage(blockedUsersAsync.error!),
              onRetry: () => _retryBlockedUsersLoad(ref),
            );
          }

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

          if (usersDataAsync.isLoading && users.isEmpty) {
            return const Center(child: AppLoadingIndicator());
          }

          if (usersDataAsync.hasError && users.isEmpty) {
            return _BlockedUsersErrorState(
              title: 'Não foi possível carregar os detalhes dos bloqueios',
              message: resolveErrorMessage(usersDataAsync.error!),
              onRetry: () => _retryBlockedUsersLoad(ref, idsKey: idsKey),
            );
          }

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
              final isLoading = ref.watch(_unblockLoadingProvider(user.uid));
              return ListTile(
                leading: UserAvatar(
                  size: 40,
                  photoUrl: user.foto,
                  name: user.appDisplayName,
                  showBorder: false,
                ),
                title: Text(
                  user.appDisplayName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: AppButton.outline(
                  text: 'Desbloquear',
                  size: AppButtonSize.small,
                  isLoading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () =>
                            _unblockUser(context, ref, authUser.uid, user.uid),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _unblockUser(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    String blockedUserId,
  ) async {
    final loadingNotifier = ref.read(
      _unblockLoadingProvider(blockedUserId).notifier,
    );
    loadingNotifier.state = true;
    try {
      final result = await ref
          .read(moderationRepositoryProvider)
          .unblockUser(
            currentUserId: currentUserId,
            blockedUserId: blockedUserId,
          );

      result.fold(
        (failure) {
          if (context.mounted) {
            AppSnackBar.error(context, failure.message);
          }
        },
        (_) {
          if (context.mounted) {
            AppSnackBar.success(context, 'Usuário desbloqueado');
          }
        },
      );
    } finally {
      loadingNotifier.state = false;
    }
  }

  void _retryBlockedUsersLoad(WidgetRef ref, {String? idsKey}) {
    ref.invalidate(_blockedUsersInitialContentProvider);
    ref.invalidate(blockedUsersProvider);
    final normalizedIdsKey = idsKey?.trim();
    if (normalizedIdsKey != null && normalizedIdsKey.isNotEmpty) {
      ref.invalidate(blockedUsersDetailsByKeyProvider(normalizedIdsKey));
    }
  }
}

class _BlockedUsersErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _BlockedUsersErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: EmptyStateWidget(
          icon: Icons.block_flipped,
          title: title,
          subtitle: message,
          actionButton: AppButton.secondary(
            text: 'Tentar novamente',
            onPressed: onRetry,
          ),
        ),
      ),
    );
  }
}
