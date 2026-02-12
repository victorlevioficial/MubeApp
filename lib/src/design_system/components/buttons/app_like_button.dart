import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:like_button/like_button.dart';

import '../../../features/favorites/domain/favorite_controller.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Like button with optimistic state driven by FavoriteController.
class AppLikeButton extends ConsumerStatefulWidget {
  final String targetId;
  final int initialCount;
  final double size;
  final bool showCount;

  const AppLikeButton({
    super.key,
    required this.targetId,
    required this.initialCount,
    this.size = 24.0,
    this.showCount = true,
  });

  @override
  ConsumerState<AppLikeButton> createState() => _AppLikeButtonState();
}

class _AppLikeButtonState extends ConsumerState<AppLikeButton> {
  @override
  void initState() {
    super.initState();
    _seedCount();
  }

  @override
  void didUpdateWidget(covariant AppLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetId != widget.targetId ||
        oldWidget.initialCount != widget.initialCount) {
      _seedCount();
    }
  }

  void _seedCount() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(favoriteControllerProvider.notifier)
          .ensureLikeCount(widget.targetId, widget.initialCount);
    });
  }

  Future<bool> _onTap(WidgetRef ref, bool currentIsLiked) async {
    unawaited(HapticFeedback.lightImpact());
    ref.read(favoriteControllerProvider.notifier).toggle(widget.targetId);

    // `LikeButton` uses this value to run the tap animation immediately.
    return !currentIsLiked;
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = ref.watch(
      favoriteControllerProvider.select(
        (s) => s.localFavorites.contains(widget.targetId),
      ),
    );
    final likeCount = ref.watch(
      favoriteControllerProvider.select(
        (s) => s.likeCounts[widget.targetId] ?? widget.initialCount,
      ),
    );

    return LikeButton(
      size: widget.size,
      isLiked: isLiked,
      likeCount: likeCount,
      padding: EdgeInsets.zero,
      onTap: (current) => _onTap(ref, current),
      bubblesColor: const BubblesColor(
        dotPrimaryColor: AppColors.primary,
        dotSecondaryColor: AppColors.primaryPressed,
      ),
      circleColor: const CircleColor(
        start: AppColors.primaryPressed,
        end: AppColors.primary,
      ),
      likeBuilder: (bool liked) {
        return Icon(
          liked ? Icons.favorite : Icons.favorite_outline,
          color: liked ? AppColors.primary : AppColors.textSecondary,
          size: widget.size,
        );
      },
      countBuilder: (int? count, bool liked, String text) {
        if (!widget.showCount || count == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s2),
          child: Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: liked ? AppColors.primary : AppColors.textSecondary,
              fontWeight: liked
                  ? AppTypography.buttonPrimary.fontWeight
                  : AppTypography.labelMedium.fontWeight,
            ),
          ),
        );
      },
    );
  }
}
