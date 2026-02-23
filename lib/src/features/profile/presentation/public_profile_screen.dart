import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_constants.dart';
import '../../../design_system/components/data_display/user_avatar.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_shimmer.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../domain/media_item.dart';
import 'public_profile_controller.dart';
import 'widgets/media_viewer_dialog.dart';
import 'widgets/public_gallery_grid.dart';
import 'widgets/report_reason_dialog.dart';

/// Screen to view another user's public profile.
class PublicProfileScreen extends ConsumerWidget {
  final String uid;

  const PublicProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(publicProfileControllerProvider(uid));
    final user = stateAsync.value?.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: user != null ? _buildAppBarTitle(user) : 'Perfil',
        onBackPressed: () => context.pop(),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            color: AppColors.surface,
            surfaceTintColor: AppColors.transparent,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.all12),
            onSelected: (value) => _handleMenuAction(context, ref, value, user),
            itemBuilder: (context) => [
              _buildMenuItem(
                icon: Icons.share,
                label: 'Compartilhar Perfil',
                value: 'share',
              ),
              _buildMenuItem(
                icon: Icons.link,
                label: 'Copiar Link',
                value: 'copy',
              ),
              const PopupMenuDivider(),
              const PopupMenuDivider(),
              _buildMenuItem(
                icon: Icons.block,
                label: 'Bloquear',
                value: 'block',
                isDestructive: true,
              ),
              _buildMenuItem(
                icon: Icons.flag_outlined,
                label: 'Denunciar',
                value: 'report',
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
      body: stateAsync.when(
        data: (state) {
          if (state.isLoading) return const ProfileSkeleton();

          if (state.error != null) {
            return Center(
              child: Text(
                state.error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            );
          }

          if (state.user == null) {
            return const Center(child: Text('Usuário não encontrado'));
          }

          return _buildProfileContent(context, state.user!, state.galleryItems);
        },
        loading: () => const ProfileSkeleton(),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
      bottomNavigationBar: stateAsync.value?.user != null
          ? _buildBottomActionBar(context, ref, stateAsync.value!.user!)
          : null,
    );
  }

  /// Builds the AppBar title with colored icon and profile type
  Widget _buildAppBarTitle(AppUser user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getProfileIcon(user.tipoPerfil),
          color: _getProfileColor(user.tipoPerfil),
          size: 20,
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          _getProfileLabel(user.tipoPerfil),
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Builds a popup menu item
  PopupMenuEntry<String> _buildMenuItem({
    required IconData icon,
    required String label,
    required String value,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.s12),
          Text(label, style: AppTypography.bodyMedium.copyWith(color: color)),
        ],
      ),
    );
  }

  /// Handles menu item selection
  /// Handles menu item selection
  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    AppUser? user,
  ) async {
    if (user == null) return;
    final controller = ref.read(publicProfileControllerProvider(uid).notifier);

    switch (action) {
      case 'share':
        final displayName = _getDisplayName(user);
        await SharePlus.instance.share(
          ShareParams(
            text: 'Confira meu perfil no Mube: https://mube.app/profile/$uid',
            subject: 'Perfil de $displayName no Mube',
          ),
        );
        break;
      case 'copy':
        await Clipboard.setData(
          ClipboardData(text: 'https://mube.app/profile/$uid'),
        );
        if (context.mounted) {
          AppSnackBar.success(
            context,
            'Link copiado para a área de transferência!',
          );
        }
        break;
      case 'block':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => const AppConfirmationDialog(
            title: 'Bloquear Usuário?',
            message:
                'Você não verá mais conteúdo deste usuário. Esta ação pode ser desfeita nas configurações.',
            confirmText: 'Bloquear',
            isDestructive: true,
          ),
        );

        if (confirmed == true && context.mounted) {
          final success = await controller.blockUser();
          if (context.mounted) {
            if (success) {
              AppSnackBar.success(context, 'Usuário bloqueado');
              context.pop(); // Exit profile
            } else {
              AppSnackBar.error(context, 'Erro ao bloquear usuário');
            }
          }
        }
        break;

      case 'report':
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => const ReportReasonDialog(),
        );

        if (result != null && context.mounted) {
          final reason = result['reason'] as String;
          final description = result['description'] as String?;

          final success = await controller.reportUser(reason, description);
          if (context.mounted) {
            if (success) {
              AppSnackBar.success(context, 'Denúncia enviada para análise');
            } else {
              AppSnackBar.error(context, 'Erro ao enviar denúncia');
            }
          }
        }
        break;
    }
  }

  /// Gets the icon for a profile type
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

  /// Gets the color for a profile type
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

  /// Gets the label for a profile type
  String _getProfileLabel(AppUserType? type) {
    switch (type) {
      case AppUserType.professional:
        return 'Músico';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Estúdio';
      default:
        return 'Perfil';
    }
  }

  /// Fixed bottom bar with Chat and Like buttons
  Widget _buildBottomActionBar(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    final isMe = currentUser?.uid == uid;

    if (isMe) {
      return Container(
        padding: EdgeInsets.only(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          top: AppSpacing.s12,
          bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.background.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.tipoPerfil == AppUserType.band) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(RoutePaths.manageMembers),
                  icon: const Icon(Icons.groups, size: 20),
                  label: const Text('Gerenciar Integrantes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56, // Same height as PrimaryButton
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/profile/edit'),
                      icon: const Icon(Icons.edit, size: 20),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.all16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: SizedBox(
                    height: 56, // Same height
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(authRepositoryProvider).signOut(),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Sair'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(
                          color: AppColors.error,
                          width: 1.5,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.all16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s12,
        bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Chat Button (Primary action - Full Width)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => ref
                  .read(publicProfileControllerProvider(uid).notifier)
                  .openChat(context),
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('Iniciar Conversa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: AppSpacing.v12,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.all12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    AppUser user,
    List<MediaItem> galleryItems,
  ) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    if (isWide) {
      return _buildWideProfileContent(context, user, galleryItems);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          _buildHeader(user),

          const SizedBox(height: AppSpacing.s24),

          // Bio Section
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            _buildBioSection(user.bio!),
            const SizedBox(height: AppSpacing.s24),
          ],

          // Type-specific details
          _buildTypeSpecificDetails(user),

          // Gallery Section (always show)
          const SizedBox(height: AppSpacing.s24),
          _buildGallerySection(context, galleryItems),

          // Extra padding at bottom to not overlap with fixed bar
          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }

  Widget _buildWideProfileContent(
    BuildContext context,
    AppUser user,
    List<MediaItem> galleryItems,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s32),
      child: ResponsiveCenter(
        padding: EdgeInsets.zero,
        maxContentWidth: 1200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coluna Esquerda: Header & Bio
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(user),
                  const SizedBox(height: AppSpacing.s32),
                  if (user.bio != null && user.bio!.isNotEmpty)
                    _buildBioSection(user.bio!),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s48),
            // Coluna Direita: Detalhes & Galeria
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeSpecificDetails(user),
                  const SizedBox(height: AppSpacing.s32),
                  _buildGallerySection(context, galleryItems),
                  const SizedBox(height: AppSpacing.s48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppUser user) {
    final displayName = _getDisplayName(user);
    final location = user.location;

    return Center(
      child: Column(
        children: [
          // Avatar with Hero Transition
          Hero(
            tag: 'avatar-${user.uid}',
            child: UserAvatar(
              size: 120,
              photoUrl: user.foto,
              name: displayName,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),

          // Display Name (artistic name / band name / studio name)
          Text(
            displayName,
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),

          // Subcategories with Icons (for professionals)
          if (user.tipoPerfil == AppUserType.professional) ...[
            const SizedBox(height: AppSpacing.s8),
            _buildSubCategoriesRow(user),
          ],

          // Location
          if (location != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.s4),
                Text(
                  '${location['cidade'] ?? '-'}, ${location['estado'] ?? '-'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _buildTypeSpecificDetails(AppUser user) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return _buildProfessionalDetails(user);
      case AppUserType.band:
        return _buildBandDetails(user);
      case AppUserType.studio:
        return _buildStudioDetails(user);
      case AppUserType.contractor:
        return _buildContractorDetails(user);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfessionalDetails(AppUser user) {
    final prof = user.dadosProfissional;
    if (prof == null) return const SizedBox.shrink();

    final instrumentos = (prof['instrumentos'] as List?)?.cast<String>() ?? [];
    final funcoes = (prof['funcoes'] as List?)?.cast<String>() ?? [];
    final generos = (prof['generosMusicais'] as List?)?.cast<String>() ?? [];

    final skills = [...instrumentos, ...funcoes];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (skills.isNotEmpty)
          _buildChipsSection('Habilidades', skills, isSkill: true),
        if (generos.isNotEmpty)
          _buildChipsSection('Gêneros Musicais', generos, isSkill: false),
      ],
    );
  }

  Widget _buildBandDetails(AppUser user) {
    final banda = user.dadosBanda;
    if (banda == null) return const SizedBox.shrink();

    final generos = (banda['generosMusicais'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (generos.isNotEmpty)
          _buildChipsSection('Gêneros Musicais', generos, isSkill: false),
      ],
    );
  }

  Widget _buildStudioDetails(AppUser user) {
    final estudio = user.dadosEstudio;
    if (estudio == null) return const SizedBox.shrink();

    final services =
        (estudio['services'] as List?)?.cast<String>() ??
        (estudio['servicosOferecidos'] as List?)?.cast<String>() ??
        [];
    final studioType = estudio['studioType'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (studioType != null)
          _buildChipsSection('Tipo', [
            studioType == 'commercial' ? 'Comercial' : 'Home Studio',
          ], isSkill: true),
        if (services.isNotEmpty)
          _buildChipsSection('Serviços', services, isSkill: true),
      ],
    );
  }

  Widget _buildContractorDetails(AppUser user) {
    final contratante = user.dadosContratante;
    if (contratante == null) return const SizedBox.shrink();

    final genero = contratante['genero'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (genero != null && genero.isNotEmpty)
          _buildChipsSection('Gênero', [genero], isSkill: true),
      ],
    );
  }

  Widget _buildChipsSection(
    String title,
    List<String> items, {
    required bool isSkill,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              if (isSkill) {
                return _buildSkillChip(item);
              } else {
                return _buildGenreChip(item);
              }
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String label) {
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
        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildGenreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight, // Matches skill chip
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildGallerySection(
    BuildContext context,
    List<MediaItem> galleryItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Galeria', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s12),
        if (galleryItems.isEmpty)
          Container(
            width: double.infinity,
            padding: AppSpacing.v32,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all12,
              border: Border.all(color: AppColors.surfaceHighlight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Galeria Vazia',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Este usuário ainda não adicionou fotos ou vídeos.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          PublicGalleryGrid(
            items: galleryItems,
            onItemTap: (index) {
              _showMediaViewer(context, galleryItems, index);
            },
          ),
      ],
    );
  }

  void _showMediaViewer(
    BuildContext context,
    List<MediaItem> items,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: AppColors.background.withValues(alpha: 0.87),
      builder: (context) =>
          MediaViewerDialog(items: items, initialIndex: initialIndex),
    );
  }

  String _getDisplayName(AppUser user) {
    return user.appDisplayName;
  }

  Widget _buildSubCategoriesRow(AppUser user) {
    final ids = user.dadosProfissional?['categorias'] as List? ?? [];
    if (ids.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    for (final id in ids) {
      final config = professionalCategories.firstWhere(
        (c) => c['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (config.isEmpty) continue;

      widgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config['icon'] as IconData,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.s4),
            Text(
              config['label'] as String,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: widgets,
    );
  }
}
