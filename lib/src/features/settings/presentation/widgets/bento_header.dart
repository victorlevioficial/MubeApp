import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/data/auth_repository.dart';

/// Enhanced profile header with modern bento grid layout
///
/// Features:
/// - Large profile card with avatar, name, email
/// - Edit button with refined styling
/// - Stats grid showing favorites and plan type
/// - Glassmorphic effects and subtle depth
class BentoHeader extends ConsumerWidget {
  const BentoHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    return Column(
      children: [
        // ENHANCED PROFILE CARD
        _ProfileCard(
          name: user?.nome ?? 'Bem-vindo',
          email: user?.email ?? 'Visitante',
          photoUrl: user?.foto,
          onEditTap: () => context.push('/profile/edit'),
        ),

        const SizedBox(height: AppSpacing.s16),

        // STATS GRID
        _StatsGrid(
          favoritesCount: user?.favoritesCount ?? 0,
          planType: user?.plan ?? 'free',
        ),
      ],
    );
  }
}

/// Profile card component with enhanced styling
class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final VoidCallback onEditTap;

  const _ProfileCard({
    required this.name,
    required this.email,
    required this.onEditTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        // Refined gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceHighlight.withValues(alpha: 0.6),
            AppColors.surface.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: AppRadius.all24,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Enhanced Avatar with border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.surface,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null
                  ? Icon(
                      Icons.person_rounded,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      size: 32,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: AppSpacing.s16),

          // User Info with enhanced typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  email,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.s8),

          // Enhanced Edit Button
          _EditButton(onTap: onEditTap),
        ],
      ),
    );
  }
}

/// Refined edit button with subtle styling
class _EditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s10),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.edit_outlined,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Stats grid showing user statistics
class _StatsGrid extends StatelessWidget {
  final int favoritesCount;
  final String planType;

  const _StatsGrid({required this.favoritesCount, required this.planType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Favorites Stat
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            iconColor: AppColors.primary,
            value: favoritesCount.toString(),
            label: 'Favoritos',
          ),
        ),

        const SizedBox(width: AppSpacing.s12),

        // Plan Stat
        Expanded(
          child: _StatCard(
            icon: planType == 'pro'
                ? Icons.workspace_premium
                : Icons.star_border_rounded,
            iconColor: planType == 'pro'
                ? AppColors.warning
                : AppColors.textSecondary.withValues(alpha: 0.6),
            value: planType == 'pro' ? 'Pro' : 'Free',
            label: 'Plano Ativo',
          ),
        ),
      ],
    );
  }
}

/// Individual stat card component
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: AppRadius.all20,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container with accent background
          Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),

          const SizedBox(width: AppSpacing.s12),

          // Value and Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
