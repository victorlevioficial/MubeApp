import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/category_normalizer.dart';
import '../../../matchpoint/domain/matchpoint_availability.dart';

/// Determines the profile classification based on selected categories.
enum ProfileClassification {
  musician, // Cantor/Instrumentista without technical crew
  technician, // Pure stage technician
  professional,
  band,
  studio,
  venue,
}

/// A badge that displays the profile type with a colored icon.
class ProfileTypeBadge extends StatelessWidget {
  final String tipoPerfil;
  final List<String> subCategories;

  const ProfileTypeBadge({
    super.key,
    required this.tipoPerfil,
    this.subCategories = const [],
  });

  @override
  Widget build(BuildContext context) {
    final classification = _getClassification();
    final (label, icon, iconColor) = _getBadgeData(classification);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\u2022',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
        Icon(icon, size: 14, color: iconColor),
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

  ProfileClassification _getClassification() {
    switch (tipoPerfil) {
      case 'banda':
        return ProfileClassification.band;
      case 'estudio':
        return ProfileClassification.studio;
      case 'profissional':
        return CategoryNormalizer.isPureTechnician(
              rawCategories: subCategories,
              rawRoles: const [],
            )
            ? ProfileClassification.technician
            : isArtisticallyEligibleCategoryIds(subCategories)
            ? ProfileClassification.musician
            : ProfileClassification.professional;
      case 'contratante':
        return ProfileClassification.venue;
      default:
        return ProfileClassification.professional;
    }
  }

  (String, IconData, Color) _getBadgeData(
    ProfileClassification classification,
  ) {
    switch (classification) {
      case ProfileClassification.musician:
        return ('Musico', Icons.music_note, AppColors.badgeMusician);
      case ProfileClassification.technician:
        return ('Tecnico', Icons.build_rounded, AppColors.badgeMusician);
      case ProfileClassification.professional:
        return ('Profissional', Icons.badge_rounded, AppColors.primary);
      case ProfileClassification.band:
        return ('Banda', Icons.groups, AppColors.badgeBand);
      case ProfileClassification.studio:
        return ('Estudio', Icons.headphones, AppColors.badgeStudio);
      case ProfileClassification.venue:
        return ('Local', Icons.storefront_rounded, AppColors.warning);
    }
  }
}
