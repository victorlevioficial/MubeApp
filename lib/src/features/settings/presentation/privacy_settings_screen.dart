import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_skeleton.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../chat/data/chat_repository.dart';
import '../../moderation/data/blocked_users_provider.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Privacidade e Visibilidade'),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          final isActiveMatchpoint =
              user.matchpointProfile?['is_active'] == true;
          final isVisibleHome =
              (user.privacySettings['visible_in_home'] as bool?) ?? true;
          final isChatOpen =
              (user.privacySettings['chat_open'] as bool?) ?? true;

          final totalBlockedCount = {
            ...user.blockedUsers,
            ...?ref.watch(blockedUsersProvider).value,
          }.length;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              _buildSectionHeader('Visibilidade'),
              _buildSwitchTile(
                title: 'Aparecer na Home e Busca',
                subtitle:
                    'Se desativado, seu perfil não aparecerá nas buscas gerais nem no feed.',
                value: isVisibleHome,
                onChanged: (val) async {
                  final notifier = ref.read(authRepositoryProvider);
                  final updatedPrivacy = {
                    ...user.privacySettings,
                    'visible_in_home': val,
                  };
                  await notifier.updateUser(
                    user.copyWith(privacySettings: updatedPrivacy),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'Ativar MatchPoint',
                subtitle:
                    'Se desativado, você não aparecerá para ninguém no MatchPoint e não receberá novos matches.',
                value: isActiveMatchpoint,
                onChanged: (val) async {
                  final notifier = ref.read(authRepositoryProvider);
                  final updatedMatchpoint = {
                    ...user.matchpointProfile ?? {},
                    'is_active': val,
                  };
                  await notifier.updateUser(
                    user.copyWith(matchpointProfile: updatedMatchpoint),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'Chat público',
                subtitle:
                    'Se desativado, novas mensagens de quem ainda não tem vínculo com você irão para Solicitacoes.',
                value: isChatOpen,
                onChanged: (val) async {
                  final notifier = ref.read(authRepositoryProvider);
                  final updatedPrivacy = {
                    ...user.privacySettings,
                    'chat_open': val,
                  };
                  final result = await notifier.updateUser(
                    user.copyWith(privacySettings: updatedPrivacy),
                  );

                  if (!context.mounted) return;

                  if (result.isLeft()) {
                    final failure = result.fold(
                      (failure) => failure,
                      (_) => throw StateError('Expected update failure'),
                    );
                    AppSnackBar.error(
                      context,
                      'Erro ao atualizar privacidade do chat: ${failure.message}',
                    );
                    return;
                  }

                  if (val) {
                    final reevaluateResult = await ref
                        .read(chatRepositoryProvider)
                        .reevaluatePendingConversationsForRecipient(
                          recipientId: user.uid,
                          trigger: 'privacy_settings_public',
                        );
                    if (!context.mounted) return;
                    reevaluateResult.fold(
                      (failure) => AppSnackBar.error(
                        context,
                        'Chat atualizado, mas houve falha ao promover solicitacoes: ${failure.message}',
                      ),
                      (_) => AppSnackBar.success(
                        context,
                        'Privacidade do chat atualizada.',
                      ),
                    );
                    return;
                  }

                  AppSnackBar.success(
                    context,
                    'Privacidade do chat atualizada.',
                  );
                },
              ),
              const Divider(color: AppColors.surfaceHighlight, height: 32),
              _buildSectionHeader('Segurança'),
              ListTile(
                title: Text(
                  'Usuários Bloqueados',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '$totalBlockedCount usuários',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
                onTap: () {
                  context.push(RoutePaths.blockedUsers);
                },
              ),
            ],
          );
        },
        loading: () => const _PrivacySettingsSkeleton(),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: AppSpacing.v8,
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: AppTypography.buttonPrimary.fontWeight,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      trackColor: WidgetStateProperty.resolveWith(
        (states) => AppColors.surfaceHighlight,
      ),
    );
  }
}

class _PrivacySettingsSkeleton extends StatelessWidget {
  const _PrivacySettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: const [
          SkeletonText(width: 110, height: 12),
          SizedBox(height: AppSpacing.s12),
          _PrivacyTileSkeleton(),
          SizedBox(height: AppSpacing.s12),
          _PrivacyTileSkeleton(),
          SizedBox(height: AppSpacing.s16),
          Divider(color: AppColors.surfaceHighlight, height: 32),
          SkeletonText(width: 92, height: 12),
          SizedBox(height: AppSpacing.s12),
          _SecurityTileSkeleton(),
        ],
      ),
    );
  }
}

class _PrivacyTileSkeleton extends StatelessWidget {
  const _PrivacyTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 170, height: 14),
                SizedBox(height: AppSpacing.s8),
                SkeletonText(width: double.infinity, height: 11),
                SizedBox(height: AppSpacing.s4),
                SkeletonText(width: 210, height: 11),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s12),
          SkeletonBox(width: 48, height: 28, borderRadius: AppRadius.rPill),
        ],
      ),
    );
  }
}

class _SecurityTileSkeleton extends StatelessWidget {
  const _SecurityTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 150, height: 14),
                SizedBox(height: AppSpacing.s8),
                SkeletonText(width: 92, height: 12),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s8),
          SkeletonBox(width: 20, height: 20, borderRadius: AppRadius.r8),
        ],
      ),
    );
  }
}
