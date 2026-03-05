import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/image_cache_config.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/interactions/app_popup_menu_button.dart';
import '../../../design_system/components/loading/app_shimmer.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_icons.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/instagram_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../domain/media_item.dart';
import 'public_profile_controller.dart';
import 'widgets/band_members_section.dart';
import 'widgets/media_viewer_dialog.dart';
import 'widgets/profile_gallery_tabs.dart';
import 'widgets/profile_hero_header.dart';
import 'widgets/report_reason_dialog.dart';

/// Public profile screen Ã¢â‚¬â€ the digital business card of a Mube user.
///
/// Differentiates visually between:
/// - [AppUserType.professional] Ã¢â‚¬â€ pink/red accent
/// - [AppUserType.band]         Ã¢â‚¬â€ fuchsia accent + members section
/// - [AppUserType.studio]       Ã¢â‚¬â€ red accent
/// - [AppUserType.contractor]   Ã¢â‚¬â€ amber accent
class PublicProfileScreen extends ConsumerWidget {
  final String uid;
  final String? avatarHeroTag;
  static const double _topActionSize = AppSpacing.s48;

  const PublicProfileScreen({super.key, required this.uid, this.avatarHeroTag});

  // Ã¢â€â‚¬Ã¢â€â‚¬ Helpers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  String _displayName(AppUser user) => user.appDisplayName;

