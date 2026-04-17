import 'package:flutter/material.dart';

import '../../../../constants/app_constants.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/category_normalizer.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';
import '../../../matchpoint/domain/matchpoint_availability.dart';

/// Hero header for the public profile screen.
///
/// Uses a card-led layout instead of a decorative banner so the identity
/// information stays compact and easier to scan on mobile.
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
        return 'Músico';
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

  static IconData profileTypeIconForUser(AppUser user) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return _isArtisticallyEligibleProfessional(user)
            ? Icons.music_note_rounded
            : Icons.badge_rounded;
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
        return _isArtisticallyEligibleProfessional(user)
            ? 'Músico'
            : 'Profissional';
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

  static bool _isArtisticallyEligibleProfessional(AppUser user) {
    final professional = user.dadosProfissional;
    final rawCategories = user.professionalCategories.toList(growable: true);

    final legacyCategory = professional?['categoria'];
    if (legacyCategory is String && legacyCategory.isNotEmpty) {
      rawCategories.add(legacyCategory);
    }

    final rawRoles = user.professionalRoles;

    return isArtisticallyEligibleProfessionalCategories(
      rawCategories: rawCategories,
      rawRoles: rawRoles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user.appDisplayName;
    final typeColor = profileTypeColor(user.tipoPerfil);
    final hasAvatar =
        user.avatarPreviewUrl != null && user.avatarPreviewUrl!.isNotEmpty;
    final metadata = _buildMetadata(typeColor);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface2, AppColors.surface],
        ),
        borderRadius: AppRadius.all24,
        border: Border.all(color: AppColors.surfaceHighlight),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.34),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: AppSpacing.s16,
            left: AppSpacing.s20,
            right: AppSpacing.s20,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    typeColor.withValues(alpha: 0.92),
                    typeColor.withValues(alpha: 0.16),
                  ],
                ),
                borderRadius: AppRadius.pill,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.all24,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      typeColor.withValues(alpha: 0.08),
                      AppColors.transparent,
                      AppColors.transparent,
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -32,
            right: -24,
            child: IgnorePointer(
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      typeColor.withValues(alpha: 0.16),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s24,
              AppSpacing.s20,
              AppSpacing.s20,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSplitIdentity =
                    MediaQuery.sizeOf(context).width >= 600;
                if (!useSplitIdentity) {
                  return _stackedIdentity(
                    displayName: displayName,
                    typeColor: typeColor,
                    hasAvatar: hasAvatar,
                    metadata: metadata,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s8),
                          child: _AvatarBubble(
                            user: user,
                            displayName: displayName,
                            hasAvatar: hasAvatar,
                            avatarHeroTag: avatarHeroTag,
                            onTap: onAvatarTap,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s16),
                        Expanded(
                          child: _IdentityContent(
                            user: user,
                            displayName: displayName,
                            typeColor: typeColor,
                            crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                        ),
                      ],
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s16),
                      _MetadataPanel(metadata: metadata),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stackedIdentity({
    required String displayName,
    required Color typeColor,
    required bool hasAvatar,
    required List<Widget> metadata,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.s8),
        Align(
          child: _AvatarBubble(
            user: user,
            displayName: displayName,
            hasAvatar: hasAvatar,
            avatarHeroTag: avatarHeroTag,
            onTap: onAvatarTap,
            size: 104,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _IdentityContent(
          user: user,
          displayName: displayName,
          typeColor: typeColor,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _MetadataPanel(metadata: metadata, centered: true),
        ],
      ],
    );
  }

  List<Widget> _buildMetadata(Color typeColor) {
    final items = <Widget>[];
    final locationLabel = _locationLabel(user.location);

    if (locationLabel != null) {
      items.add(
        _MetaPill(
          icon: Icons.location_on_outlined,
          label: locationLabel,
          accentColor: typeColor,
        ),
      );
    }

    if (user.favoritesCount > 0) {
      final count = user.favoritesCount;
      items.add(
        _MetaPill(
          icon: Icons.favorite_rounded,
          label: '$count',
          accentColor: typeColor,
          emphasizeIcon: true,
          compact: true,
        ),
      );
    }

    return items;
  }

  String? _locationLabel(Map<String, dynamic>? location) {
    if (location == null) return null;

    final city = location['cidade'] as String? ?? '';
    final state = _abbreviateState(location['estado'] as String? ?? '');

    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    }

    if (city.isNotEmpty) {
      return city;
    }

    if (state.isNotEmpty) {
      return state;
    }

    return null;
  }

  String _abbreviateState(String rawState) {
    final normalized = rawState.trim();
    if (normalized.isEmpty) return '';
    if (normalized.length <= 2) return normalized.toUpperCase();

    const stateAbbreviations = <String, String>{
      'acre': 'AC',
      'alagoas': 'AL',
      'amapa': 'AP',
      'amazonas': 'AM',
      'bahia': 'BA',
      'ceara': 'CE',
      'distrito federal': 'DF',
      'espirito santo': 'ES',
      'goias': 'GO',
      'maranhao': 'MA',
      'mato grosso': 'MT',
      'mato grosso do sul': 'MS',
      'minas gerais': 'MG',
      'para': 'PA',
      'paraiba': 'PB',
      'parana': 'PR',
      'pernambuco': 'PE',
      'piaui': 'PI',
      'rio de janeiro': 'RJ',
      'rio grande do norte': 'RN',
      'rio grande do sul': 'RS',
      'rondonia': 'RO',
      'roraima': 'RR',
      'santa catarina': 'SC',
      'sao paulo': 'SP',
      'sergipe': 'SE',
      'tocantins': 'TO',
    };

    final key = normalized
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éê]'), 'e')
        .replaceAll(RegExp(r'[í]'), 'i')
        .replaceAll(RegExp(r'[óôõ]'), 'o')
        .replaceAll(RegExp(r'[ú]'), 'u')
        .replaceAll('ç', 'c');

    return stateAbbreviations[key] ?? normalized;
  }
}

