import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/data/auth_repository.dart';

class BentoHeader extends ConsumerWidget {
  const BentoHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    // Bento Grid Layout: 2 Rows
    // Row 1: Profile Card (Wide)
    // Row 2: Two smaller cards (Stats/Actions)

    return Column(
      children: [
        // BIG PROFILE CARD
        Container(
          width: double.infinity,
          padding: AppSpacing.all16,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(
              alpha: 0.5,
            ), // Glassy feel
            borderRadius: AppRadius.all24,
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
            ),
            boxShadow: AppEffects.cardShadow,
          ),
          child: Row(
            children: [
              // Avatar (Simplified - No Border)
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.surface,
                backgroundImage: user?.foto != null
                    ? NetworkImage(user!.foto!)
                    : null,
                child: user?.foto == null
                    ? const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s16),
              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nome ?? 'Bem-vindo',
                      style: AppTypography.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      user?.email ?? 'Visitante',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Edit Action
              GestureDetector(
                onTap: () => context.push('/settings/profile'),
                child: Container(
                  padding: AppSpacing.all8,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s12),

        // MINI CARDS ROW
        Row(
          children: [
            // Stats Card (Received Favorites)
            Expanded(
              child: _buildMiniCard(
                icon: Icons.favorite,
                iconColor: AppColors.error,
                title: user?.favoritesCount.toString() ?? '0',
                subtitle: 'Favoritos',
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            // Action Card (Active Plan)
            Expanded(
              child: _buildMiniCard(
                icon: user?.plan == 'pro' ? Icons.star : Icons.star_border,
                iconColor: user?.plan == 'pro'
                    ? AppColors.primary
                    : AppColors.textSecondary,
                title: user?.plan == 'pro' ? 'Pro' : 'Free',
                subtitle: 'Plano Ativo',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: AppSpacing.all16,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: AppRadius.all24,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: AppTypography.buttonPrimary.fontWeight,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
