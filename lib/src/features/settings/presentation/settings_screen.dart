import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/app_seeder.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../design_system/presentation/widgetbook_screen.dart';
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
      appBar: const AppAppBar(title: 'Configurações', showBackButton: false),
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        padding: AppSpacing.h16v8,
        child: Column(
          children: [
            // 1. DASHBOARD HEADER (BENTO)
            const BentoHeader(),

            const SizedBox(height: AppSpacing.s32),

            // 2. SETTINGS GROUPS
            SettingsGroup(
              title: 'CONTA',
              children: [
                NeonSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Meus Endereços',
                  subtitle: 'Gerenciar entregas',
                  onTap: () => context.push('/settings/addresses'),
                  customAccentColor: AppColors.info,
                ),
                NeonSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Editar Dados',
                  onTap: () => context.push('/profile/edit'),
                  customAccentColor: AppColors.primary,
                ),
                NeonSettingsTile(
                  icon: Icons.favorite_outline,
                  title: 'Meus Favoritos',
                  onTap: () => context.push('/favorites'),
                  customAccentColor: AppColors.primary,
                ),
                // Dynamic Tile: Band Management or My Bands
                if (ref.watch(
                      currentUserProfileProvider.select(
                        (s) => s.value?.tipoPerfil,
                      ),
                    ) ==
                    AppUserType.band)
                  NeonSettingsTile(
                    icon: Icons.groups_outlined,
                    title: 'Gerenciar Banda',
                    subtitle: 'Integrantes e convites',
                    onTap: () => context.push(RoutePaths.invites),
                    customAccentColor: AppColors.warning,
                  )
                else
                  NeonSettingsTile(
                    icon: Icons.mail_outline,
                    title: 'Minhas Bandas',
                    subtitle: 'Convites e parcerias',
                    onTap: () => context.push(RoutePaths.invites),
                    customAccentColor: AppColors.warning,
                  ),
                NeonSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Alterar Senha',
                  onTap: () => _changePassword(context, ref),
                  customAccentColor: AppColors.info,
                ),
                NeonSettingsTile(
                  icon: Icons.public,
                  title: 'Privacidade e Visibilidade',
                  subtitle: 'MatchPoint, Busca, Bloqueios',
                  onTap: () => context.push(RoutePaths.privacySettings),
                  customAccentColor: AppColors.primary,
                ),
              ],
            ),

            SettingsGroup(
              title: 'OUTROS',
              children: [
                NeonSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Ajuda e Suporte',
                  onTap: () => context.push(RoutePaths.support),
                  customAccentColor: AppColors.info,
                ),
                NeonSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Termos de Uso',
                  onTap: () => context.push('${RoutePaths.legal}/termsOfUse'),
                  customAccentColor: AppColors.textSecondary,
                ),
                NeonSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidade',
                  onTap: () =>
                      context.push('${RoutePaths.legal}/privacyPolicy'),
                  customAccentColor: AppColors.textSecondary,
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
                    customAccentColor: AppColors.textPrimary,
                  ),
                  NeonSettingsTile(
                    icon: Icons.developer_mode,
                    title: 'Developer Tools 🛠️',
                    subtitle: 'Push Notifications, Logs, etc.',
                    onTap: () => context.push('/developer-tools'),
                    customAccentColor: AppColors.warning,
                  ),
                  NeonSettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Widgetbook (Style Guide)',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WidgetbookScreen(),
                        ),
                      );
                    },
                    customAccentColor: AppColors.primary,
                  ),
                  NeonSettingsTile(
                    icon: Icons.groups_outlined,
                    title: 'Popular Banco (MatchPoint)',
                    subtitle: 'Gerar 150 perfis diversos',
                    onTap: () => _seedDatabase(context, ref),
                    customAccentColor: AppColors.success,
                  ),
                  NeonSettingsTile(
                    icon: Icons.settings_input_component,
                    title: 'Seed App Config',
                    subtitle: 'Resetar listas (Gêneros/Inst.)',
                    onTap: () => _seedAppConfig(context, ref),
                    customAccentColor: AppColors.info,
                  ),
                  // REMOVIDO: Botão de limpar perfis fake não deve estar em produção
                  // NeonSettingsTile(
                  //   icon: Icons.delete_sweep_outlined,
                  //   title: 'Limpar Perfis Fake',
                  //   subtitle: 'Deletar usuários do seeder',
                  //   onTap: () => _deleteSeededUsers(context, ref),
                  //   customAccentColor: AppColors.error,
                  // ),
                ],
              ),

            const SizedBox(height: AppSpacing.s16),

            // 3. ACTION BUTTONS (Logout / Delete)
            _buildLogoutButton(context, ref),

            const SizedBox(height: AppSpacing.s12),

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

            const SizedBox(height: AppSpacing.s40),
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
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _confirmLogout(context, ref),
          borderRadius: AppRadius.all16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Sair da Conta',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: AppTypography.titleSmall.fontWeight,
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

  void _changePassword(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      AppSnackBar.error(context, 'Não foi possível encontrar seu email.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: 'Alterar Senha',
        message:
            'Enviaremos um link de redefinição para:\n\n$email\n\nDeseja continuar?',
        confirmText: 'Enviar',
        isDestructive: false,
      ),
    );

    if (confirm == true && context.mounted) {
      AppSnackBar.info(context, 'Enviando email...');

      final result = await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email);

      if (!context.mounted) return;

      result.fold(
        (failure) => AppSnackBar.error(context, failure.message),
        (_) => AppSnackBar.success(
          context,
          'Email enviado! Verifique sua caixa de entrada.',
        ),
      );
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

  // REMOVIDO: Método de deletar perfis fake não deve estar em produção
  // void _deleteSeededUsers(BuildContext context, WidgetRef ref) async { ... }
}
