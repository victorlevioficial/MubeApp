import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_shimmer.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/user_avatar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          // Pre-cache avatar for faster loading on edit screen
          if (user.foto != null && user.foto!.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(user.foto!), context);
          }

          // Helper to format categories
          String formatCategory(String cat) {
            switch (cat) {
              case 'singer':
                return 'Cantor(a)';
              case 'instrumentalist':
                return 'Instrumentista';
              case 'band':
                return 'Banda';
              case 'dj':
                return 'DJ';
              case 'crew':
                return 'Equipe Técnica';
              case 'other':
                return 'Outro';
              default:
                return cat;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s24,
              vertical: AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Avatar + Name)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.s32),
                      UserAvatar(
                        size: 100,
                        photoUrl: user.foto,
                        name: _getDisplayName(user),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        _getDisplayName(user),
                        style: AppTypography.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        user.tipoPerfil?.label.toUpperCase() ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_getDisplayName(user) != user.nome) ...[
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          user.nome ?? '',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (user.location != null) ...[
                        const SizedBox(height: AppSpacing.s8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.location?['bairro'] ?? user.location?['cidade'] ?? '-'}, ${user.location?['estado'] ?? '-'}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s32),
                const Divider(color: AppColors.surfaceHighlight),
                const SizedBox(height: AppSpacing.s24),

                // Type Specific Details
                if (user.tipoPerfil == AppUserType.professional)
                  _buildProfessionalDetails(user, formatCategory),
                if (user.tipoPerfil == AppUserType.band)
                  _buildBandDetails(user),
                if (user.tipoPerfil == AppUserType.studio)
                  _buildStudioDetails(user),
                if (user.tipoPerfil == AppUserType.contractor)
                  _buildContractorDetails(user),

                const SizedBox(height: AppSpacing.s24),
                // Actions
                PrimaryButton(
                  text: 'Editar Perfil',
                  onPressed: () => context.go('/profile/edit'),
                ),
                const SizedBox(height: AppSpacing.s48),
                const SizedBox(height: 40),
                Align(
                  child: IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const ProfileCardSkeleton(),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  String _getDisplayName(AppUser user) {
    if (user.tipoPerfil == AppUserType.professional) {
      return user.dadosProfissional?['nomeArtistico'] ?? user.nome ?? '';
    } else if (user.tipoPerfil == AppUserType.studio) {
      return user.dadosEstudio?['nomeArtistico'] ?? user.nome ?? '';
    }
    return user.nome ?? '';
  }

  Widget _buildProfessionalDetails(
    AppUser user,
    String Function(String) formatter,
  ) {
    final profissional = user.dadosProfissional;
    final categorias =
        (profissional?['categorias'] as List?)?.cast<String>() ?? [];
    final instrumentos =
        (profissional?['instrumentos'] as List?)?.cast<String>() ?? [];
    final generos =
        (profissional?['generosMusicais'] as List?)?.cast<String>() ?? [];
    final funcoes = (profissional?['funcoes'] as List?)?.cast<String>() ?? [];

    final displayCategorias = categorias.map(formatter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (displayCategorias.isNotEmpty)
          _buildInfoSection('Atuação', displayCategorias),
        if (instrumentos.isNotEmpty)
          _buildInfoSection('Instrumentos', instrumentos),
        if (funcoes.isNotEmpty) _buildInfoSection('Funções Técnicas', funcoes),
        if (generos.isNotEmpty) _buildInfoSection('Gêneros Musicais', generos),
      ],
    );
  }

  Widget _buildBandDetails(AppUser user) {
    final banda = user.dadosBanda;
    final generos = (banda?['generosMusicais'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (generos.isNotEmpty) _buildInfoSection('Gêneros Musicais', generos),
      ],
    );
  }

  Widget _buildStudioDetails(AppUser user) {
    final estudio = user.dadosEstudio;
    final servicos =
        (estudio?['servicosOferecidos'] as List?)?.cast<String>() ?? [];
    final type = estudio?['studioType'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (type != null)
          _buildInfoSection('Tipo', [
            type == 'commercial' ? 'Comercial' : 'Home Studio',
          ]),
        if (servicos.isNotEmpty)
          _buildInfoSection('Serviços Oferecidos', servicos),
      ],
    );
  }

  Widget _buildContractorDetails(AppUser user) {
    final contratante = user.dadosContratante;
    final instagram = contratante?['instagram'] as String?;
    final genero = contratante?['genero'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (genero != null && genero.isNotEmpty)
          _buildInfoSection('Gênero', [genero]),
        if (instagram != null && instagram.isNotEmpty)
          _buildInfoSection('Instagram', [instagram]),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items.map((item) {
            return Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                item,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.surfaceHighlight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }
}
