import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_like_button.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/feed_item.dart';
import 'profile_type_badge.dart';

/// Enhanced vertical feed card with modern design and clean layout.
///
/// Features:
/// - Avatar 80px with better prominence
/// - Improved information hierarchy
/// - Category and location on same line
/// - Like button on top right
/// - Better skill and genre display
/// - Online status indicator
/// - Verified badge
/// - Modern card design with depth
class EnhancedFeedCard extends ConsumerStatefulWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final EdgeInsets? margin;

  const EnhancedFeedCard({
    super.key,
    required this.item,
    required this.onTap,
    this.margin,
  });

  @override
  ConsumerState<EnhancedFeedCard> createState() => _EnhancedFeedCardState();
}

class _EnhancedFeedCardState extends ConsumerState<EnhancedFeedCard> {
  bool _isPressed = false;

  bool get _hasLocationInfo => widget.item.distanceText.isNotEmpty;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  // Mock online status - in production would come from Firestore
  bool get _isOnline => widget.item.uid.hashCode % 3 == 0;

  // Mock verified status - in production would come from Firestore
  bool get _isVerified => widget.item.likeCount > 50;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isPressed = true),
      onExit: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Container(
            margin:
                widget.margin ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s20,
                  vertical: AppSpacing.s8,
                ),
            padding: AppSpacing.all16,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all20,
              border: Border.all(
                color: _isPressed
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.surfaceHighlight.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.background.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with online status
                    Stack(
                      children: [
                        Hero(
                          tag: 'avatar-${item.uid}',
                          child: UserAvatar(
                            photoUrl: item.foto,
                            name: item.displayName,
                            size: 80,
                          ),
                        ),
                        if (_isOnline)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.s16),

                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name with verified badge
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.displayName,
                                  style: AppTypography.titleLarge.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isVerified) ...[
                                const SizedBox(width: AppSpacing.s4),
                                const Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: AppColors.info,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s8),

                          // Profile type and location on same line
                          Row(
                            children: [
                              ProfileTypeBadge(
                                tipoPerfil: item.tipoPerfil,
                                subCategories: item.subCategories,
                              ),
                              if (_hasLocationInfo) ...[
                                const SizedBox(width: AppSpacing.s8),
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.s2),
                                Flexible(
                                  child: Text(
                                    widget.item.distanceText,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Like button in top right
                    SizedBox(
                      width: 60,
                      child: AppLikeButton(
                        targetId: item.uid,
                        initialCount: item.likeCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),

                // Skills
                if (item.skills.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                    child: Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: item.skills.take(5).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                            vertical: AppSpacing.s8,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            skill,
                            style: AppTypography.chipLabel.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Genres
                if (item.formattedGenres.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: item.formattedGenres.take(4).map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s10,
                          vertical: AppSpacing.s4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: AppRadius.pill,
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          genre,
                          style: AppTypography.chipLabel.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
