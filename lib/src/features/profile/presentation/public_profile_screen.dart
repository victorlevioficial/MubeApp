import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../../constants/venue_type_constants.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/professional_profile_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../../gigs/domain/gig.dart';
import '../../gigs/domain/gig_review.dart';
import '../../gigs/presentation/providers/gig_streams.dart';
import '../../gigs/presentation/widgets/star_rating_widget.dart';
import '../domain/media_item.dart';
import '../domain/music_link_validator.dart';
import 'music_platform_catalog.dart';
import 'public_profile_controller.dart';
import 'widgets/band_members_section.dart';
import 'widgets/media_viewer_dialog.dart';
import 'widgets/profile_gallery_tabs.dart';
import 'widgets/profile_hero_header.dart';
import 'widgets/report_reason_dialog.dart';

part 'public_profile_body.dart';
part 'public_profile_bottom_bar.dart';
part 'public_profile_details.dart';

typedef PublicProfileMetrics = ({double? averageRating, int reviewCount});

final publicProfileMetricsProvider = FutureProvider.autoDispose
    .family<PublicProfileMetrics, String>((ref, uid) async {
      final averageRating = await ref.watch(
        userAverageRatingProvider(uid).future,
      );
      final reviews = await ref.watch(userReviewsProvider(uid).future);
      return (averageRating: averageRating, reviewCount: reviews.length);
    });

/// Public profile screen for the user-facing profile experience.
class PublicProfileScreen extends ConsumerWidget {
  final String profileRef;
  final String? avatarHeroTag;
  static const double _topActionSize = AppSpacing.s48;
  static const double _topActionTopPadding = AppSpacing.s8;
  static const double _topContentGap = AppSpacing.s12;

  const PublicProfileScreen({
    super.key,
    required this.profileRef,
    this.avatarHeroTag,
  });

  String _displayName(AppUser user) => user.appDisplayName;

