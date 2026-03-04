import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/search_filters.dart';

/// Displays active search filters as removable chips with a "Limpar" button.
class ActiveFiltersBar extends StatelessWidget {
  final SearchFilters filters;
  final String? activePrefilterLabel;
  final VoidCallback onClearAll;
  final VoidCallback? onClearPrefilter;
  final ValueChanged<String>? onRemoveGenre;
  final ValueChanged<String>? onRemoveInstrument;
  final ValueChanged<String>? onRemoveRole;
  final ValueChanged<String>? onRemoveService;
  final VoidCallback? onClearSubcategory;
  final VoidCallback? onClearStudioType;
  final VoidCallback? onClearBackingVocal;

  const ActiveFiltersBar({
    super.key,
    required this.filters,
    this.activePrefilterLabel,
    required this.onClearAll,
    this.onClearPrefilter,
    this.onRemoveGenre,
    this.onRemoveInstrument,
    this.onRemoveRole,
    this.onRemoveService,
    this.onClearSubcategory,
    this.onClearStudioType,
    this.onClearBackingVocal,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    final maxChipWidth = MediaQuery.sizeOf(context).width * 0.62;

    if (activePrefilterLabel != null) {
      chips.add(
        _buildChip(
          activePrefilterLabel!,
          AppColors.primary,
          maxWidth: maxChipWidth,
          icon: Icons.bolt_rounded,
          onRemove: onClearPrefilter,
        ),
      );
    }

    if (activePrefilterLabel == null &&
        filters.category != SearchCategory.all) {
      chips.add(
        _buildChip(
          _categoryLabel(filters.category),
          AppColors.primary,
          maxWidth: maxChipWidth,
          icon: _categoryIcon(filters.category),
        ),
      );
    }

    if (activePrefilterLabel == null &&
        filters.professionalSubcategory != null) {
      chips.add(
        _buildChip(
          _subcategoryLabel(filters.professionalSubcategory!),
          AppColors.info,
          maxWidth: maxChipWidth,
          icon: _subcategoryIcon(filters.professionalSubcategory!),
          onRemove: onClearSubcategory,
        ),
      );
    }

    if (filters.studioType != null) {
      chips.add(
        _buildChip(
          _studioTypeLabel(filters.studioType!),
          AppColors.badgeStudio,
          maxWidth: maxChipWidth,
          icon: filters.studioType == 'home_studio'
              ? Icons.home_rounded
              : Icons.storefront_rounded,
          onRemove: onClearStudioType,
        ),
      );
    }

    for (final genre in filters.genres) {
      chips.add(
        _buildChip(
          genre,
          AppColors.badgeBand,
          maxWidth: maxChipWidth,
          icon: Icons.library_music_rounded,
          onRemove: onRemoveGenre != null ? () => onRemoveGenre!(genre) : null,
        ),
      );
    }

    for (final instrument in filters.instruments) {
      chips.add(
        _buildChip(
          instrument,
          AppColors.info,
          maxWidth: maxChipWidth,
          icon: Icons.music_note_rounded,
          onRemove: onRemoveInstrument != null
              ? () => onRemoveInstrument!(instrument)
              : null,
        ),
      );
    }

    for (final role in filters.roles) {
      chips.add(
        _buildChip(
          role,
          AppColors.error,
          maxWidth: maxChipWidth,
          icon: Icons.build_rounded,
          onRemove: onRemoveRole != null ? () => onRemoveRole!(role) : null,
        ),
      );
    }

    for (final service in filters.services) {
      chips.add(
        _buildChip(
          service,
          AppColors.success,
          maxWidth: maxChipWidth,
          icon: Icons.headset_mic_rounded,
          onRemove: onRemoveService != null
              ? () => onRemoveService!(service)
              : null,
        ),
      );
    }

    if (filters.canDoBackingVocal != null) {
      chips.add(
        _buildChip(
          filters.canDoBackingVocal == true ? 'Faz backing vocal' : 'Só solo',
          AppColors.warning,
          maxWidth: maxChipWidth,
          icon: Icons.record_voice_over_rounded,
          onRemove: onClearBackingVocal,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        children: [
          ...chips.map(
            (chip) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: chip,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: onClearAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      'Limpar',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String label,
    Color color, {
    required double maxWidth,
    IconData? icon,
    VoidCallback? onRemove,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.pill,
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: AppSpacing.s4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: AppSpacing.s4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryLabel(SearchCategory category) {
    switch (category) {
      case SearchCategory.all:
        return 'Todos';
      case SearchCategory.professionals:
        return 'Profissionais';
      case SearchCategory.bands:
        return 'Bandas';
      case SearchCategory.studios:
        return 'Estúdios';
    }
  }

  IconData _categoryIcon(SearchCategory category) {
    switch (category) {
      case SearchCategory.all:
        return Icons.people_outline;
      case SearchCategory.professionals:
        return Icons.person_outline;
      case SearchCategory.bands:
        return Icons.groups_outlined;
      case SearchCategory.studios:
        return Icons.mic_none;
    }
  }

  String _subcategoryLabel(ProfessionalSubcategory sub) {
    switch (sub) {
      case ProfessionalSubcategory.singer:
        return 'Cantor(a)';
      case ProfessionalSubcategory.instrumentalist:
        return 'Instrumentista';
      case ProfessionalSubcategory.crew:
        return 'Equipe Técnica';
      case ProfessionalSubcategory.dj:
        return 'DJ';
    }
  }

  IconData _subcategoryIcon(ProfessionalSubcategory sub) {
    switch (sub) {
      case ProfessionalSubcategory.singer:
        return Icons.mic_rounded;
      case ProfessionalSubcategory.instrumentalist:
        return Icons.music_note_rounded;
      case ProfessionalSubcategory.crew:
        return Icons.build_rounded;
      case ProfessionalSubcategory.dj:
        return Icons.album_rounded;
    }
  }

  String _studioTypeLabel(String studioType) {
    switch (studioType) {
      case 'commercial':
        return 'Comercial';
      case 'home_studio':
        return 'Home Studio';
      default:
        return studioType;
    }
  }
}
