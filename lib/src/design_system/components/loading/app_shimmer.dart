import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../foundations/tokens/app_colors.dart';

// Re-export skeletons from centralized file
export 'app_skeleton.dart'
    show
        SkeletonShimmer,
        SkeletonBox,
        SkeletonCircle,
        SkeletonText,
        ProfileSkeleton,
        UserCardSkeleton,
        UserListSkeleton,
        FeedCardSkeleton,
        FeedListSkeleton,
        FeedScreenSkeleton;

/// A shimmer loading placeholder widget.
///
/// Use for skeleton loading states while content is being fetched.
/// Provides a smooth animation effect that indicates loading.
class AppShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const AppShimmer({super.key, required this.child, this.enabled = true});

  /// Creates a rectangular shimmer placeholder.
  factory AppShimmer.box({
    Key? key,
    double? width,
    double? height,
    double borderRadius = 8,
  }) {
    return AppShimmer(
      key: key,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Creates a circular shimmer placeholder (for avatars).
  factory AppShimmer.circle({Key? key, double size = 48}) {
    return AppShimmer(
      key: key,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.surfaceHighlight,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Creates a text-line shimmer placeholder.
  factory AppShimmer.text({
    Key? key,
    double width = double.infinity,
    double height = 14,
  }) {
    return AppShimmer(
      key: key,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight.withValues(alpha: 0.5),
      child: child,
    );
  }
}
