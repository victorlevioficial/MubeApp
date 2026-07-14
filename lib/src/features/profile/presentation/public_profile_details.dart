part of 'public_profile_screen.dart';

/// Renders a single consolidated information card per profile type.
///
/// Replaces the previous one-card-per-attribute layout where each chip
/// group lived in its own InfoCard. Bringing them under a single card
/// reduces visual repetition and lets density vary based on what each
/// type actually carries.
class _TypeDetails extends StatelessWidget {
  final AppUser user;
  final List<AppUser> bandMembers;

  const _TypeDetails({required this.user, required this.bandMembers});

  @override
  Widget build(BuildContext context) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return _ProfessionalDetailsCard(user: user);
      case AppUserType.band:
        return _BandDetailsCard(user: user, members: bandMembers);
      case AppUserType.studio:
        return _StudioDetailsCard(user: user);
      case AppUserType.contractor:
        return _ContractorDetailsCard(user: user);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DetailsCard extends StatelessWidget {
  final List<_DetailsBlock> blocks;

  const _DetailsCard({required this.blocks});

  @override
  Widget build(BuildContext context) {
    final visible = blocks
        .where((block) => block.shouldRender)
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            visible[i].build(context),
            if (i != visible.length - 1) ...[
              const SizedBox(height: AppSpacing.s16),
              Container(
                height: 1,
                color: AppColors.surfaceHighlight.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ],
        ],
      ),
    );
  }
}

abstract class _DetailsBlock {
  bool get shouldRender;
  Widget build(BuildContext context);
}

class _ChipsBlock extends _DetailsBlock {
  _ChipsBlock({required this.icon, required this.title, required this.items});

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  bool get shouldRender => items.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BlockHeader(icon: icon, title: title, count: items.length),
        const SizedBox(height: AppSpacing.s10),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: items
              .map((item) => _SkillChip(label: item))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _CustomBlock extends _DetailsBlock {
  _CustomBlock({
    required this.icon,
    required this.title,
    required this.body,
    this.count,
    this.visible = true,
  });

  final IconData icon;
  final String title;
  final Widget body;
  final int? count;
  final bool visible;

  @override
  bool get shouldRender => visible;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BlockHeader(icon: icon, title: title, count: count),
        const SizedBox(height: AppSpacing.s10),
        body,
      ],
    );
  }
}

class _BlockHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;

  const _BlockHeader({required this.icon, required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (count != null && count! > 0)
          Text(
            '$count',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ===========================================================================
// PROFESSIONAL
// ===========================================================================

class _ProfessionalDetailsCard extends StatelessWidget {
  final AppUser user;

  const _ProfessionalDetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final instrumentos = instrumentDisplayLabels(user.professionalInstruments);
    final funcoes = professionalRoleDisplayLabels(user.professionalRoles);
    final generos = genreDisplayLabels(user.professionalGenres);
    final musicLinks = MusicLinkValidator.validLinks(user.musicLinks);

    final blocks = <_DetailsBlock>[
      _ChipsBlock(
        icon: Icons.piano_rounded,
        title: 'INSTRUMENTOS',
        items: instrumentos,
      ),
      _ChipsBlock(
        icon: Icons.engineering_rounded,
        title: 'FUNÇÕES TÉCNICAS',
        items: funcoes,
      ),
      _ChipsBlock(
        icon: Icons.queue_music_rounded,
        title: 'GÊNEROS MUSICAIS',
        items: generos,
      ),
      _CustomBlock(
        icon: Icons.headphones_rounded,
        title: 'OUÇA NAS PLATAFORMAS',
        visible: musicLinks.isNotEmpty,
        body: _MusicLinksRow(musicLinks: musicLinks),
      ),
    ];

    return _DetailsCard(blocks: blocks);
  }
}

// ===========================================================================
// BAND
// ===========================================================================

class _BandDetailsCard extends StatelessWidget {
  final AppUser user;
  final List<AppUser> members;

  const _BandDetailsCard({required this.user, required this.members});

  @override
  Widget build(BuildContext context) {
    final banda = user.dadosBanda;
    final generos = genreDisplayLabels(
      profileStringList(banda?['generosMusicais']),
    );
    final musicLinks = MusicLinkValidator.validLinks(user.musicLinks);
    final accentColor = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);

    final blocks = <_DetailsBlock>[
      _CustomBlock(
        icon: Icons.people_rounded,
        title: 'INTEGRANTES',
        count: members.isNotEmpty ? members.length : null,
        body: BandMembersSection(members: members, accentColor: accentColor),
      ),
      _ChipsBlock(
        icon: Icons.queue_music_rounded,
        title: 'GÊNEROS MUSICAIS',
        items: generos,
      ),
      _CustomBlock(
        icon: Icons.headphones_rounded,
        title: 'OUÇA NAS PLATAFORMAS',
        visible: musicLinks.isNotEmpty,
        body: _MusicLinksRow(musicLinks: musicLinks),
      ),
    ];

    return _DetailsCard(blocks: blocks);
  }
}

// ===========================================================================
// STUDIO
// ===========================================================================

class _StudioDetailsCard extends StatelessWidget {
  final AppUser user;

  const _StudioDetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final estudio = user.dadosEstudio ?? const <String, dynamic>{};
    final studioType = estudio['studioType'] as String?;
    final services = studioServiceDisplayLabels(
      profileStringList(estudio['services']).isNotEmpty
          ? profileStringList(estudio['services'])
          : profileStringList(estudio['servicosOferecidos']),
    );
    final musicLinks = MusicLinkValidator.validLinks(user.musicLinks);

    final String? studioTypeLabel = studioType == null
        ? null
        : (studioType == 'commercial' ? 'Comercial' : 'Home Studio');

    final blocks = <_DetailsBlock>[
      _ChipsBlock(
        icon: Icons.home_work_rounded,
        title: 'TIPO DE ESTÚDIO',
        items: studioTypeLabel == null ? const [] : [studioTypeLabel],
      ),
      _ChipsBlock(
        icon: Icons.graphic_eq_rounded,
        title: 'SERVIÇOS OFERECIDOS',
        items: services,
      ),
      _CustomBlock(
        icon: Icons.headphones_rounded,
        title: 'PORTFÓLIO',
        visible: musicLinks.isNotEmpty,
        body: _MusicLinksRow(musicLinks: musicLinks),
      ),
    ];

    return _DetailsCard(blocks: blocks);
  }
}

