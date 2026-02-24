import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
