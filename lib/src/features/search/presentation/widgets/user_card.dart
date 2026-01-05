import 'package:flutter/material.dart';

import '../../../../features/auth/domain/app_user.dart';
import '../../../../features/auth/domain/user_type.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';

/// Displays a user profile card in search results.
class UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onTap;

  const UserCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceHighlight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceHighlight,
                backgroundImage: user.foto != null && user.foto!.isNotEmpty
                    ? NetworkImage(user.foto!)
                    : null,
                child: user.foto == null || user.foto!.isEmpty
                    ? Icon(
                        _getIconForType(user.tipoPerfil),
                        color: AppColors.textSecondary,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(user),
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      user.tipoPerfil?.label ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    if (user.location != null) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Expanded(
                            child: Text(
                              '${user.location?['cidade'] ?? ''}, ${user.location?['estado'] ?? ''}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayName(AppUser user) {
    return switch (user.tipoPerfil) {
      AppUserType.professional =>
        user.dadosProfissional?['nomeArtistico'] ?? user.nome ?? '',
      AppUserType.studio =>
        user.dadosEstudio?['nomeArtistico'] ?? user.nome ?? '',
      _ => user.nome ?? '',
    };
  }

  IconData _getIconForType(AppUserType? type) {
    return switch (type) {
      AppUserType.professional => Icons.person,
      AppUserType.band => Icons.groups,
      AppUserType.studio => Icons.headphones,
      AppUserType.contractor => Icons.business,
      null => Icons.person,
    };
  }
}
