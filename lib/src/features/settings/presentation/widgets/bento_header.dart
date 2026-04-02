import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../core/services/image_cache_config.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_type.dart';

/// Enhanced profile header with modern bento grid layout
///
/// Features:
/// - Large profile card with avatar, name, email
/// - Edit button with refined styling
/// - Stats grid showing favorites and profile type
/// - Glassmorphic effects and subtle depth
class BentoHeader extends ConsumerWidget {
  const BentoHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    final profileSummary = _ProfileSummary.fromUserType(l10n, user?.tipoPerfil);

    return Column(
      children: [
        _ProfileCard(
          name: user?.appDisplayName ?? l10n.settings_profile_guest_name,
          email: user == null
              ? l10n.settings_profile_guest_email
              : user.hasApplePrivateRelayEmail
              ? l10n.settings_profile_apple_private_email
              : user.email,
          photoUrl: user?.foto,
          onEditTap: () => context.push(RoutePaths.profileEdit),
        ),
        const SizedBox(height: AppSpacing.s16),
        _StatsGrid(
          favoritesCount: user?.favoritesCount ?? 0,
          profileSummary: profileSummary,
          onFavoritesTap: () => context.push(RoutePaths.receivedFavorites),
        ),
      ],
    );
  }
}

class _ProfileSummary {
  final String value;
  final IconData icon;
  final Color iconColor;

  const _ProfileSummary({
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  factory _ProfileSummary.fromUserType(
    AppLocalizations l10n,
    AppUserType? userType,
  ) {
    switch (userType) {
      case AppUserType.professional:
        return _ProfileSummary(
          value: l10n.settings_profile_type_professional,
          icon: Icons.music_note_rounded,
          iconColor: AppColors.primary,
        );
      case AppUserType.band:
        return _ProfileSummary(
          value: l10n.settings_profile_type_band,
          icon: Icons.groups_rounded,
          iconColor: AppColors.warning,
        );
      case AppUserType.studio:
        return _ProfileSummary(
          value: l10n.settings_profile_type_studio,
          icon: Icons.graphic_eq_rounded,
          iconColor: AppColors.info,
        );
      case AppUserType.contractor:
        return _ProfileSummary(
          value: l10n.settings_profile_type_contractor,
          icon: Icons.event_available_rounded,
          iconColor: AppColors.success,
        );
      default:
        return _ProfileSummary(
          value: l10n.profile_title,
          icon: Icons.person_outline_rounded,
          iconColor: AppColors.textSecondary,
        );
    }
  }
}

/// Profile card component with enhanced styling
class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final VoidCallback onEditTap;

  const _ProfileCard({
    required this.name,
    required this.email,
    required this.onEditTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceHighlight.withValues(alpha: 0.6),
            AppColors.surface.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: AppRadius.all24,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.surface,
            child: photoUrl == null
                ? Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 32,
                  )
                : ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                      cacheManager: ImageCacheConfig.profileCacheManager,
                      memCacheWidth: 160,
                      memCacheHeight: 160,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, _) =>
                          Container(color: AppColors.surface),
                      errorWidget: (context, _, _) => Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        size: 32,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.headlineSmall.copyWith(
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  email,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          _EditButton(onTap: onEditTap),
        ],
      ),
    );
  }
}

/// Refined edit button with subtle styling
class _EditButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all12,
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s10),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            borderRadius: AppRadius.all12,
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.edit_outlined,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Stats grid showing user statistics
class _StatsGrid extends StatelessWidget {
  final int favoritesCount;
  final _ProfileSummary profileSummary;
  final VoidCallback onFavoritesTap;

  const _StatsGrid({
    required this.favoritesCount,
    required this.profileSummary,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            iconColor: AppColors.primary,
            value: favoritesCount.toString(),
            label: l10n.settings_profile_favorites_label,
            onTap: onFavoritesTap,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: _StatCard(
            icon: profileSummary.icon,
            iconColor: profileSummary.iconColor,
            value: profileSummary.value,
            label: l10n.settings_profile_type_label,
          ),
        ),
      ],
    );
  }
}

/// Individual stat card component
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Ink(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: AppRadius.all20,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.all12,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  label,
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.all20,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all20,
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}
