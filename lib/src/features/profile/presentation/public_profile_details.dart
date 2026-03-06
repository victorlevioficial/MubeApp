part of 'public_profile_screen.dart';

class _TypeDetails extends StatelessWidget {
  final AppUser user;
  final List<AppUser> bandMembers;

  const _TypeDetails({required this.user, required this.bandMembers});

  @override
  Widget build(BuildContext context) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return _ProfessionalDetails(user: user);
      case AppUserType.band:
        return _BandDetails(user: user, members: bandMembers);
      case AppUserType.studio:
        return _StudioDetails(user: user);
      case AppUserType.contractor:
        return _ContractorDetails(user: user);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ProfessionalDetails extends StatelessWidget {
  final AppUser user;

  const _ProfessionalDetails({required this.user});

  @override
  Widget build(BuildContext context) {
    final prof = user.dadosProfissional;
    if (prof == null) return const SizedBox.shrink();

    final instrumentos = (prof['instrumentos'] as List?)?.cast<String>() ?? [];
    final funcoes = (prof['funcoes'] as List?)?.cast<String>() ?? [];
    final generos = (prof['generosMusicais'] as List?)?.cast<String>() ?? [];
    final color = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (instrumentos.isNotEmpty) ...[
          _InfoCard(
            icon: Icons.piano_rounded,
            title: 'Instrumentos',
            accentColor: color,
            child: _ChipWrap(
              items: instrumentos,
              accentColor: color,
              isSkill: true,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        if (funcoes.isNotEmpty) ...[
          _InfoCard(
            icon: Icons.engineering_rounded,
            title: 'Fun\u00E7\u00F5es T\u00E9cnicas',
            accentColor: color,
            child: _ChipWrap(items: funcoes, accentColor: color, isSkill: true),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        if (generos.isNotEmpty)
          _InfoCard(
            icon: Icons.queue_music_rounded,
            title: 'G\u00EAneros Musicais',
            accentColor: color,
            child: _ChipWrap(items: generos, accentColor: color),
          ),
      ],
    );
  }
}

class _BandDetails extends StatelessWidget {
  final AppUser user;
  final List<AppUser> members;

  const _BandDetails({required this.user, required this.members});

  @override
  Widget build(BuildContext context) {
    final banda = user.dadosBanda;
    final generos = (banda?['generosMusicais'] as List?)?.cast<String>() ?? [];
    final color = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          icon: Icons.people_rounded,
          title: 'Integrantes',
          accentColor: color,
          count: members.isNotEmpty ? members.length : null,
          child: BandMembersSection(members: members, accentColor: color),
        ),
        if (generos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          _InfoCard(
            icon: Icons.queue_music_rounded,
            title: 'G\u00EAneros Musicais',
            accentColor: color,
            child: _ChipWrap(items: generos, accentColor: color),
          ),
        ],
      ],
    );
  }
}

class _StudioDetails extends StatelessWidget {
  final AppUser user;

  const _StudioDetails({required this.user});

  @override
  Widget build(BuildContext context) {
    final estudio = user.dadosEstudio;
    if (estudio == null) return const SizedBox.shrink();

    final studioType = estudio['studioType'] as String?;
    final services =
        (estudio['services'] as List?)?.cast<String>() ??
        (estudio['servicosOferecidos'] as List?)?.cast<String>() ??
        [];
    final color = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);

    String? studioTypeLabel;
    if (studioType != null) {
      studioTypeLabel = studioType == 'commercial'
          ? 'Comercial'
          : 'Home Studio';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (studioTypeLabel != null) ...[
          _InfoCard(
            icon: Icons.home_work_rounded,
            title: 'Tipo de Est\u00FAdio',
            accentColor: color,
            child: _ChipWrap(
              items: [studioTypeLabel],
              accentColor: color,
              isSkill: true,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        if (services.isNotEmpty)
          _InfoCard(
            icon: Icons.graphic_eq_rounded,
            title: 'Servi\u00E7os Oferecidos',
            accentColor: color,
            child: _ChipWrap(
              items: services,
              accentColor: color,
              isSkill: true,
            ),
          ),
      ],
    );
  }
}

class _ContractorDetails extends StatelessWidget {
  final AppUser user;

  const _ContractorDetails({required this.user});

  @override
  Widget build(BuildContext context) {
    final contratante = user.dadosContratante;
    if (contratante == null) return const SizedBox.shrink();

    final genero = contratante['genero'] as String?;
    final color = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);

    final hasGenero = genero != null && genero.isNotEmpty;

    if (!hasGenero) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasGenero)
          _InfoCard(
            icon: Icons.person_outline_rounded,
            title: 'Gênero',
            accentColor: color,
            child: _ChipWrap(items: [genero], accentColor: color),
          ),
      ],
    );
  }
}

// Shared UI components

/// Card container for a profile information section.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget child;
  final int? count;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.child,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(child: Text(title, style: AppTypography.titleSmall)),
              if (count != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.labelSmall.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          child,
        ],
      ),
    );
  }
}

/// Bio card with "Sobre" section styling.
class _BioCard extends StatelessWidget {
  final String bio;

  const _BioCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text('Sobre', style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            bio,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrap of chip widgets.
class _ChipWrap extends StatelessWidget {
  final List<String> items;
  final Color accentColor;
  final bool isSkill;

  const _ChipWrap({
    required this.items,
    required this.accentColor,
    this.isSkill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: items.map((item) {
        if (isSkill) {
          return _SkillChip(label: item, accentColor: accentColor);
        }
        return _GenreChip(label: item);
      }).toList(),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _SkillChip({required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.pill,
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;

  const _GenreChip({required this.label});

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
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