class _IdentityContent extends StatelessWidget {
  final AppUser user;
  final String displayName;
  final Color typeColor;
  final CrossAxisAlignment crossAxisAlignment;

  const _IdentityContent({
    required this.user,
    required this.displayName,
    required this.typeColor,
    required this.crossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final isCentered = crossAxisAlignment == CrossAxisAlignment.center;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          displayName,
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 26,
            height: 1.1,
          ),
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.s10),
        Wrap(
          alignment: isCentered ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            if (user.publicHandle != null)
              _PublicHandleChip(label: user.publicHandle!),
            _ProfileTypeBadge(
              icon: ProfileHeroHeader.profileTypeIconForUser(user),
              label: ProfileHeroHeader.profileTypeLabelForUser(user),
              color: typeColor,
            ),
          ],
        ),
        if (user.tipoPerfil == AppUserType.professional) ...[
          const SizedBox(height: AppSpacing.s12),
          _SubCategoriesRow(
            user: user,
            alignment: isCentered ? WrapAlignment.center : WrapAlignment.start,
          ),
        ],
      ],
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final AppUser user;
  final String displayName;
  final bool hasAvatar;
  final String avatarHeroTag;
  final VoidCallback? onTap;
  final double size;

  const _AvatarBubble({
    required this.user,
    required this.displayName,
    required this.hasAvatar,
    required this.avatarHeroTag,
    this.onTap,
    this.size = 108,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasAvatar ? onTap : null,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.background.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Hero(
              tag: avatarHeroTag,
              child: UserAvatar(
                size: size,
                photoUrl: user.avatarFullUrl,
                photoPreviewUrl: user.avatarPreviewUrl,
                name: displayName,
                showBorder: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicHandleChip extends StatelessWidget {
  final String label;

  const _PublicHandleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.alternate_email_rounded,
            size: 13,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.s4),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataPanel extends StatelessWidget {
  final List<Widget> metadata;
  final bool centered;

  const _MetadataPanel({required this.metadata, this.centered = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.42),
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Wrap(
        alignment: centered ? WrapAlignment.center : WrapAlignment.start,
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        children: metadata,
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
  final WrapAlignment alignment;

  const _SubCategoriesRow({
    required this.user,
    this.alignment = WrapAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final ids = user.professionalCategories;
    if (ids.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    for (final id in ids) {
      if (id == 'crew') {
        widgets.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.build_rounded,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(
                'Equipe Técnica',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
        continue;
      }

      final config = _subCategoryConfig(id);
      if (config == null) continue;

      widgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.s4),
            Text(
              config.label,
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
      runSpacing: AppSpacing.s8,
      alignment: alignment,
      children: widgets,
    );
  }
}

class _SubCategoryConfig {
  final String label;
  final IconData icon;

  const _SubCategoryConfig({required this.label, required this.icon});
}

_SubCategoryConfig? _subCategoryConfig(String rawId) {
  final normalized = CategoryNormalizer.normalizeCategoryId(rawId);

  for (final config in professionalCategories) {
    if (config['id'] == normalized) {
      return _SubCategoryConfig(
        label: config['label'] as String,
        icon: config['icon'] as IconData,
      );
    }
  }

  switch (normalized) {
    case 'audiovisual':
    case 'audio_visual':
      return const _SubCategoryConfig(
        label: 'Audiovisual',
        icon: Icons.videocam_rounded,
      );
    case 'education':
    case 'educacao':
      return const _SubCategoryConfig(
        label: 'Educação',
        icon: Icons.school_rounded,
      );
    case 'luthier':
    case 'luthieria':
      return const _SubCategoryConfig(
        label: 'Luthier',
        icon: Icons.handyman_rounded,
      );
    case 'performance':
      return const _SubCategoryConfig(
        label: 'Performance',
        icon: Icons.mic_rounded,
      );
    default:
      return null;
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool emphasizeIcon;
  final bool compact;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.emphasizeIcon = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = emphasizeIcon ? accentColor : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          SizedBox(width: compact ? AppSpacing.s4 : AppSpacing.s8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: compact ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: compact ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
