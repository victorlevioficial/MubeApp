import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

/// Determines the profile classification based on selected categories.
enum ProfileClassification {
  musician, // Cantor/Instrumentista without "Equipe Técnica"
  professional, // Has "Equipe Técnica" category
  band,
  studio,
}

/// A badge that displays the profile type with a colored icon.
///
/// Design:
/// - Filled dark gray chip background
/// - White text label
/// - Colored icon based on profile type
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
        const Text(
          '•',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
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
        // Check if has "Equipe Técnica" category
        final hasEquipeTecnica = subCategories.contains('equipe_tecnica');
        return hasEquipeTecnica
            ? ProfileClassification.professional
            : ProfileClassification.musician;
      default:
        return ProfileClassification.musician;
    }
  }

  (String, IconData, Color) _getBadgeData(
    ProfileClassification classification,
  ) {
    switch (classification) {
      case ProfileClassification.musician:
        return ('Músico', Icons.music_note, AppColors.badgeMusician);
      case ProfileClassification.professional:
        return ('Profissional', Icons.music_note, AppColors.badgeMusician);
      case ProfileClassification.band:
        return ('Banda', Icons.groups, AppColors.badgeBand);
      case ProfileClassification.studio:
        return ('Estúdio', Icons.headphones, AppColors.badgeStudio);
    }
  }
}
