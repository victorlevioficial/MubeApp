import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../design_system/foundations/app_colors.dart';

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
          color: AppColors.textPrimary,
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
          color: AppColors.textPrimary,
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
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceHighlight,
      child: child,
    );
  }
}

/// A profile card skeleton for loading states.
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Center(child: AppShimmer.circle(size: 120)),
          const SizedBox(height: 24),

          // Name
          Center(child: AppShimmer.text(width: 180, height: 24)),
          const SizedBox(height: 8),

          // Subtitle
          Center(child: AppShimmer.text(width: 120, height: 14)),
          const SizedBox(height: 32),

          // Info rows
          AppShimmer.text(width: double.infinity, height: 48),
          const SizedBox(height: 12),
          AppShimmer.text(width: double.infinity, height: 48),
          const SizedBox(height: 12),
          AppShimmer.text(width: 200, height: 48),
        ],
      ),
    );
  }
}
