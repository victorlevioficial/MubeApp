import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_confirmation_dialog.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../core/data/app_seeder.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../../design_system/showcase/design_system_showcase_screen.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_type.dart';
import 'widgets/bento_header.dart';
import 'widgets/neon_settings_tile.dart';
import 'widgets/settings_group.dart';

/// Settings screen with "Option A" Bento Grid Redesign
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MubeAppBar(title: 'Configurações', showBackButton: false),
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 1. DASHBOARD HEADER (BENTO)
            const BentoHeader(),

            const SizedBox(height: 32),

            // 2. SETTINGS GROUPS
            SettingsGroup(
              title: 'CONTA',
              children: [
                NeonSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Meus Endereços',
                  subtitle: 'Gerenciar entregas',
                  onTap: () => context.push('/settings/addresses'),
                  customAccentColor: Colors.blueAccent,
                ),
                NeonSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Editar Dados',
                  onTap: () => context.push('/profile/edit'),
                  customAccentColor: Colors.purpleAccent,
                ),
                NeonSettingsTile(
                  icon: Icons.favorite_outline,
                  title: 'Meus Favoritos',
                  onTap: () => context.push('/favorites'),
                  customAccentColor: AppColors.brandPrimary,
                ),
                // Dynamic Tile: Band Management or My Bands
                if (ref.watch(currentUserProfileProvider).value?.tipoPerfil ==
                    AppUserType.band)
                  NeonSettingsTile(
                    icon: Icons.groups_outlined,
                    title: 'Gerenciar Banda',
                    subtitle: 'Integrantes e convites',
                    onTap: () => context.push(RoutePaths.invites),
                    customAccentColor: Colors.pinkAccent,
                  )
                else
                  NeonSettingsTile(
                    icon: Icons.mail_outline,
                    title: 'Minhas Bandas',
                    subtitle: 'Convites e parcerias',
                    onTap: () => context.push(RoutePaths.invites),
                    customAccentColor: Colors.pinkAccent,
                  ),
                NeonSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Alterar Senha',
                  onTap: () => AppSnackBar.info(context, 'Em breve!'),
                  customAccentColor: Colors.orangeAccent,
                ),
              ],
            ),

            SettingsGroup(
              title: 'OUTROS',
              children: [
                NeonSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Ajuda e Suporte',
                  onTap: () {},
                  customAccentColor: Colors.tealAccent,
                ),
                NeonSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Termos de Uso',
                  onTap: () {},
                  customAccentColor: Colors.grey,
                ),
                NeonSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidade',
                  onTap: () {},
                  customAccentColor: Colors.grey,
                ),
              ],
            ),

            if (kDebugMode)
              SettingsGroup(
                title: 'DEV ZONE',
                children: [
                  NeonSettingsTile(
                    icon: Icons.build_circle_outlined,
                    title: 'Manutenção (Dev)',
                    onTap: () => context.push(RoutePaths.maintenance),
                    customAccentColor: Colors.white,
                  ),
                  NeonSettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Design System',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DesignSystemShowcaseScreen(),
                        ),
                      );
                    },
                    customAccentColor: Colors.pink,
                  ),
                  NeonSettingsTile(
                    icon: Icons.groups_outlined,
                    title: 'Popular Banco (MatchPoint)',
                    subtitle: 'Gerar 150 perfis diversos',
                    onTap: () => _seedDatabase(context, ref),
                    customAccentColor: Colors.greenAccent,
                  ),
                  NeonSettingsTile(
                    icon: Icons.settings_input_component,
                    title: 'Seed App Config',
                    subtitle: 'Resetar listas (Gêneros/Inst.)',
                    onTap: () => _seedAppConfig(context, ref),
                    customAccentColor: Colors.cyanAccent,
                  ),
                  NeonSettingsTile(
                    icon: Icons.delete_sweep_outlined,
                    title: 'Limpar Perfis Fake',
                    subtitle: 'Deletar usuários do seeder',
                    onTap: () => _deleteSeededUsers(context, ref),
                    customAccentColor: Colors.redAccent,
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // 3. ACTION BUTTONS (Logout / Delete)
            _buildLogoutButton(context, ref),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => _confirmDeactivate(context, ref),
              child: Text(
                'Desativar Conta',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error.withValues(alpha: 0.7),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmLogout(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sair da Conta',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Sair da conta?',
        message: 'Você precisará fazer login novamente.',
        confirmText: 'Sair',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      unawaited(ref.read(authRepositoryProvider).signOut());
    }
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Desativar conta?',
        message:
            'Sua conta e todos os dados serão excluídos permanentemente. '
            'Esta ação não pode ser desfeita.',
        confirmText: 'Desativar',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(authRepositoryProvider).deleteAccount();
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, 'Erro: $e');
        }
      }
    }
  }

  void _seedDatabase(BuildContext context, WidgetRef ref) async {
    AppSnackBar.info(context, 'Iniciando população do banco...');

    try {
      final seeder = ref.read(appSeederProvider);
      final count = await seeder.seedUsers(count: 150);
      if (context.mounted) {
        AppSnackBar.success(context, '✅ $count usuários criados!');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Erro ao popular: $e');
      }
    }
  }

  void _seedAppConfig(BuildContext context, WidgetRef ref) async {
    AppSnackBar.info(context, 'Gravando configurações...');

    try {
      await ref.read(appSeederProvider).seedAppConfig();
      if (context.mounted) {
        AppSnackBar.success(context, '✅ Configuração salva no Firestore!');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Erro: $e');
      }
    }
  }

  void _deleteSeededUsers(BuildContext context, WidgetRef ref) async {
    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Limpar Perfis Fake',
        message:
            'Isso vai deletar TODOS os perfis criados pelo seeder '
            '(identificados pelo email @seeded.mube.app). Continuar?',
        confirmText: 'Deletar',
        isDestructive: true,
      ),
    );

    if (confirm == true && context.mounted) {
      AppSnackBar.info(context, 'Deletando perfis fake...');

      try {
        final seeder = ref.read(appSeederProvider);
        final count = await seeder.deleteSeededUsers();
        if (context.mounted) {
          AppSnackBar.success(context, '🗑️ $count perfis deletados!');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, 'Erro ao deletar: $e');
        }
      }
    }
  }
}
