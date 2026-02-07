import 'package:flutter/material.dart';

import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
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
        // Header with title and "Ver todos"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: AppTypography.buttonPrimary.fontWeight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        // Content
        SizedBox(
          height:
              176, // Optimized height for compact card content (110 avatar + info)
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
    final hasMore = items.length > 10;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      itemCount: displayItems.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < displayItems.length) {
          final item = displayItems[index];
          return FeedCardCompact(item: item, onTap: () => onItemTap(item));
        } else {
          return _buildSeeAllCard();
        }
      },
    );
  }

  Widget _buildSeeAllCard() {
    return GestureDetector(
      onTap: onSeeAllTap,
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110, // Match photo size
            margin: const EdgeInsets.only(right: AppSpacing.s12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all12,
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s12),
            child: Text(
              'Ver todos',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: AppTypography.buttonPrimary.fontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SkeletonShimmer(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: AppSpacing.s12),
            child: const Column(
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
