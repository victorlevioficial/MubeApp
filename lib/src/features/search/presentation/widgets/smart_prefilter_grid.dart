import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../design_system/foundations/tokens/app_assets.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/search_filters.dart';

/// Represents a smart pre-filter shortcut for discovery.
class SmartPrefilter {
  final String label;
  final String subtitle;
  final IconData? icon;
  final String? svgAssetPath;
  final Color accentColor;

  /// The filters to apply when this pre-filter is tapped.
  final SearchFilters filters;

  const SmartPrefilter({
    required this.label,
    required this.subtitle,
    this.icon,
    this.svgAssetPath,
    required this.accentColor,
    required this.filters,
  }) : assert(
         (icon != null) != (svgAssetPath != null),
         'Provide either icon or svgAssetPath.',
       );
}

/// A group of prefilters under a section header.
class _PrefilterSection {
  final String title;
  final String? subtitle;
  final List<SmartPrefilter> items;

  const _PrefilterSection({
    required this.title,
    this.subtitle,
    required this.items,
  });
}

// ─── Pre-filter Definitions ──────────────────────────────────────────────────

const _kMusiciansSection = _PrefilterSection(
  title: 'Músicos',
  subtitle: 'Encontre instrumentistas e cantores',
  items: [
    SmartPrefilter(
      label: 'Cantores',
      subtitle: 'Vocais & Backing',
      icon: FontAwesomeIcons.microphone,
      accentColor: Color(0xFFA78BFA),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.singer,
      ),
    ),
    SmartPrefilter(
      label: 'Guitarristas',
      subtitle: 'Violão & Guitarra',
      icon: FontAwesomeIcons.guitar,
      accentColor: Color(0xFFE8466C),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.instrumentalist,
        instruments: ['Guitarra', 'Violão'],
      ),
    ),
    SmartPrefilter(
      label: 'Bateristas',
      subtitle: 'Percussão & Bateria',
      icon: FontAwesomeIcons.drum,
      accentColor: Color(0xFF60A5FA),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.instrumentalist,
        instruments: ['Bateria'],
      ),
    ),
    SmartPrefilter(
      label: 'Baixistas',
      subtitle: 'Contrabaixo & Baixo',
      icon: FontAwesomeIcons.guitar,
      accentColor: Color(0xFF34D399),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.instrumentalist,
        instruments: ['Baixo', 'Contrabaixo'],
      ),
    ),
    SmartPrefilter(
      label: 'Tecladistas',
      subtitle: 'Piano & Teclado',
      svgAssetPath: AppAssets.searchPrefilterKeyboardSvg,
      accentColor: Color(0xFFFBBF24),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.instrumentalist,
        instruments: ['Teclado', 'Piano'],
      ),
    ),
    SmartPrefilter(
      label: 'DJs',
      subtitle: 'Eletrônica & Mix',
      icon: FontAwesomeIcons.compactDisc,
      accentColor: Color(0xFFF472B6),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.dj,
      ),
    ),
  ],
);

const _kProductionSection = _PrefilterSection(
  title: 'Produção Musical',
  subtitle: 'Produção, gravação e direção musical',
  items: [
    SmartPrefilter(
      label: 'Produtores',
      subtitle: 'Produção & Direção',
      icon: FontAwesomeIcons.sliders,
      accentColor: Color(0xFFC026D3),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.production,
        roles: [
          'Produtor Musical',
          'Beatmaker',
          'Programação de Instrumentos (MIDI)',
        ],
      ),
    ),
    SmartPrefilter(
      label: 'Mixagem & Master',
      subtitle: 'Gravação & Edição',
      icon: FontAwesomeIcons.volumeHigh,
      accentColor: Color(0xFFE8466C),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.production,
        roles: [
          'Mixagem',
          'Masterização',
          'Técnico de Gravação',
          'Edição de Áudio',
        ],
      ),
    ),
    SmartPrefilter(
      label: 'Arranjadores',
      subtitle: 'Composição & Direção',
      icon: FontAwesomeIcons.music,
      accentColor: Color(0xFF34D399),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.production,
        roles: ['Arranjador', 'Compositor', 'Diretor Vocal'],
      ),
    ),
  ],
);

const _kStageTechSection = _PrefilterSection(
  title: 'Técnica de Palco',
  subtitle: 'Profissionais de palco, áudio e operação ao vivo',
  items: [
    SmartPrefilter(
      label: 'Técnicos de Som',
      subtitle: 'PA, Monitor & RF',
      icon: FontAwesomeIcons.volumeHigh,
      accentColor: Color(0xFF60A5FA),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.stageTech,
        roles: ['Técnico de PA', 'Técnico de Monitor', 'Técnico de RF'],
      ),
    ),
    SmartPrefilter(
      label: 'Técnicos de Luz',
      subtitle: 'Iluminação & LED',
      icon: FontAwesomeIcons.solidLightbulb,
      accentColor: Color(0xFFFBBF24),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.stageTech,
        roles: ['Técnico de Luz', 'VJ (Telão)', 'Técnico de LED (Painel)'],
      ),
    ),
    SmartPrefilter(
      label: 'Roadies',
      subtitle: 'Techs & Backline',
      icon: FontAwesomeIcons.toolbox,
      accentColor: Color(0xFFF87171),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.stageTech,
        roles: [
          'Roadie',
          'Guitar Tech',
          'Drum Tech',
          'Bass Tech',
          'Keyboard Tech',
        ],
      ),
    ),
    SmartPrefilter(
      label: 'Stage Managers',
      subtitle: 'Gestão de Palco',
      icon: FontAwesomeIcons.clipboardList,
      accentColor: Color(0xFF34D399),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        professionalSubcategory: ProfessionalSubcategory.stageTech,
        roles: ['Stage Manager'],
      ),
    ),
  ],
);

