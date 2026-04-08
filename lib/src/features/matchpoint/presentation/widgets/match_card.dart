import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

import '../../../../constants/firestore_constants.dart';
import '../../../../core/services/image_cache_config.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/user_type.dart';
import '../../domain/matchpoint_dynamic_fields.dart';

class MatchCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onTap;
  final List<String>? currentUserGenres;

  const MatchCard({
    super.key,
    required this.user,
    this.onTap,
    this.currentUserGenres,
  });

  @override
  Widget build(BuildContext context) {
    final cacheWidth = _resolveCardCacheWidth(context);
    final cacheHeight = cacheWidth * 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.all24,
          color: AppColors.surface,
          boxShadow: AppEffects.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.all24,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              if (user.foto case final fotoUrl? when fotoUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: fotoUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: cacheWidth,
                  memCacheHeight: cacheHeight,
                  maxWidthDiskCache: cacheWidth,
                  maxHeightDiskCache: cacheHeight,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  useOldImageOnUrlChange: false,
                  cacheManager: ImageCacheConfig.profileCacheManager,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceHighlight,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceHighlight,
                    child: const Icon(
                      Icons.person_off,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Container(
                  color: AppColors.surfaceHighlight,
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                ),

              // 2. Gradient Overlay for Text Readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.transparent,
                        AppColors.transparent,
                        AppColors.background.withValues(alpha: 0.8),
                        AppColors.background.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. "Tap to see more" hint
              if (onTap != null)
                Positioned(
                  top: AppSpacing.s16,
                  right: AppSpacing.s16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.expand_more,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        Text(
                          'Ver mais',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Content Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Compatibility Badge
                      if (_getGenreCompatibility() > 0)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s12,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s12,
                              vertical: AppSpacing.s4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.9),
                              borderRadius: AppRadius.pill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.music_note,
                                  color: AppColors.textPrimary,
                                  size: 16,
                                ),
                                const SizedBox(width: AppSpacing.s4),
                                Text(
                                  '${_getGenreCompatibility()} gênero${_getGenreCompatibility() > 1 ? "s" : ""} em comum',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Name & Age
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getDisplayName(),
                              style: AppTypography.headlineMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_getAge() != null) ...[
                            const SizedBox(width: AppSpacing.s8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s8,
                                vertical: AppSpacing.s4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: AppRadius.all8,
                              ),
                              child: Text(
                                '${_getAge()}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight:
                                      AppTypography.buttonPrimary.fontWeight,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: AppSpacing.s4),

                      // Role / Bio Snippet
                      Text(
                        _getSubtitle(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppSpacing.s12),

                      // Filter Chips (Tags)
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        children: _getTags().take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s12,
                              vertical: AppSpacing.s8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.8),
                              borderRadius: AppRadius.pill,
                              border: Border.all(
                                color: AppColors.surfaceHighlight,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight:
                                    AppTypography.buttonPrimary.fontWeight,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _resolveCardCacheWidth(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final requestedWidth = (viewportWidth * pixelRatio).round();
    if (requestedWidth < ImageCacheConfig.minDecodeDimensionPx) {
      return ImageCacheConfig.minDecodeDimensionPx;
    }
    if (requestedWidth > 720) return 720;
    return requestedWidth;
  }

  String _getDisplayName() {
    final display = user.appDisplayName;
    if (display.trim().isNotEmpty) return display.trim();
    return user.nome ?? 'Usuario';
  }

  String? _getAge() {
    return null;
  }

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

  List<String> _getTags() {
    final List<String> tags = [];
    if (user.tipoPerfil == AppUserType.professional) {
      tags.addAll(
        matchpointStringList(user.dadosProfissional?['generosMusicais']),
      );
    } else if (user.tipoPerfil == AppUserType.band) {
      tags.addAll(matchpointStringList(user.dadosBanda?['generosMusicais']));
    }

    if (tags.isEmpty && user.matchpointProfile != null) {
      tags.addAll(
        matchpointStringList(
          user.matchpointProfile?[FirestoreFields.musicalGenres],
        ),
      );

      if (tags.isEmpty) {
        tags.addAll(
          matchpointStringList(user.matchpointProfile?['musicalGenres']),
        );
      }

      if (tags.isEmpty) {
        tags.addAll(
          matchpointStringList(user.matchpointProfile?['musical_genres']),
        );
      }

      if (tags.isEmpty) {
        tags.addAll(matchpointStringList(user.matchpointProfile?['genres']));
      }
    }

    return tags;
  }

  /// Calcula quantos gêneros em comum entre o usuário atual e o candidato
  int _getGenreCompatibility() {
    final userGenres = currentUserGenres;
    if (userGenres == null || userGenres.isEmpty) return 0;

    final candidateGenres = _getTags();
    if (candidateGenres.isEmpty) return 0;

    // Conta quantos gêneros do candidato estão na lista do usuário atual
    final commonGenres = candidateGenres
        .where((g) => userGenres.contains(g))
        .length;

    return commonGenres;
  }
}
