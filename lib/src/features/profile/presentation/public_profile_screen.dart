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
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../../gigs/presentation/providers/gig_streams.dart';
import '../../gigs/presentation/widgets/user_rating_display.dart';
import '../domain/media_item.dart';
import 'public_profile_controller.dart';
import 'widgets/band_members_section.dart';
import 'widgets/media_viewer_dialog.dart';
import 'widgets/profile_gallery_tabs.dart';
import 'widgets/profile_hero_header.dart';
import 'widgets/report_reason_dialog.dart';

part 'public_profile_body.dart';
part 'public_profile_bottom_bar.dart';
part 'public_profile_details.dart';

/// Public profile screen for the user-facing profile experience.
class PublicProfileScreen extends ConsumerWidget {
  final String uid;
  final String? avatarHeroTag;
  static const double _topActionSize = AppSpacing.s48;

  const PublicProfileScreen({super.key, required this.uid, this.avatarHeroTag});

  String _displayName(AppUser user) => user.appDisplayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(publicProfileControllerProvider(uid));
    final user = stateAsync.value?.user;
    final averageRatingAsync = ref.watch(userAverageRatingProvider(uid));
    final reviewsAsync = ref.watch(userReviewsProvider(uid));
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
                  averageRating: averageRatingAsync.asData?.value,
                  reviewCount: reviewsAsync.asData?.value.length ?? 0,
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
