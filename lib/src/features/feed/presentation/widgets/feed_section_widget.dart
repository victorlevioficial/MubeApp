import 'package:flutter/material.dart';

import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/feed_item.dart';
import 'feed_card_compact.dart';

/// Horizontal feed section widget with title and "Ver todos" button.
class FeedSectionWidget extends StatelessWidget {
  final String title;
  final List<FeedItem> items;
  final bool isLoading;
  final VoidCallback onSeeAllTap;
  final void Function(FeedItem) onItemTap;

  const FeedSectionWidget({
    super.key,
    required this.title,
    required this.items,
    this.isLoading = false,
    required this.onSeeAllTap,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and top-level action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.surfaceHighlight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todos',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),

        // Section content
        SizedBox(
          height: 160,
          child: isLoading
              ? _buildLoadingState()
              : items.isEmpty
              ? _buildEmptyState()
              : _buildList(),
        ),
      ],
    );
  }

  Widget _buildList() {
    final displayItems = items.take(10).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.s12),
          child: FeedCardCompact(item: item, onTap: () => onItemTap(item)),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return SkeletonShimmer(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 122,
            child: Column(
              children: [
                // Image placeholder
                SkeletonBox(width: 110, height: 110, borderRadius: 12),
                SizedBox(height: AppSpacing.s8),
                // Text placeholder
                SkeletonText(width: 80, height: 14),
                SizedBox(height: AppSpacing.s4),
                SkeletonText(width: 50, height: 12),
                SizedBox(height: AppSpacing.s4),
                SkeletonText(width: 40, height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Nenhum resultado',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