// ===========================================================================
// CONTRACTOR
// ===========================================================================

class _ContractorDetailsCard extends StatelessWidget {
  final AppUser user;

  const _ContractorDetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final contractor = user.dadosContratante ?? const <String, dynamic>{};
    final venueTypeId = contractor['venueType'] as String?;
    final amenities = profileStringList(contractor['comodidades']).isNotEmpty
        ? profileStringList(contractor['comodidades'])
        : profileStringList(contractor['amenities']);
    final venueType = venueTypeLabel(venueTypeId);
    final amenityLabels = venueAmenityLabels(amenities);

    final blocks = <_DetailsBlock>[
      _ChipsBlock(
        icon: Icons.storefront_rounded,
        title: 'TIPO DE LOCAL',
        items: (venueType == null || venueType.isEmpty)
            ? const []
            : [venueType],
      ),
      _ChipsBlock(
        icon: Icons.check_circle_outline_rounded,
        title: 'COMODIDADES',
        items: amenityLabels,
      ),
    ];

    return _DetailsCard(blocks: blocks);
  }
}

// ===========================================================================
// MUSIC LINKS
// ===========================================================================

class _MusicLinksRow extends StatelessWidget {
  final Map<String, String> musicLinks;

  const _MusicLinksRow({required this.musicLinks});

  @override
  Widget build(BuildContext context) {
    final entries = <_MusicPlatformEntry>[];
    for (final platform in musicPlatformCatalog) {
      final url = musicLinks[platform.key];
      if (url != null && url.isNotEmpty) {
        entries.add(_MusicPlatformEntry(platform: platform, url: url));
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: entries
          .map(
            (entry) => _MusicLinkPill(platform: entry.platform, url: entry.url),
          )
          .toList(growable: false),
    );
  }
}

class _MusicPlatformEntry {
  final MusicPlatformDefinition platform;
  final String url;

  const _MusicPlatformEntry({required this.platform, required this.url});
}

class _MusicLinkPill extends StatelessWidget {
  final MusicPlatformDefinition platform;
  final String url;

  const _MusicLinkPill({required this.platform, required this.url});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppSnackBar.warning(context, 'Link inválido do ${platform.label}.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !context.mounted) return;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao abrir link musical da plataforma ${platform.key}',
        error,
        stackTrace,
        false,
      );
      if (!context.mounted) return;
    }

    AppSnackBar.info(
      context,
      'Não foi possível abrir ${platform.label} agora.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pill,
        onTap: () => _open(context),
        child: Tooltip(
          message: 'Abrir ${platform.label}',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.pill,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  platform.assetPath,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    platform.color,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  platform.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
