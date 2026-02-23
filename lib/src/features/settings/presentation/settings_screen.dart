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
import '../../../design_system/foundations/tokens/app_effects.dart';
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

/// Professional Settings screen with enhanced UI/UX
///
/// Features:
/// - Modern bento grid header with stats
/// - Refined settings groups with better visual hierarchy
/// - Professional spacing and typography
/// - Smooth interactions and animations
/// - Clear visual separation between sections
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Configurações', showBackButton: false),
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s4),

            // 1. ENHANCED PROFILE HEADER
            const BentoHeader(),

            const SizedBox(height: AppSpacing.s40),

            // 2. ACCOUNT SETTINGS GROUP
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

            // 3. OTHER SETTINGS GROUP
            SettingsGroup(
              title: 'OUTROS',
              children: [
                NeonSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Ajuda e Suporte',
                  onTap: () => context.push(RoutePaths.support),
                  customAccentColor: AppColors.info,
                ),
                NeonSettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Termos de Uso',
                  onTap: () => context.push('${RoutePaths.legal}/termsOfUse'),
                  customAccentColor: AppColors.textSecondary.withValues(
                    alpha: 0.6,
                  ),
                ),
                NeonSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de Privacidade',
                  onTap: () =>
                      context.push('${RoutePaths.legal}/privacyPolicy'),
                  customAccentColor: AppColors.textSecondary.withValues(
                    alpha: 0.6,
                  ),
                ),
              ],
            ),

            // 4. DEV ZONE (Debug Mode Only)
            if (kDebugMode)
              SettingsGroup(
                title: 'DEV ZONE',
                children: [
                  NeonSettingsTile(
                    icon: Icons.build_circle_outlined,
                    title: 'Manutenção (Dev)',
                    onTap: () => context.push(RoutePaths.maintenance),
                    customAccentColor: AppColors.textPrimary.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  NeonSettingsTile(
                    icon: Icons.developer_mode_rounded,
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
                    subtitle: 'Gerar 150 perfis diversos (likes iniciam em 0)',
                    onTap: () => _seedDatabase(context, ref),
                    customAccentColor: AppColors.success,
                  ),
                  NeonSettingsTile(
                    icon: Icons.settings_input_component_rounded,
                    title: 'Seed App Config',
                    subtitle: 'Resetar listas (Gêneros/Inst.)',
                    onTap: () => _seedAppConfig(context, ref),
                    customAccentColor: AppColors.info,
                  ),
                ],
              ),

            const SizedBox(height: AppSpacing.s8),

            // 5. ACTION BUTTONS SECTION
            _LogoutSection(
              onLogout: () => _confirmLogout(context, ref),
              onDeactivate: () => _confirmDeactivate(context, ref),
            ),

            const SizedBox(height: AppSpacing.s48),
          ],
        ),
      ),
    );
  }

  // Action methods
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
        AppSnackBar.success(context, '$count usuários criados!');
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
        AppSnackBar.success(context, 'Configuração salva no Firestore!');
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

/// Logout and deactivate section component
class _LogoutSection extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeactivate;

  const _LogoutSection({required this.onLogout, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logout Button with refined styling
        _LogoutButton(onTap: onLogout),

        const SizedBox(height: AppSpacing.s16),

        // Deactivate Account Link
        TextButton(
          onPressed: onDeactivate,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s8,
            ),
          ),
          child: Text(
            'Desativar Conta',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textSecondary.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Professional logout button
class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppEffects.fast,
      curve: Curves.easeOut,
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _isPressed
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface.withValues(alpha: 0.8),
                  AppColors.surface.withValues(alpha: 0.6),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface.withValues(alpha: 0.7),
                  AppColors.surface.withValues(alpha: 0.5),
                ],
              ),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: _isPressed
              ? AppColors.textPrimary.withValues(alpha: 0.12)
              : AppColors.textPrimary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: _isPressed
            ? null
            : [
                BoxShadow(
                  color: AppColors.background.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: AppRadius.all16,
          splashColor: AppColors.textPrimary.withValues(alpha: 0.05),
          highlightColor: AppColors.textPrimary.withValues(alpha: 0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppColors.textPrimary.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(
                'Sair da Conta',
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
