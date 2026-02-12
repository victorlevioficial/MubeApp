import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

/// Determines the profile classification based on selected categories.
enum ProfileClassification {
  musician, // Cantor/Instrumentista without technical crew
  professional, // Has technical crew category
  band,
  studio,
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
          '•',
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
        final hasTechnicalCrew = subCategories
            .map(_normalizeCategory)
            .contains('crew');
        return hasTechnicalCrew
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

  String _normalizeCategory(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (normalized == 'crew' ||
        normalized == 'equipe_tecnica' ||
        normalized == 'tecnico' ||
        normalized == 'tecnica') {
      return 'crew';
    }

    return normalized;
  }
}
