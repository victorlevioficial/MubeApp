import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:like_button/like_button.dart';

import '../../../features/favorites/domain/favorite_controller.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_typography.dart';

/// An optimistic like button that manages its own animation state locally
/// to provide a smooth user experience while syncing with a global state controller.
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
  // Local, optimistic state for a smooth UI animation.
  late bool _isLiked;
  late int _displayCount;

  @override
  void initState() {
    super.initState();
    // Initialize local state from the source of truth (widget props and Riverpod).
    _isLiked = ref
        .read(favoriteControllerProvider)
        .localFavorites
        .contains(widget.targetId);
    _displayCount = widget.initialCount;
  }

  @override
  void didUpdateWidget(AppLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync local state if the external data changes (e.g., from a pull-to-refresh).
    // This ensures the button reflects the true state if it's updated externally.
    final latestIsLiked = ref
        .read(favoriteControllerProvider)
        .localFavorites
        .contains(widget.targetId);
    if (_isLiked != latestIsLiked) {
      _isLiked = latestIsLiked;
    }
    if (widget.initialCount != _displayCount &&
        widget.initialCount != oldWidget.initialCount) {
      _displayCount = widget.initialCount;
    }
  }

  /// Handles the tap event by first updating the local UI optimistically
  /// and then dispatching the state change to the global controller.
  Future<bool> _onTap(bool currentIsLiked) async {
    // 1. Optimistically update the local state for an instant, smooth animation.
    setState(() {
      _isLiked = !currentIsLiked;
      if (_isLiked) {
        _displayCount++;
      } else {
        // Prevent count from going below zero on the UI.
        if (_displayCount > 0) {
          _displayCount--;
        }
      }
    });

    // 2. Give haptic feedback.
    unawaited(HapticFeedback.lightImpact());

    // 3. Dispatch the action to the controller for background processing.
    ref.read(favoriteControllerProvider.notifier).toggle(widget.targetId);

    // 4. Return the new optimistic state to the `LikeButton` package,
    // which uses it to run its icon animation.
    return _isLiked;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider. This is necessary so that `didUpdateWidget` is called
    // when the global state changes from an external source.
    ref.watch(
      favoriteControllerProvider.select(
        (s) => s.localFavorites.contains(widget.targetId),
      ),
    );

    return LikeButton(
      size: widget.size,
      // The button's appearance is now driven by our local, optimistic state.
      isLiked: _isLiked,
      likeCount: _displayCount,
      padding: EdgeInsets.zero,
      onTap: _onTap,
      bubblesColor: const BubblesColor(
        dotPrimaryColor: AppColors.brandPrimary,
        dotSecondaryColor: AppColors.semanticAction,
      ),
      circleColor: const CircleColor(
        start: AppColors.semanticAction,
        end: AppColors.brandPrimary,
      ),
      likeBuilder: (bool isLiked) {
        return Icon(
          isLiked ? Icons.favorite : Icons.favorite_outline,
          color: isLiked ? AppColors.brandPrimary : AppColors.textSecondary,
          size: widget.size,
        );
      },
      countBuilder: (int? count, bool isLiked, String text) {
        if (!widget.showCount || count == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: isLiked ? AppColors.brandPrimary : AppColors.textSecondary,
              fontWeight: isLiked ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
