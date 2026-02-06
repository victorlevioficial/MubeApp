import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';

/// Premium header for the Feed screen.
///
/// Features:
/// - Logo MUBE with gradient
/// - Search and notification buttons
/// - Animated user avatar
/// - Personalized welcome message
/// - Mini profile CTA card
class FeedHeader extends StatelessWidget {
  final AppUser? currentUser;
  final VoidCallback? onNotificationTap;
  final bool isScrolled;
  final int notificationCount;

  const FeedHeader({
    super.key,
    this.currentUser,
    this.onNotificationTap,
    this.isScrolled = false,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isScrolled
                ? [AppColors.surface, AppColors.surface]
                : [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.background,
                  ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context),
                const SizedBox(height: AppSpacing.s24),
                _buildProfileCard(context),
                const SizedBox(height: AppSpacing.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Welcome section with avatar, greeting and notification button
  Widget _buildWelcomeSection(BuildContext context) {
    final displayName = _getDisplayName();
    final firstName = displayName.split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Animated avatar - CIRCULAR
        Hero(
          tag: 'profile-avatar',
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isScrolled ? 44 : 56,
              height: isScrolled ? 44 : 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryPressed],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: currentUser?.foto != null
                    ? UserAvatar(
                        photoUrl: currentUser!.foto,
                        name: displayName,
                        size: isScrolled ? 44 : 56,
                      )
                    : Icon(
                        Icons.person,
                        color: AppColors.textPrimary,
                        size: isScrolled ? 24 : 28,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s16),

        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Text(
                    'Olá, $firstName! 👋',
                    style: isScrolled
                        ? AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                          )
                        : AppTypography.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                  ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                _getGreetingSubtitle(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Notifications button
        _NotificationButton(
          count: notificationCount,
          onTap: () {
            HapticFeedback.lightImpact();
            onNotificationTap?.call();
          },
        ),
      ],
    );
  }

  /// Mini profile CTA card
  Widget _buildProfileCard(BuildContext context) {
    final profileType = _getProfileTypeLabel();
    final profileRole = _getProfileRole();
    final completionPercent = _getProfileCompletionPercent();

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/profile/edit');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryPressed],
          ),
          borderRadius: AppRadius.all16,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile type icon - CIRCULAR
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getProfileTypeIcon(),
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.s16),

            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu Perfil',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    '$profileType • $profileRole',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: AppTypography.titleSmall.fontWeight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    '$completionPercent% completo',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Container(
              padding: AppSpacing.all8,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withAlpha(20),
                borderRadius: AppRadius.all12,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Helper Methods ----------

  String _getDisplayName() {
    if (currentUser == null) return 'Usuário';

    // Try artistic name from professional data
    final profData = currentUser!.dadosProfissional;
    if (profData != null && profData['nomeArtistico'] != null) {
      final artisticName = profData['nomeArtistico'] as String;
      if (artisticName.isNotEmpty) return artisticName;
    }

    // Try band name
    final bandData = currentUser!.dadosBanda;
    if (bandData != null && bandData['nomeBanda'] != null) {
      final bandName = bandData['nomeBanda'] as String;
      if (bandName.isNotEmpty) return bandName;
    }

    // Fallback to regular name
    return currentUser!.nome ?? 'Usuário';
  }

  String _getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia! Pronto para tocar?';
    if (hour < 18) return 'Boa tarde! Vamos fazer música?';
    return 'Boa noite! Que tal um som?';
  }

  String _getProfileTypeLabel() {
    final type = currentUser?.tipoPerfil;
    if (type == null) return 'Músico';

    switch (type) {
      case AppUserType.professional:
        return 'Profissional';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Estúdio';
      case AppUserType.contractor:
        return 'Contratante';
    }
  }

  IconData _getProfileTypeIcon() {
    final type = currentUser?.tipoPerfil;
    if (type == null) return Icons.person;

    switch (type) {
      case AppUserType.professional:
        return Icons.music_note;
      case AppUserType.band:
        return Icons.groups;
      case AppUserType.studio:
        return Icons.headphones;
      case AppUserType.contractor:
        return Icons.business_center;
    }
  }

  String _getProfileRole() {
    if (currentUser == null) return 'Músico';

    final profData = currentUser!.dadosProfissional;
    if (profData != null) {
      // Try to get first category or instrument
      final categorias = profData['categorias'] as List<dynamic>?;
      if (categorias != null && categorias.isNotEmpty) {
        return _formatRole(categorias.first as String);
      }

      final instrumentos = profData['instrumentos'] as List<dynamic>?;
      if (instrumentos != null && instrumentos.isNotEmpty) {
        return _formatRole(instrumentos.first as String);
      }
    }

    return 'Músico';
  }

  String _formatRole(String role) {
    // Convert snake_case to Title Case
    return role
        .split('_')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  int _getProfileCompletionPercent() {
    if (currentUser == null) return 0;

    int score = 0;
    const maxScore = 100;

    // Basic info (40 points)
    if (currentUser!.nome != null && currentUser!.nome!.isNotEmpty) score += 15;
    if (currentUser!.foto != null && currentUser!.foto!.isNotEmpty) score += 15;
    if (currentUser!.bio != null && currentUser!.bio!.isNotEmpty) score += 10;

    // Location (15 points)
    if (currentUser!.location != null) score += 15;

    // Profile type data (35 points)
    if (currentUser!.tipoPerfil != null) {
      score += 10;

      final typeData = switch (currentUser!.tipoPerfil!) {
        AppUserType.professional => currentUser!.dadosProfissional,
        AppUserType.band => currentUser!.dadosBanda,
        AppUserType.studio => currentUser!.dadosEstudio,
        AppUserType.contractor => currentUser!.dadosContratante,
      };

      if (typeData != null && typeData.isNotEmpty) score += 25;
    }

    // Registration status (10 points)
    if (currentUser!.isCadastroConcluido) score += 10;

    return (score / maxScore * 100).round().clamp(0, 100);
  }
}

/// Notification button with badge
class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: AppSpacing.all8,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          if (count > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: AppSpacing.all4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
