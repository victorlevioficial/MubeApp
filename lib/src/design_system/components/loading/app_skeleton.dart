import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';

// =============================================================================
// SKELETON PRIMITIVES
// =============================================================================

/// Widget base que aplica o efeito shimmer.
///
/// Uso:
/// ```dart
/// SkeletonShimmer(child: YourSkeletonWidget())
/// ```
class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const SkeletonShimmer({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight.withValues(
        alpha: 0.5,
      ), // Inverted for "glowing" effect on dark mode
      child: child,
    );
  }
}

/// Forma base para skeletons - retângulo arredondado.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Forma base para skeletons - círculo (avatares).
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.skeletonBase,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Forma base para skeletons - linha de texto.
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: AppRadius.all4,
      ),
    );
  }
}

// =============================================================================
// SKELETON COMPOSITIONS - Reutilizáveis
// =============================================================================

/// Skeleton de card com avatar + texto (para listas de usuários/conversas).
class UserCardSkeleton extends StatelessWidget {
  final double avatarSize;

  const UserCardSkeleton({super.key, this.avatarSize = 56});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        children: [
          SkeletonCircle(size: avatarSize),
          const SizedBox(width: AppSpacing.s12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 150, height: 16),
                SizedBox(height: AppSpacing.s8),
                SkeletonText(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de UserCardSkeletons (para resultados de busca, conversas).
class UserListSkeleton extends StatelessWidget {
  final int itemCount;
  final double avatarSize;

  const UserListSkeleton({super.key, this.itemCount = 6, this.avatarSize = 56});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) =>
            UserCardSkeleton(avatarSize: avatarSize),
      ),
    );
  }
}

/// Skeleton de card vertical do Feed (avatar grande + infos + badges).
class FeedCardSkeleton extends StatelessWidget {
  const FeedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      padding: AppSpacing.all12,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
      ),
      child: SkeletonShimmer(
        child: Row(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceHighlight,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: AppRadius.all4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: AppRadius.all4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: AppRadius.all12,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Container(
                        width: 50,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: AppRadius.all12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Favorite icon
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.surfaceHighlight,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de FeedCardSkeletons.
class FeedListSkeleton extends StatelessWidget {
  final int itemCount;

  const FeedListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const FeedCardSkeleton(),
    );
  }
}

/// Skeleton de perfil completo (avatar + nome + infos).
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: Padding(
        padding: AppSpacing.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: SkeletonCircle(size: 120)),
            SizedBox(height: AppSpacing.s24),
            Center(child: SkeletonText(width: 180, height: 24)),
            SizedBox(height: AppSpacing.s8),
            Center(child: SkeletonText(width: 120, height: 14)),
            SizedBox(height: AppSpacing.s32),
            SkeletonBox(width: double.infinity, height: 48),
            SizedBox(height: AppSpacing.s12),
            SkeletonBox(width: double.infinity, height: 48),
            SizedBox(height: AppSpacing.s12),
            SkeletonBox(width: 200, height: 48),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FEED SCREEN SKELETON (Completo com header + seções)
// =============================================================================

/// Skeleton completo da FeedScreen (header + seções horizontais + cards).
class FeedScreenSkeleton extends StatelessWidget {
  const FeedScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonShimmer(child: _buildHeaderSkeleton()),
            SkeletonShimmer(child: _buildHorizontalSectionSkeleton()),
            const SizedBox(height: AppSpacing.s24),
            SkeletonShimmer(child: _buildHorizontalSectionSkeleton()),
            const SizedBox(height: AppSpacing.s24),
            SkeletonShimmer(child: _buildQuickFilterSkeleton()),
            const SizedBox(height: AppSpacing.s16),
            const FeedCardSkeleton(),
            const FeedCardSkeleton(),
            const FeedCardSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s16),
      child: Column(
        children: [
          Row(
            children: [
              SkeletonCircle(size: 44),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 120, height: 16),
                    SizedBox(height: AppSpacing.s8),
                    SkeletonText(width: 180, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.s8),
              SkeletonBox(width: 32, height: 32, borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSectionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonText(width: 140, height: 18),
              SkeletonText(width: 60, height: 14),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            itemCount: 3,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.s12),
            itemBuilder: (context, index) =>
                const SkeletonBox(width: 140, height: 180, borderRadius: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilterSkeleton() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: 4,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.s8),
        itemBuilder: (context, index) =>
            const SkeletonBox(width: 80, height: 32, borderRadius: 20),
      ),
    );
  }
}
