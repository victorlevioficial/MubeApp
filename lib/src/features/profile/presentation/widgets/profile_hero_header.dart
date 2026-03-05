import 'package:flutter/material.dart';

import '../../../../constants/app_constants.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';

/// Hero header for the public profile screen.
///
/// Displays a gradient banner in the profile type accent color,
/// a large avatar with hero animation, name, type badge, sub-categories,
/// location and a favorites stat.
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

  // â”€â”€ Colors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  static IconData profileTypeIcon(AppUserType? type) {
    switch (type) {
      case AppUserType.professional:
        return Icons.music_note_rounded;
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

  static String profileTypeLabel(AppUserType? type) {
    switch (type) {
      case AppUserType.professional:
        return 'M\u00FAsico';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Est\u00FAdio';
      case AppUserType.contractor:
        return 'Contratante';
      default:
        return 'Perfil';
    }
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final displayName = user.appDisplayName;
    final typeColor = profileTypeColor(user.tipoPerfil);
    final hasAvatar = user.foto != null && user.foto!.isNotEmpty;
    final location = user.location;

    return Column(
      children: [
        // Gradient banner + overlapping avatar
        SizedBox(
          height: 148,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Gradient background
              Positioned.fill(child: _GradientBanner(color: typeColor)),
              // Avatar overlapping the banner bottom
              Positioned(
                bottom: -56,
                child: _AvatarBubble(
                  user: user,
                  displayName: displayName,
                  typeColor: typeColor,
                  hasAvatar: hasAvatar,
                  avatarHeroTag: avatarHeroTag,
                  onTap: onAvatarTap,
                ),
              ),
            ],
          ),
        ),

        // Space for the overlapping avatar
        const SizedBox(height: 60),

        // Display name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
          child: Text(
            displayName,
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: AppSpacing.s8),

        // Profile type badge
        _ProfileTypeBadge(
          icon: profileTypeIcon(user.tipoPerfil),
          label: profileTypeLabel(user.tipoPerfil),
          color: typeColor,
        ),

        // Professional sub-categories
        if (user.tipoPerfil == AppUserType.professional) ...[
          const SizedBox(height: AppSpacing.s8),
          _SubCategoriesRow(user: user),
        ],

        // Location
        if (location != null) ...[
          const SizedBox(height: AppSpacing.s10),
          _LocationRow(location: location),
        ],

        // Favorites count stat
        if (user.favoritesCount > 0) ...[
          const SizedBox(height: AppSpacing.s10),
          _FavoritesStat(count: user.favoritesCount),
        ],

        const SizedBox(height: AppSpacing.s8),
      ],
    );
  }
}

// â”€â”€ Private sub-widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GradientBanner extends StatelessWidget {
  final Color color;

  const _GradientBanner({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.32),
            color.withValues(alpha: 0.14),
            AppColors.background,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle radial highlight at top-left for depth
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final AppUser user;
  final String displayName;
  final Color typeColor;
  final bool hasAvatar;
  final String avatarHeroTag;
  final VoidCallback? onTap;

  const _AvatarBubble({
    required this.user,
    required this.displayName,
    required this.typeColor,
    required this.hasAvatar,
    required this.avatarHeroTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasAvatar ? onTap : null,
      child: Container(
        width: 124,
        height: 124,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: typeColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Hero(
            tag: avatarHeroTag,
            child: UserAvatar(
              size: 124,
              photoUrl: user.foto,
              name: displayName,
              showBorder: false,
            ),
          ),
        ),
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
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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

class _SubCategoriesRow extends StatelessWidget {
  final AppUser user;

  const _SubCategoriesRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final ids = user.dadosProfissional?['categorias'] as List? ?? [];
    if (ids.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    for (final id in ids) {
      final config = professionalCategories.firstWhere(
        (c) => c['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (config.isEmpty) continue;

      widgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config['icon'] as IconData,
              size: 12,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.s4),
            Text(
              config['label'] as String,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.s12,
      runSpacing: AppSpacing.s4,
      alignment: WrapAlignment.center,
      children: widgets,
    );
  }
}

class _LocationRow extends StatelessWidget {
  final Map<String, dynamic> location;

  const _LocationRow({required this.location});

  @override
  Widget build(BuildContext context) {
    final city = location['cidade'] as String? ?? '';
    final state = location['estado'] as String? ?? '';
    final label = city.isNotEmpty && state.isNotEmpty
        ? '$city, $state'
        : city.isNotEmpty
        ? city
        : state;

    if (label.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 14,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.s4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FavoritesStat extends StatelessWidget {
  final int count;

  const _FavoritesStat({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite_rounded, size: 13, color: AppColors.primary),
        const SizedBox(width: AppSpacing.s4),
        Text(
          '$count ${count == 1 ? 'favorito' : 'favoritos'}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
