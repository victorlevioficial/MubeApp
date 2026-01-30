import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import 'feed_item_skeleton.dart';

export 'feed_item_skeleton.dart';

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
            _buildHeaderSkeleton(),
            const SizedBox(height: AppSpacing.s24),
            _buildSectionSkeleton(),
            const SizedBox(height: AppSpacing.s24),
            _buildSectionSkeleton(),
            const SizedBox(height: AppSpacing.s24),
            _buildFilterBarSkeleton(),
            _buildTitleSkeleton(), // Simulates "Destaques" title
            // No extra gap needed as title has its own padding
            const FeedItemSkeleton(),
            const FeedItemSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Shimmer.fromColors(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight.withValues(alpha: 0.5),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors
                    .skeletonBase, // Standardized skeleton element color
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors
                        .skeletonBase, // Standardized skeleton element color
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors
                        .skeletonBase, // Standardized skeleton element color
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Shimmer.fromColors(
            baseColor: AppColors.skeletonBase,
            highlightColor: AppColors.skeletonHighlight.withValues(alpha: 0.5),
            child: Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors
                    .skeletonBase, // Standardized skeleton element color
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => Shimmer.fromColors(
              baseColor: AppColors.skeletonBase,
              highlightColor: AppColors.skeletonHighlight.withValues(
                alpha: 0.5,
              ),
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: AppColors
                      .skeletonBase, // Standardized skeleton element color
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBarSkeleton() {
    return SizedBox(
      height: 44, // Match real QuickFilterBar height
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          // Simulate variable widths like "Todos", "Músicos", "Perto de mim"
          final width = [60.0, 90.0, 70.0, 100.0, 80.0][index % 5];
          return Center(
            child: Shimmer.fromColors(
              baseColor: AppColors.skeletonBase,
              highlightColor: AppColors.skeletonHighlight.withValues(
                alpha: 0.5,
              ),
              child: Container(
                width: width,
                height: 32, // Chip height inside 44 container
                decoration: BoxDecoration(
                  color: AppColors
                      .skeletonBase, // Standardized skeleton element color
                  borderRadius: BorderRadius.circular(100), // Fully rounded
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight.withValues(alpha: 0.5),
        child: Container(
          width: 120,
          height: 20, // Title size
          decoration: BoxDecoration(
            color:
                AppColors.skeletonBase, // Standardized skeleton element color
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
