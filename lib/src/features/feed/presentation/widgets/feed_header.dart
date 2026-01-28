import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/user_type.dart';
import '../../../bands/data/invites_repository.dart';

class FeedHeader extends ConsumerWidget {
  final AppUser? currentUser;
  final VoidCallback onNotificationTap;

  const FeedHeader({
    super.key,
    required this.currentUser,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Determine Alert State
    Widget? bottomAlert;
    final user = currentUser;

    if (user != null) {
      if (user.tipoPerfil == AppUserType.band) {
        // Band Alert: Check member count
        final members = (user.dadosBanda?['membros_preview'] as List?) ?? [];
        if (members.length < 2) {
          bottomAlert = _buildAlertBar(
            context,
            color: Colors.orange,
            icon: Icons.warning_amber_rounded,
            text: 'Banda inativa: adicione integrantes!',
            onTap: () => context.push(RoutePaths.manageMembers),
          );
        }
      } else if (user.tipoPerfil == AppUserType.professional) {
        // Musician Alert: Check pending invites
        final invitesCountAsync = ref.watch(
          pendingInviteCountProvider(user.uid),
        );

        // Only show if we have data and count > 0
        invitesCountAsync.whenData((count) {
          if (count > 0) {
            bottomAlert = _buildAlertBar(
              context,
              color: AppColors.success, // "Positive thing" as requested
              icon: Icons
                  .check_circle_outline, // Use check circle for positive vibes
              text:
                  'Você tem $count convite${count > 1 ? 's' : ''} pendente${count > 1 ? 's' : ''}!',
              onTap: () => context.push('/profile/invites'),
            );
          }
        });

        // Note: As this is async inside build, in a real reactive scenario it works fine.
        // We handle the 'bottomAlert' assignation for the NEXT frame if it updates.
        // But since 'bottom' expects a Widget, we normally need the value NOW.
        // If async is loading, we show nothing.
        // For 'bottom', we can't easily switch height dynamically without stutter in Slivers
        // unless we use a PreferredSize that can be 0.
        // A cleaner way for SliverAppBar bottom is using a PreferredSizeWidget that handles its own visibility.
      }
    }

    // Refined Bottom Widget handling to avoid layout issues
    PreferredSizeWidget? bottomWidget;
    if (bottomAlert != null) {
      bottomWidget = PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: bottomAlert!,
      );
    }

    return SliverAppBar(
      floating: false,
      pinned: false,
      toolbarHeight: 70.0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,

      // Inject Alert Bar if exists
      bottom: bottomWidget,

      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (currentUser != null) {
                context.push('/user/${currentUser!.uid}');
              }
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surface,
              backgroundImage:
                  (currentUser?.foto != null && currentUser!.foto!.isNotEmpty)
                  ? CachedNetworkImageProvider(currentUser!.foto!)
                  : null,
              child: (currentUser?.foto == null || currentUser!.foto!.isEmpty)
                  ? const Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.textSecondary,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${currentUser?.nome ?? 'Visitante'}',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Explore o que há de novo',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      actions: [
        Container(
          margin: const EdgeInsets.only(right: AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            color: AppColors.textPrimary,
            onPressed: onNotificationTap,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBar(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48, // Standard height
        width: double.infinity,
        color: color.withValues(alpha: 0.15), // Subtle background
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: color, // Text matches icon
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
