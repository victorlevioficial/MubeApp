import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';

class FeedItemSkeleton extends StatelessWidget {
  const FeedItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Base color for the shimmer effect - slightly lighter than background for visibility
    const baseColor = AppColors.skeletonBase;
    final highlightColor = AppColors.skeletonHighlight.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      padding: AppSpacing.all12,
      decoration: BoxDecoration(
        color: AppColors.surface, // Background of the card itself
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(
            alpha: 0.5,
          ), // Match FeedCardVertical border
          width: 1,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Placeholder
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.skeletonBase, // Standardized
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Name Placeholder
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.skeletonBase, // Standardized
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Location Placeholder
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.skeletonBase, // Standardized
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chips Placeholders (Skills)
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.skeletonBase, // Standardized
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.skeletonBase, // Standardized
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Chips Placeholders (Genres)
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