const _kBandsStudiosSection = _PrefilterSection(
  title: 'Bandas & Estúdios',
  subtitle: 'Grupos e espaços musicais',
  items: [
    SmartPrefilter(
      label: 'Bandas',
      subtitle: 'Grupos musicais',
      icon: FontAwesomeIcons.peopleGroup,
      accentColor: Color(0xFFC026D3),
      filters: SearchFilters(category: SearchCategory.bands),
    ),
    SmartPrefilter(
      label: 'Estúdios',
      subtitle: 'Gravação & Ensaio',
      icon: FontAwesomeIcons.headset,
      accentColor: Color(0xFFDC2626),
      filters: SearchFilters(category: SearchCategory.studios),
    ),
  ],
);

const _kGenresSection = _PrefilterSection(
  title: 'Por Gênero',
  subtitle: 'Filtre por estilo musical',
  items: [
    SmartPrefilter(
      label: 'Sertanejo',
      subtitle: 'Universitário & Raiz',
      icon: FontAwesomeIcons.hatCowboy,
      accentColor: Color(0xFFFBBF24),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        genres: ['Sertanejo', 'Sertanejo Universitário'],
      ),
    ),
    SmartPrefilter(
      label: 'Rock',
      subtitle: 'Clássico, Indie & Alt',
      icon: FontAwesomeIcons.boltLightning,
      accentColor: Color(0xFFF87171),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        genres: ['Rock', 'Pop Rock', 'Rock Clássico', 'Indie Rock'],
      ),
    ),
    SmartPrefilter(
      label: 'Gospel',
      subtitle: 'Worship & Louvor',
      icon: FontAwesomeIcons.handsPraying,
      accentColor: Color(0xFF60A5FA),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        genres: ['Gospel', 'Worship'],
      ),
    ),
    SmartPrefilter(
      label: 'Funk & Eletrônica',
      subtitle: 'EDM, House & Funk',
      icon: FontAwesomeIcons.recordVinyl,
      accentColor: Color(0xFFA78BFA),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        genres: ['Funk', 'Eletrônica', 'EDM', 'House'],
      ),
    ),
    SmartPrefilter(
      label: 'Pagode & Samba',
      subtitle: 'Samba-enredo & Pagode',
      icon: Icons.celebration_rounded,
      accentColor: Color(0xFF34D399),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        genres: ['Pagode', 'Samba', 'Samba-enredo'],
      ),
    ),
    SmartPrefilter(
      label: 'Forró & Nordeste',
      subtitle: 'Forró, Piseiro & Xote',
      icon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFE8466C),
      filters: SearchFilters(
        category: SearchCategory.professionals,
        genres: ['Forró', 'Piseiro', 'Xote', 'Baião'],
      ),
    ),
  ],
);

final List<_PrefilterSection> _kAllSections = [
  _kMusiciansSection,
  _kProductionSection,
  _kStageTechSection,
  _kBandsStudiosSection,
  _kGenresSection,
];

// Flat list for backward compatibility
final List<SmartPrefilter> kSmartPrefilters = _kAllSections
    .expand((section) => section.items)
    .toList();

/// A grid of smart pre-filter cards organized in sections for quick discovery.
class SmartPrefilterGrid extends StatelessWidget {
  final ValueChanged<SmartPrefilter> onPrefilterTap;

  const SmartPrefilterGrid({super.key, required this.onPrefilterTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Text('Descobrir', style: AppTypography.headlineMedium),
        ),
        const SizedBox(height: AppSpacing.s4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Text(
            'Encontre o profissional ideal',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        ..._kAllSections.map((section) => _buildSection(section)),
      ],
    );
  }

  Widget _buildSection(_PrefilterSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.pill,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (section.subtitle != null)
                        Text(
                          section.subtitle!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),

          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = AppSpacing.s10;
              final availableWidth =
                  constraints.maxWidth - (AppSpacing.s16 * 2);
              final columnCount = availableWidth >= 960
                  ? 4
                  : availableWidth >= 640
                  ? 3
                  : 2;
              final itemWidth =
                  (availableWidth - ((columnCount - 1) * spacing)) /
                  columnCount;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final item in section.items)
                      SizedBox(
                        width: itemWidth,
                        child: _PrefilterCard(
                          item: item,
                          onTap: onPrefilterTap,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrefilterCard extends StatefulWidget {
  final SmartPrefilter item;
  final ValueChanged<SmartPrefilter> onTap;

  const _PrefilterCard({required this.item, required this.onTap});

  @override
  State<_PrefilterCard> createState() => _PrefilterCardState();
}

class _PrefilterCardState extends State<_PrefilterCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.item.accentColor;

    return GestureDetector(
      onTap: () => widget.onTap(widget.item),
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 124),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(
                color: _isPressed
                    ? accent.withValues(alpha: 0.5)
                    : AppColors.surfaceHighlight.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: AppRadius.all8,
                  ),
                  child: Center(
                    child: widget.item.svgAssetPath != null
                        ? SvgPicture.asset(
                            widget.item.svgAssetPath!,
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              accent,
                              BlendMode.srcIn,
                            ),
                          )
                        : Icon(widget.item.icon, color: accent, size: 18),
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  widget.item.label,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  widget.item.subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
