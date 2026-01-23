import 'package:flutter/material.dart';

import '../../../../common_widgets/app_shimmer.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        // Content
        SizedBox(
          height:
              190, // Increased from 170 to accommodate vertical layout of location and icons
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
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          width: 110, // Match FeedCardCompact width
          margin: const EdgeInsets.only(right: AppSpacing.s12),
          child: Column(
            children: [
              // Shimmer image placeholder
              AppShimmer.box(width: 110, height: 110, borderRadius: 12),
              const SizedBox(height: AppSpacing.s8),
              // Shimmer text placeholder
              AppShimmer.text(width: 80, height: 14),
              const SizedBox(height: 4),
              AppShimmer.text(width: 50, height: 12),
              const SizedBox(height: 4),
              AppShimmer.text(width: 40, height: 12),
            ],
          ),
        );
      },
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
