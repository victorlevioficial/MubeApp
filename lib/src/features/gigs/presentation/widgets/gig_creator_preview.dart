import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';

class GigCreatorPreview extends StatelessWidget {
  const GigCreatorPreview({
    super.key,
    required this.creator,
    this.compact = false,
  });

  final AppUser creator;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = creator.appDisplayName;
    final categoryLabel = _categoryLabel(creator);
    final avatarSize = compact ? 36.0 : 44.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RoutePaths.publicProfileById(creator.uid)),
        borderRadius: AppRadius.all12,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.s10 : AppSpacing.s12,
            vertical: compact ? AppSpacing.s8 : AppSpacing.s10,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: AppRadius.all12,
          ),
          child: Row(
            children: [
              UserAvatar(
                size: avatarSize,
                photoUrl: creator.foto,
                name: name,
                showBorder: false,
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      compact ? 'Publicado por' : 'Criado por',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: compact
                          ? AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            )
                          : AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                    ),
                    if (categoryLabel.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(AppUser user) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return 'Perfil Individual';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Estudio';
      case AppUserType.contractor:
        return 'Contratante';
      case null:
        return 'Perfil';
    }
  }
}
