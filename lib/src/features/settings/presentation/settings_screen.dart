import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_snackbar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import 'widgets/settings_item.dart';

/// Settings screen with configuration options.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Configurações',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Section: Account
          _buildSectionHeader('Conta'),

          SettingsItem(
            icon: Icons.location_on_outlined,
            title: 'Meus Endereços',
            onTap: () => context.push('/settings/addresses'),
          ),

          SettingsItem(
            icon: Icons.person_outline,
            title: 'Editar Dados',
            onTap: () => context.push('/profile/edit'),
          ),

          SettingsItem(
            icon: Icons.favorite_outline,
            title: 'Meus Favoritos',
            onTap: () => context.push('/favorites'),
          ),

          SettingsItem(
            icon: Icons.lock_outline,
            title: 'Alterar Senha',
            onTap: () {
              // TODO: Implement password change
              AppSnackBar.info(context, 'Em breve!');
            },
          ),

          const SizedBox(height: 24),

          // Section: Other
          _buildSectionHeader('Outros'),

          SettingsItem(
            icon: Icons.help_outline,
            title: 'Ajuda e Suporte',
            onTap: () {
              // TODO: Implement help
            },
          ),

          SettingsItem(
            icon: Icons.description_outlined,
            title: 'Termos de Uso',
            onTap: () {
              // TODO: Navigate to terms
            },
          ),

          SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de Privacidade',
            onTap: () {
              // TODO: Navigate to privacy policy
            },
            showDivider: false,
          ),

          const SizedBox(height: 32),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Sair da Conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.surfaceHighlight),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Deactivate account
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => _confirmDeactivate(context, ref),
              child: Text(
                'Desativar Conta',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).signOut();
            },
            child: const Text('Sair', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Desativar conta?'),
        content: const Text(
          'Sua conta e todos os dados serão excluídos permanentemente. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authRepositoryProvider).deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.error(context, 'Erro: $e');
                }
              }
            },
            child: const Text(
              'Desativar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
