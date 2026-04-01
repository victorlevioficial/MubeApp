import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/image_cache_config.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';
import '../../../profile/domain/media_item.dart';
import '../../../profile/presentation/widgets/public_gallery_grid.dart';
import '../../domain/matchpoint_dynamic_fields.dart';

/// BottomSheet scrollável que exibe o perfil detalhado de um candidato
/// no Matchpoint, sem o botão "Iniciar Conversa".
///
/// Inspirado no modelo do Tinder — ao tocar na foto do candidato,
/// expande para mostrar todas as informações do perfil.
class MatchProfilePreviewSheet extends StatelessWidget {
  final AppUser user;

  const MatchProfilePreviewSheet({super.key, required this.user});

  /// Abre o sheet como modal bottom sheet.
  static Future<void> show(BuildContext context, AppUser user) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.background.withValues(alpha: 0.6),
      builder: (_) => MatchProfilePreviewSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bio = user.profileBio;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final bottomPadding =
            MediaQuery.viewPaddingOf(context).bottom + AppSpacing.s24;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: AppRadius.pill,
                  ),
                ),
              ),
              // Close button row
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.s8,
                    top: AppSpacing.s4,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s24,
                    0,
                    AppSpacing.s24,
                    bottomPadding,
                  ),
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: AppSpacing.s24),
                    _buildNameSection(),
                    const SizedBox(height: AppSpacing.s16),
                    if (bio != null) ...[
                      _buildBioSection(bio),
                      const SizedBox(height: AppSpacing.s24),
                    ],
                    _buildMatchpointHashtags(),
                    _buildTypeSpecificDetails(),
                    _buildGallerySection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Foto grande do candidato com bordas arredondadas.
  Widget _buildPhotoSection() {
    if (user.foto == null || user.foto!.isEmpty) {
      return Container(
        height: 320,
        decoration: const BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: AppRadius.all16,
        ),
        child: const Center(
          child: Icon(Icons.person, size: 80, color: AppColors.textSecondary),
        ),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.all16,
      child: CachedNetworkImage(
        imageUrl: user.foto!,
        height: 320,
        width: double.infinity,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        cacheManager: ImageCacheConfig.profileCacheManager,
        placeholder: (context, url) => Container(
          height: 320,
          color: AppColors.surfaceHighlight,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 320,
          color: AppColors.surfaceHighlight,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Nome, tipo de perfil e localização.
  Widget _buildNameSection() {
    final displayName = user.appDisplayName.isNotEmpty
        ? user.appDisplayName
        : (user.nome ?? 'Usuário');
    final location = user.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile type badge
        Row(
          children: [
            Icon(
              _getProfileIcon(user.tipoPerfil),
              color: _getProfileColor(user.tipoPerfil),
              size: 18,
            ),
            const SizedBox(width: AppSpacing.s4),
            Text(
              _getProfileLabel(user.tipoPerfil),
              style: AppTypography.labelSmall.copyWith(
                color: _getProfileColor(user.tipoPerfil),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        // Name
        Text(
          displayName,
          style: AppTypography.headlineMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Subtitle (roles / type description)
        const SizedBox(height: AppSpacing.s4),
        Text(
          _getSubtitle(),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Location
        if (location != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Text(
                  '${location['cidade'] ?? '-'}, ${location['estado'] ?? '-'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Seção de bio / sobre.
  Widget _buildBioSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sobre', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          bio,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Hashtags do matchpoint profile do candidato.
  Widget _buildMatchpointHashtags() {
    final mp = user.matchpointProfile;
    if (mp == null) return const SizedBox.shrink();

    final hashtags = matchpointStringList(mp['hashtags']);
    if (hashtags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hashtags', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: hashtags
                .map((tag) => tag.replaceFirst(RegExp(r'^#+'), ''))
                .where((tag) => tag.isNotEmpty)
                .map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      '#$tag',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Detalhes por tipo de perfil (instrumentos, gêneros, serviços, etc).
  Widget _buildTypeSpecificDetails() {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return _buildProfessionalDetails();
      case AppUserType.band:
        return _buildBandDetails();
      case AppUserType.studio:
        return _buildStudioDetails();
      case AppUserType.contractor:
        return _buildContractorDetails();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfessionalDetails() {
    final prof = user.dadosProfissional;
    if (prof == null) return const SizedBox.shrink();

    final instrumentos = matchpointStringList(prof['instrumentos']);
    final funcoes = matchpointStringList(prof['funcoes']);
    final generos = matchpointStringList(prof['generosMusicais']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (instrumentos.isNotEmpty)
          _buildChipsSection('Instrumentos', instrumentos),
        if (funcoes.isNotEmpty) _buildChipsSection('Funções Técnicas', funcoes),
        if (generos.isNotEmpty) _buildChipsSection('Gêneros Musicais', generos),
      ],
    );
  }

  Widget _buildBandDetails() {
    final banda = user.dadosBanda;
    if (banda == null) return const SizedBox.shrink();

    final generos = matchpointStringList(banda['generosMusicais']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (generos.isNotEmpty) _buildChipsSection('Gêneros Musicais', generos),
      ],
    );
  }

  Widget _buildStudioDetails() {
    final estudio = user.dadosEstudio;
    if (estudio == null) return const SizedBox.shrink();

    final services = {
      ...matchpointStringList(estudio['services']),
      ...matchpointStringList(estudio['servicosOferecidos']),
    }.toList(growable: false);
    final studioType = estudio['studioType'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (studioType != null)
          _buildChipsSection('Tipo', [
            studioType == 'commercial' ? 'Comercial' : 'Home Studio',
          ]),
        if (services.isNotEmpty) _buildChipsSection('Serviços', services),
      ],
    );
  }

  Widget _buildContractorDetails() {
    final contratante = user.dadosContratante;
    if (contratante == null) return const SizedBox.shrink();

    final genero = contratante['genero'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (genero != null && genero.isNotEmpty)
          _buildChipsSection('Gênero', [genero]),
      ],
    );
  }

  Widget _buildChipsSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: items.map((item) {
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
                  item,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Galeria de fotos e vídeos extraída dos dados do user.
  Widget _buildGallerySection() {
    final List<dynamic> galleryData;

    switch (user.tipoPerfil) {
      case AppUserType.professional:
        galleryData =
            user.dadosProfissional?['gallery'] as List<dynamic>? ?? [];
        break;
      case AppUserType.band:
        galleryData = user.dadosBanda?['gallery'] as List<dynamic>? ?? [];
        break;
      case AppUserType.studio:
        galleryData = user.dadosEstudio?['gallery'] as List<dynamic>? ?? [];
        break;
      case AppUserType.contractor:
        galleryData = user.dadosContratante?['gallery'] as List<dynamic>? ?? [];
        break;
      default:
        galleryData = [];
    }

    final gallery =
        matchpointStringMapList(galleryData).map(MediaItem.fromJson).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    if (gallery.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Galeria', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s12),
        PublicGalleryGrid(items: gallery),
      ],
    );
  }

  // --- Helpers ---

  String _getSubtitle() {
    if (user.tipoPerfil == AppUserType.professional) {
      final roles = matchpointStringList(user.dadosProfissional?['funcoes']);
      if (roles.isNotEmpty) {
        return roles.join(' • ');
      }
    }
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return 'Músico Profissional';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Estúdio';
      case AppUserType.contractor:
        return 'Contratante';
      default:
        return 'Usuário';
    }
  }

  IconData _getProfileIcon(AppUserType? type) {
    switch (type) {
      case AppUserType.professional:
        return Icons.music_note;
      case AppUserType.band:
        return Icons.groups;
      case AppUserType.studio:
        return Icons.headphones;
      default:
        return Icons.person;
    }
  }

  Color _getProfileColor(AppUserType? type) {
    switch (type) {
      case AppUserType.professional:
        return AppColors.badgeMusician;
      case AppUserType.band:
        return AppColors.badgeBand;
      case AppUserType.studio:
        return AppColors.badgeStudio;
      default:
        return AppColors.badgeMusician;
    }
  }

  String _getProfileLabel(AppUserType? type) {
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
}