  static double bodyTopInset(BuildContext context) {
    final topInset = math.max(
      MediaQuery.viewPaddingOf(context).top,
      AppSpacing.s24,
    );
    return topInset + _topActionTopPadding + _topActionSize + _topContentGap;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(publicProfileControllerProvider(profileRef));
    final state = stateAsync.asData?.value;
    final resolvedUid = state?.user?.uid;
    final AsyncValue<PublicProfileMetrics> metricsAsync = resolvedUid == null
        ? const AsyncValue.loading()
        : ref.watch(publicProfileMetricsProvider(resolvedUid));
    final metrics = metricsAsync.asData?.value;
    final AsyncValue<List<GigReview>> reviewsAsync = resolvedUid == null
        ? const AsyncValue.loading()
        : ref.watch(userReviewsProvider(resolvedUid));
    final reviews = reviewsAsync.asData?.value ?? const <GigReview>[];
    final reviewAuthorIdsKey = encodeGigUserIdsKey(
      reviews.map((review) => review.reviewerId),
    );
    final AsyncValue<Map<String, AppUser>> reviewAuthorsAsync =
        reviewAuthorIdsKey.isEmpty
        ? const AsyncValue.data(<String, AppUser>{})
        : ref.watch(gigUsersByStableIdsProvider(reviewAuthorIdsKey));
    final reviewAuthors =
        reviewAuthorsAsync.asData?.value ?? const <String, AppUser>{};
    final AsyncValue<List<Gig>> openGigsAsync = resolvedUid == null
        ? const AsyncValue.loading()
        : ref.watch(publicCreatorOpenGigsProvider(resolvedUid));
    final openGigs = openGigsAsync.asData?.value ?? const <Gig>[];
    final resolvedAvatarHeroTag =
        avatarHeroTag ?? 'avatar-${resolvedUid ?? profileRef}';
    final isMetricsLoading =
        state?.user != null && metrics == null && metricsAsync.isLoading;
    final isReviewsLoading =
        state?.user != null && reviewsAsync.isLoading && reviews.isEmpty;
    final isOpenGigsLoading =
        state?.user != null && openGigsAsync.isLoading && openGigs.isEmpty;
    final shouldShowLoading =
        (state == null && stateAsync.isLoading) || (state?.isLoading ?? false);
    final visibleUser = shouldShowLoading ? null : state?.user;

    Widget body;
    if (stateAsync.hasError) {
      body = _ErrorBody(message: 'Erro: ${stateAsync.error}');
    } else if (state?.error != null) {
      body = _ErrorBody(message: state!.error!);
    } else if (shouldShowLoading) {
      body = _buildLoadingState(context);
    } else if (state?.user == null) {
      body = const _ErrorBody(message: 'Usuário não encontrado.');
    } else {
      body = _ProfileBody(
        user: state!.user!,
        galleryItems: state.galleryItems,
        bandMembers: state.bandMembers,
        averageRating: metrics?.averageRating,
        reviewCount: metrics?.reviewCount ?? 0,
        isMetricsLoading: isMetricsLoading,
        reviews: reviews,
        reviewAuthors: reviewAuthors,
        isReviewsLoading: isReviewsLoading,
        openGigs: openGigs,
        isOpenGigsLoading: isOpenGigsLoading,
        avatarHeroTag: resolvedAvatarHeroTag,
        onAvatarTap: () =>
            _showAvatarViewer(context, state.user!, resolvedAvatarHeroTag),
        onMediaTap: (index, items) => _showMediaViewer(context, items, index),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopActions(context, ref, visibleUser),
          ),
        ],
      ),
      bottomNavigationBar: visibleUser != null
          ? _buildBottomBar(context, ref, visibleUser)
          : null,
    );
  }

  Widget _buildTopActions(BuildContext context, WidgetRef ref, AppUser? user) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s12,
          _topActionTopPadding,
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
    final controller = ref.read(
      publicProfileControllerProvider(profileRef).notifier,
    );
    final publicProfileUrl = RoutePaths.publicProfileShareUrl(
      uid: user.uid,
      username: user.publicUsername,
    );

    switch (action) {
      case 'share':
        await _shareProfile(context, user, shareUrl: publicProfileUrl);
        break;

      case 'copy':
        await _copyProfileLink(context, user, shareUrl: publicProfileUrl);
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

  String _publicProfileUrl(AppUser user) => RoutePaths.publicProfileShareUrl(
    uid: user.uid,
    username: user.publicUsername,
  );

  Future<void> _shareProfile(
    BuildContext context,
    AppUser user, {
    String? shareUrl,
  }) async {
    final publicProfileUrl = shareUrl ?? _publicProfileUrl(user);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Confira meu perfil no Mube: $publicProfileUrl',
        subject: 'Perfil de ${_displayName(user)} no Mube',
      ),
    );
  }

  Future<void> _copyProfileLink(
    BuildContext context,
    AppUser user, {
    String? shareUrl,
  }) async {
    final publicProfileUrl = shareUrl ?? _publicProfileUrl(user);
    await Clipboard.setData(ClipboardData(text: publicProfileUrl));
    if (!context.mounted) return;

    AppSnackBar.success(context, 'Link copiado para a área de transferência!');
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
                    imageUrl: user.avatarFullUrl!,
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
    final isMe = currentUser?.uid == user.uid;
    final canStartChat = !isMe;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s12,
          AppSpacing.s8,
          AppSpacing.s12,
          AppSpacing.s12,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surface2.withValues(alpha: 0.98),
                AppColors.surface,
              ],
            ),
            borderRadius: AppRadius.all24,
            border: Border.all(color: AppColors.surfaceHighlight),
            boxShadow: [
              BoxShadow(
                color: AppColors.background.withValues(alpha: 0.42),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isMe
              ? _MeBottomBar(user: user)
              : _OtherBottomBar(
                  onShare: () => unawaited(_shareProfile(context, user)),
                  onChat: canStartChat
                      ? () => ref
                            .read(
                              publicProfileControllerProvider(profileRef)
                                  .notifier,
                            )
                            .openChat(context)
                      : null,
                ),
        ),
      ),
    );
  }
}
