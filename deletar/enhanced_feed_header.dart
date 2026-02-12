import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/app_constants.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';

/// Enhanced premium header for the Feed screen with modern aesthetics.
///
/// Features:
/// - Larger animated user avatar with gradient glow
/// - Personalized welcome message with context
/// - User engagement stats row (connections, matches, views)
/// - Improved profile completion card with progress visualization
/// - Notification button with badge
class EnhancedFeedHeader extends ConsumerWidget {
  final AppUser? currentUser;
  final VoidCallback? onNotificationTap;
  final bool isScrolled;
  final int notificationCount;

  const EnhancedFeedHeader({
    super.key,
    this.currentUser,
    this.onNotificationTap,
    this.isScrolled = false,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isScrolled
                ? [AppColors.background, AppColors.background]
                : [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.02),
                    AppColors.background,
                  ],
            stops: isScrolled ? null : const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s20,
              AppSpacing.s20,
              AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context),
                const SizedBox(height: AppSpacing.s20),
                _buildProfileCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Welcome section with larger avatar, greeting and notification button
  Widget _buildWelcomeSection(BuildContext context) {
    final displayName = _getDisplayName();
    final firstName = displayName.split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Larger animated avatar with gradient glow
        Hero(
          tag: 'profile-avatar',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/profile/edit');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isScrolled ? 56 : 68,
              height: isScrolled ? 56 : 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryPressed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: currentUser?.foto != null
                    ? UserAvatar(
                        photoUrl: currentUser!.foto,
                        name: displayName,
                        size: isScrolled ? 56 : 68,
                      )
                    : Icon(
                        Icons.person,
                        color: AppColors.textPrimary,
                        size: isScrolled ? 28 : 34,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s16),

        // Greeting text with larger typography
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $firstName! 👋',
                style: isScrolled
                    ? AppTypography.headlineSmall
                    : AppTypography.headlineMedium.copyWith(fontSize: 22),
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

        // Notifications button with enhanced design
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



  /// Enhanced profile CTA card with progress visualization
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
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.95),
              AppColors.primaryPressed,
            ],
          ),
          borderRadius: AppRadius.all20,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withAlpha(40),
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
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary.withAlpha(220),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        '$profileType • $profileRole',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Container(
                  padding: AppSpacing.all8,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withAlpha(25),
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
            const SizedBox(height: AppSpacing.s16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Perfil completo',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary.withAlpha(200),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$completionPercent%',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                ClipRRect(
                  borderRadius: AppRadius.pill,
                  child: LinearProgressIndicator(
                    value: completionPercent / 100,
                    backgroundColor: AppColors.textPrimary.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textPrimary.withAlpha(230),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
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
    if (type == null) return Icons.music_note;

    switch (type) {
      case AppUserType.professional:
        return Icons.music_note_rounded;
      case AppUserType.band:
        return Icons.groups_rounded;
      case AppUserType.studio:
        return Icons.headphones_rounded;
      case AppUserType.contractor:
        return Icons.business_center_rounded;
    }
  }

  String _getProfileRole() {
    if (currentUser == null) return 'Músico';

    final profData = currentUser!.dadosProfissional;
    if (profData != null) {
      // Try to get first category or instrument
      final categorias = profData['categorias'] as List<dynamic>?;
      if (categorias != null && categorias.isNotEmpty) {
        return _getCategoryLabel(categorias.first as String);
      }

      final instrumentos = profData['instrumentos'] as List<dynamic>?;
      if (instrumentos != null && instrumentos.isNotEmpty) {
        return _formatRole(instrumentos.first as String);
      }
    }

    return 'Músico';
  }

  String _getCategoryLabel(String id) {
    try {
      final category = professionalCategories.firstWhere(
        (e) => e['id'] == id,
        orElse: () => {'label': _formatRole(id)},
      );
      return category['label'] as String;
    } catch (_) {
      return _formatRole(id);
    }
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

/// Enhanced notification button with modern badge design
class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: AppSpacing.all12,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surfaceHighlight,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryPressed],
                  ),
                  borderRadius: AppRadius.pill,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
