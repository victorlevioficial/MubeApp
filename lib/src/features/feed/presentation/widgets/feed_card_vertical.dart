import 'package:flutter/material.dart';
import 'package:mube/src/design_system/components/buttons/app_like_button.dart';
import 'package:mube/src/design_system/foundations/tokens/app_spacing.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart'
    show AppTypography;
import '../../../../utils/professional_profile_utils.dart';
import '../../domain/feed_item.dart';
import 'profile_type_badge.dart';

/// A vertical feed card that reactively updates its favorite status.
class FeedCardVertical extends StatefulWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final EdgeInsets? margin;
  final String? avatarHeroTag;

  const FeedCardVertical({
    super.key,
    required this.item,
    required this.onTap,
    this.margin,
    this.avatarHeroTag,
  });

  @override
  State<FeedCardVertical> createState() => _FeedCardVerticalState();
}

class _FeedCardVerticalState extends State<FeedCardVertical> {
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final avatar = UserAvatar(
      photoUrl: item.foto,
      name: item.displayName,
      size: 80,
    );
    final avatarWidget = widget.avatarHeroTag != null
        ? Hero(tag: widget.avatarHeroTag!, child: avatar)
        : avatar;

    return Semantics(
      button: true,
      label: item.displayName,
      hint: 'Toque para abrir o perfil',
      child: MouseRegion(
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
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s8,
                  ),
              padding: AppSpacing.all12,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.all16,
                border: Border.all(
                  color: _isPressed
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.surfaceHighlight.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatarWidget,
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.displayName,
                                style: AppTypography.cardTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                          child: Row(
                            children: [
                              if (_hasLocationInfo) ...[
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.s4),
                                Text(
                                  widget.item.distanceText,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s8),
                              ],
                              ProfileTypeBadge(
                                tipoPerfil: item.tipoPerfil,
                                subCategories: item.subCategories,
                              ),
                            ],
                          ),
                        ),
                        if (item.offersRemoteRecording)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.s8,
                            ),
                            child: _buildRemoteRecordingChip(),
                          ),
                        if (item.formattedSkills.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.s8,
                            ),
                            child: _SingleLineChipList(
                              items: item.formattedSkills,
                              chipBuilder: _buildSkillChip,
                              overflowBuilder: (count) =>
                                  _buildSkillChip('+$count'),
                            ),
                          ),
                        if (item.formattedGenres.isNotEmpty)
                          _SingleLineChipList(
                            items: item.formattedGenres,
                            chipBuilder: _buildGenreChip,
                            overflowBuilder: (count) =>
                                _buildGenreChip('+$count'),
                          ),
                      ],
                    ),
                  ),
                  AppLikeButton(
                    targetId: item.uid,
                    initialCount: item.likeCount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Skill chip: filled style (using standardized chip background)
  Widget _buildSkillChip(String label) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 90,
      ), // Prevent super wide chips
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTypography.buttonPrimary.fontWeight,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  /// Genre chip: filled style (standardized monochromatic look)
  Widget _buildGenreChip(String label) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 80,
      ), // Prevent super wide chips
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.pill,
        // No border for cleaner look
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  Widget _buildRemoteRecordingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.radio_button_checked_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.s4),
          Text(
            professionalRemoteRecordingLabel,
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays chips in a single line, showing an overflow indicator
/// (e.g., "+2") if not all items fit.
/// Optimized to avoid LayoutBuilder for every card.
class _SingleLineChipList extends StatelessWidget {
  final List<String> items;
  final Widget Function(String label) chipBuilder;
  final Widget Function(int count) overflowBuilder;

  const _SingleLineChipList({
    required this.items,
    required this.chipBuilder,
    required this.overflowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // PERFORMANCE OPTIMIZATION:
    // Instead of LayoutBuilder + Layout Simulation (expensive),
    // we use a specific Wrap-like logic or just a constrained ListView
    // The previous implementation was O(N^2) relative to layout passes.

    // Simplification: display up to 3 items max for skills, then +N.
    // With 3 items, shows 2 chips + "+1" overflow counter.
    const maxVisibleItems = 3;

    if (items.length <= maxVisibleItems) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.s4),
            Flexible(child: chipBuilder(items[i])),
          ],
        ],
      );
    }

    // Overflow case
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < maxVisibleItems - 1; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s4),
          Flexible(child: chipBuilder(items[i])),
        ],
        const SizedBox(width: AppSpacing.s4),
        overflowBuilder(items.length - (maxVisibleItems - 1)),
      ],
    );
  }
}
