import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/data_display/optimized_image.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/feed_item.dart';

/// Improved compact feed card for horizontal scrolling sections.
///
/// Features:
/// - Simple circular avatar (110px)
/// - Clean layout without card wrapper
/// - Name and location/genre below
class ImprovedFeedCardCompact extends ConsumerStatefulWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const ImprovedFeedCardCompact({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  ConsumerState<ImprovedFeedCardCompact> createState() =>
      _ImprovedFeedCardCompactState();
}

class _ImprovedFeedCardCompactState
    extends ConsumerState<ImprovedFeedCardCompact> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 110,
          margin: const EdgeInsets.only(right: AppSpacing.s12),
          child: Column(
            children: [
              // Round avatar
              Hero(
                tag: 'avatar-compact-${widget.item.uid}',
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceHighlight,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.background.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.item.foto != null
                        ? OptimizedImage(
                            imageUrl: widget.item.foto!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.surface2,
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),

              // Name
              Text(
                widget.item.displayName,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              // Location or genre
              const SizedBox(height: AppSpacing.s2),
              if (widget.item.distanceText.isNotEmpty)
                Text(
                  widget.item.distanceText,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                )
              else if (widget.item.formattedGenres.isNotEmpty)
                Text(
                  widget.item.formattedGenres.first,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
