import 'package:flutter/material.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/loading/app_shimmer.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';

/// Hero "Stage" for the public profile.
///
/// Circular avatar (tap to enlarge), name, and a pill identifying the
/// profile type (professional, band, studio, contractor). Background is
/// a subtle tinted gradient using the type color.
class ProfileHeroHeader extends StatelessWidget {
  final AppUser user;
  final String avatarHeroTag;
  final VoidCallback? onAvatarTap;

  const ProfileHeroHeader({
    super.key,
    required this.user,
    required this.avatarHeroTag,
    this.onAvatarTap,
  });

  static double heightFor(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context).top;
    return 420.0 + viewPadding * 0.4;
  }

  static Color profileTypeColor(AppUserType? type) {
    switch (type) {
      case AppUserType.professional:
        return AppColors.primary;
      case AppUserType.band:
        return AppColors.badgeBand;
      case AppUserType.studio:
        return AppColors.badgeStudio;
      case AppUserType.contractor:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  static IconData profileTypeIconForUser(AppUser user) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return Icons.badge_rounded;
      case AppUserType.band:
        return Icons.people_rounded;
      case AppUserType.studio:
        return Icons.headphones_rounded;
      case AppUserType.contractor:
        return Icons.business_center_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  static String profileTypeLabelForUser(AppUser user) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return 'Profissional';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Estúdio';
      case AppUserType.contractor:
        return 'Contratante';
      default:
        return 'Perfil';
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = heightFor(context);
    final typeColor = profileTypeColor(user.tipoPerfil);
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final displayName = user.appDisplayName;
    final handle = user.publicHandle;
    final hasAvatar =
        (user.avatarPreviewUrl?.isNotEmpty ?? false) ||
        (user.avatarFullUrl?.isNotEmpty ?? false);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.35),
                radius: 0.95,
                colors: [
                  typeColor.withValues(alpha: 0.22),
                  AppColors.background,
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: topInset + 72,
              left: AppSpacing.s20,
              right: AppSpacing.s20,
              bottom: AppSpacing.s24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: hasAvatar ? onAvatarTap : null,
                  child: Hero(
                    tag: avatarHeroTag,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.55),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withValues(alpha: 0.18),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: UserAvatar(
                          size: 154,
                          photoUrl: user.avatarFullUrl,
                          photoPreviewUrl: user.avatarPreviewUrl,
                          name: displayName,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                _ProfileTypeBadge(
                  icon: profileTypeIconForUser(user),
                  label: profileTypeLabelForUser(user),
                  color: typeColor,
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineLarge.copyWith(
                    fontSize: 28,
                    height: 1.1,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (handle != null) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    handle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTypeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileTypeBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.s4),
          Text(
            label.toUpperCase(),
            style: AppTypography.profileTypeLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Static shimmer placeholder so skeletons elsewhere can reuse it.
class HeroBackdropShimmer extends StatelessWidget {
  const HeroBackdropShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer.box(
      width: double.infinity,
      height: ProfileHeroHeader.heightFor(context),
      borderRadius: AppRadius.r4,
    );
  }
}
