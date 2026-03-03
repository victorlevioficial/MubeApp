import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import 'feed_item_skeleton.dart';

export 'feed_item_skeleton.dart';

class FeedScreenSkeleton extends StatelessWidget {
  const FeedScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight.withValues(alpha: 0.5),
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
              _buildTitleSkeleton(),
              const FeedItemSkeleton(),
              const FeedItemSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.skeletonBase,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: AppRadius.all4,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Container(
                width: 180,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: AppRadius.all4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Container(
            width: 150,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.skeletonBase,
              borderRadius: AppRadius.all4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          height: AppSpacing.s48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.s12),
            itemBuilder: (context, index) => Container(
              width: 140,
              decoration: const BoxDecoration(
                color: AppColors.skeletonBase,
                borderRadius: AppRadius.all16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBarSkeleton() {
    return SizedBox(
      height: AppSpacing.s40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.s8),
        itemBuilder: (_, index) {
          final width = [60.0, 90.0, 70.0, 100.0, 80.0][index % 5];
          return Center(
            child: Container(
              width: width,
              height: AppSpacing.s32,
              decoration: const BoxDecoration(
                color: AppColors.skeletonBase,
                borderRadius: AppRadius.pill,
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
      child: Container(
        width: 120,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.skeletonBase,
          borderRadius: AppRadius.all4,
        ),
      ),
    );
  }
}