  // Ã¢â€â‚¬Ã¢â€â‚¬ Build Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(publicProfileControllerProvider(uid));
    final user = stateAsync.value?.user;
    final resolvedAvatarHeroTag = avatarHeroTag ?? 'avatar-$uid';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: stateAsync.when(
              data: (state) {
                if (state.isLoading) return _buildLoadingState(context);
                if (state.error != null) {
                  return _ErrorBody(message: state.error!);
                }
                if (state.user == null) {
                  return const _ErrorBody(
                    message: 'Usu\u00E1rio n\u00E3o encontrado.',
                  );
                }
                return _ProfileBody(
                  user: state.user!,
                  galleryItems: state.galleryItems,
                  bandMembers: state.bandMembers,
                  uid: uid,
                  avatarHeroTag: resolvedAvatarHeroTag,
                  onAvatarTap: () => _showAvatarViewer(
                    context,
                    state.user!,
                    resolvedAvatarHeroTag,
                  ),
                  onMediaTap: (index, items) =>
                      _showMediaViewer(context, items, index),
                );
              },
              loading: () => _buildLoadingState(context),
              error: (err, _) => _ErrorBody(message: 'Erro: $err'),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopActions(context, ref, user),
          ),
        ],
      ),
      bottomNavigationBar: stateAsync.value?.user != null
          ? _buildBottomBar(context, ref, stateAsync.value!.user!)
          : null,
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ AppBar title Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  // Ã¢â€â‚¬Ã¢â€â‚¬ Menu items Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Widget _buildTopActions(BuildContext context, WidgetRef ref, AppUser? user) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s12,
          AppSpacing.s8,
          AppSpacing.s12,
          0,
        ),
        child: Row(
          children: [
            _topActionShell(
              child: IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                constraints: const BoxConstraints.tightFor(
                  width: _topActionSize,
                  height: _topActionSize,
                ),
                icon: const Icon(
                  AppIcons.arrowBackCompact,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => context.pop(),
                tooltip: 'Voltar',
              ),
            ),
            const Spacer(),
            _topActionShell(
              child: AppPopupMenuButton<String>(
                enabled: user != null,
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: user != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                onSelected: user == null
                    ? null
                    : (value) => _handleMenuAction(context, ref, value, user),
                items: const [
                  AppPopupMenuAction<String>(
                    value: 'share',
                    label: 'Compartilhar Perfil',
                    icon: Icons.share_outlined,
                  ),
                  AppPopupMenuAction<String>(
                    value: 'copy',
                    label: 'Copiar Link',
                    icon: Icons.link_rounded,
                  ),
                  AppPopupMenuAction<String>(
                    value: 'block',
                    label: 'Bloquear',
                    icon: Icons.block_rounded,
                    isDestructive: true,
                    showDividerBefore: true,
                  ),
                  AppPopupMenuAction<String>(
                    value: 'report',
                    label: 'Denunciar',
                    icon: Icons.flag_outlined,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topActionShell({required Widget child}) {
    return Container(
      width: _topActionSize,
      height: _topActionSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: child,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const _PublicProfileSkeleton();
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Menu actions Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    AppUser? user,
  ) async {
    if (user == null) return;
    final controller = ref.read(publicProfileControllerProvider(uid).notifier);

    switch (action) {
      case 'share':
        await SharePlus.instance.share(
          ShareParams(
            text: 'Confira meu perfil no Mube: https://mube.app/profile/$uid',
            subject: 'Perfil de ${_displayName(user)} no Mube',
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
            'Link copiado para a \u00E1rea de transfer\u00EAncia!',
          );
        }
        break;

      case 'block':
        final confirmed = await AppOverlay.dialog<bool>(
          context: context,
          builder: (context) => const AppConfirmationDialog(
            title: 'Bloquear Usu\u00E1rio?',
            message:
                'Voc\u00EA n\u00E3o ver\u00E1 mais conte\u00FAdo deste usu\u00E1rio. '
                'Esta a\u00E7\u00E3o pode ser desfeita nas configura\u00E7\u00F5es.',
            confirmText: 'Bloquear',
            isDestructive: true,
          ),
        );
        if (confirmed == true && context.mounted) {
          final success = await controller.blockUser();
          if (context.mounted) {
            if (success) {
              AppSnackBar.success(context, 'Usu\u00E1rio bloqueado.');
              context.pop();
            } else {
              AppSnackBar.error(context, 'Erro ao bloquear usu\u00E1rio.');
            }
          }
        }
        break;

      case 'report':
        final result = await AppOverlay.dialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => const ReportReasonDialog(),
        );
        if (result != null && context.mounted) {
          final reason = result['reason'] as String;
          final description = result['description'] as String?;
          final success = await controller.reportUser(reason, description);
          if (context.mounted) {
            if (success) {
              AppSnackBar.success(
                context,
                'Den\u00FAncia enviada para an\u00E1lise.',
              );
            } else {
              AppSnackBar.error(context, 'Erro ao enviar den\u00FAncia.');
            }
          }
        }
        break;
    }
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Media viewers Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  void _showMediaViewer(
    BuildContext context,
    List<MediaItem> items,
    int initialIndex,
  ) {
    AppOverlay.dialog(
      context: context,
      barrierColor: AppColors.background.withValues(alpha: 0.87),
      builder: (context) =>
          MediaViewerDialog(items: items, initialIndex: initialIndex),
    );
  }

  void _showAvatarViewer(
    BuildContext context,
    AppUser user,
    String avatarHeroTag,
  ) {
    AppOverlay.dialog(
      context: context,
      barrierColor: AppColors.background.withValues(alpha: 0.92),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: AppColors.transparent,
          appBar: AppAppBar(
            title: _displayName(user),
            backgroundColor: AppColors.transparent,
            showBackButton: false,
            leading: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: Hero(
              tag: avatarHeroTag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: AppRadius.all16,
                  child: CachedNetworkImage(
                    imageUrl: user.foto!,
                    fit: BoxFit.contain,
                    cacheManager: ImageCacheConfig.optimizedCacheManager,
                    placeholder: (context, url) => AppShimmer.box(
                      width: 220,
                      height: 220,
                      borderRadius: AppRadius.r16,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_rounded,
                      size: 120,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Bottom action bar Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, AppUser user) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    final isMe = currentUser?.uid == uid;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s12,
        bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.s12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceHighlight)),
      ),
      child: isMe
          ? _MeBottomBar(user: user)
          : _OtherBottomBar(
              onChat: () => ref
                  .read(publicProfileControllerProvider(uid).notifier)
                  .openChat(context),
            ),
    );
  }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// Profile body Ã¢â‚¬â€ layout with responsive wide/narrow support
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

class _ProfileBody extends StatelessWidget {
  final AppUser user;
  final List<MediaItem> galleryItems;
  final List<AppUser> bandMembers;
  final String uid;
  final String avatarHeroTag;
  final VoidCallback onAvatarTap;
  final void Function(int index, List<MediaItem> items) onMediaTap;

  const _ProfileBody({
    required this.user,
    required this.galleryItems,
    required this.bandMembers,
    required this.uid,
    required this.avatarHeroTag,
    required this.onAvatarTap,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return isWide ? _wideLayout(context) : _narrowLayout(context);
  }

  Widget _narrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeroHeader(
            user: user,
            avatarHeroTag: avatarHeroTag,
            onAvatarTap: onAvatarTap,
          ),
          _buildBody(context, padding: AppSpacing.s20),
          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    final bio = user.profileBio;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s32),
      child: ResponsiveCenter(
        padding: EdgeInsets.zero,
        maxContentWidth: 1200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: header + bio
            SizedBox(
              width: 340,
              child: Column(
                children: [
                  ProfileHeroHeader(
                    user: user,
                    avatarHeroTag: avatarHeroTag,
                    onAvatarTap: onAvatarTap,
                  ),
                  if (bio != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s20,
                      ),
                      child: _BioCard(bio: bio),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s32),
            // Right column: details + gallery
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.s24),
                  _buildDetails(),
                  if (user.tipoPerfil != AppUserType.contractor) ...[
                    const SizedBox(height: AppSpacing.s20),
                    _buildGallery(),
                  ],
                  const SizedBox(height: AppSpacing.s48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required double padding}) {
    final bio = user.profileBio;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bio != null) ...[
            _BioCard(bio: bio),
            const SizedBox(height: AppSpacing.s16),
          ],
          _buildDetails(),
          if (user.tipoPerfil != AppUserType.contractor) ...[
            const SizedBox(height: AppSpacing.s20),
            _buildGallery(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return _TypeDetails(user: user, bandMembers: bandMembers);
  }

  Widget _buildGallery() {
    return ProfileGalleryTabs(
      items: galleryItems,
      accentColor: ProfileHeroHeader.profileTypeColor(user.tipoPerfil),
      onItemTap: onMediaTap,
    );
  }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// Type-specific detail sections
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

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

// Ã¢â€â‚¬Ã¢â€â‚¬ Professional Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

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
    final instagram = normalizeInstagramHandle(prof['instagram'] as String?);
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
        if (instagram.isNotEmpty) ...[
          if (generos.isNotEmpty) const SizedBox(height: AppSpacing.s12),
          _InfoCard(
            icon: Icons.alternate_email_rounded,
            title: 'Instagram',
            accentColor: color,
            child: _ChipWrap(
              items: [instagram],
              accentColor: color,
              isSkill: true,
            ),
          ),
        ],
      ],
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Band Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _BandDetails extends StatelessWidget {
  final AppUser user;
  final List<AppUser> members;

  const _BandDetails({required this.user, required this.members});

  @override
  Widget build(BuildContext context) {
    final banda = user.dadosBanda;
    final generos = (banda?['generosMusicais'] as List?)?.cast<String>() ?? [];
    final instagram = normalizeInstagramHandle(banda?['instagram'] as String?);
    final color = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Members Ã¢â‚¬â€ the highlight of a band profile
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
        if (instagram.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          _InfoCard(
            icon: Icons.alternate_email_rounded,
            title: 'Instagram',
            accentColor: color,
            child: _ChipWrap(
              items: [instagram],
              accentColor: color,
              isSkill: true,
            ),
          ),
        ],
      ],
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Studio Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

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
    final instagram = normalizeInstagramHandle(estudio['instagram'] as String?);
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
        if (instagram.isNotEmpty) ...[
          if (services.isNotEmpty || studioTypeLabel != null)
            const SizedBox(height: AppSpacing.s12),
          _InfoCard(
            icon: Icons.alternate_email_rounded,
            title: 'Instagram',
            accentColor: color,
            child: _ChipWrap(
              items: [instagram],
              accentColor: color,
              isSkill: true,
            ),
          ),
        ],
      ],
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Contractor Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _ContractorDetails extends StatelessWidget {
  final AppUser user;

  const _ContractorDetails({required this.user});

  @override
  Widget build(BuildContext context) {
    final contratante = user.dadosContratante;
    if (contratante == null) return const SizedBox.shrink();

    final genero = contratante['genero'] as String?;
    final instagram = normalizeInstagramHandle(
      contratante['instagram'] as String?,
    );
    final color = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);

    final hasGenero = genero != null && genero.isNotEmpty;
    final hasInstagram = instagram.isNotEmpty;

    if (!hasGenero && !hasInstagram) {
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
        if (hasInstagram) ...[
          if (hasGenero) const SizedBox(height: AppSpacing.s12),
          _InfoCard(
            icon: Icons.alternate_email_rounded,
            title: 'Instagram',
            accentColor: color,
            child: _ChipWrap(
              items: [instagram],
              accentColor: color,
              isSkill: true,
            ),
          ),
        ],
      ],
    );
  }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// Shared UI components
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

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

/// Skill chip Ã¢â‚¬â€ subtle accent background and border.
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

/// Genre chip Ã¢â‚¬â€ neutral surface style.
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

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// Bottom bars
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

class _OtherBottomBar extends StatelessWidget {
  final VoidCallback onChat;

  const _OtherBottomBar({required this.onChat});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onChat,
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: const Text('Iniciar Conversa'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.all16),
          textStyle: AppTypography.buttonPrimary,
        ),
      ),
    );
  }
}

class _MeBottomBar extends StatelessWidget {
  final AppUser user;

  const _MeBottomBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user.tipoPerfil == AppUserType.band) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.push(RoutePaths.manageMembers),
              icon: const Icon(Icons.people_rounded, size: 18),
              label: const Text('Gerenciar Integrantes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.all16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(RoutePaths.profileEdit),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.all16,
                    ),
                    textStyle: AppTypography.buttonPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
// Error / loading states
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

class _PublicProfileSkeleton extends StatelessWidget {
  static const double _topSpacing =
      AppSpacing.s48 + AppSpacing.s24 + AppSpacing.s20;

  const _PublicProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: _topSpacing),
            Center(child: SkeletonCircle(size: 124)),
            SizedBox(height: AppSpacing.s20),
            Center(child: SkeletonText(width: 180, height: 24)),
            SizedBox(height: AppSpacing.s8),
            Center(child: SkeletonText(width: 120, height: 14)),
            SizedBox(height: AppSpacing.s24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SkeletonBox(
                    width: double.infinity,
                    height: 112,
                    borderRadius: 16,
                  ),
                  SizedBox(height: AppSpacing.s12),
                  SkeletonBox(
                    width: double.infinity,
                    height: 132,
                    borderRadius: 16,
                  ),
                  SizedBox(height: AppSpacing.s20),
                  SkeletonBox(
                    width: double.infinity,
                    height: 180,
                    borderRadius: 16,
                  ),
                  SizedBox(height: AppSpacing.s48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;

  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.all24,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
