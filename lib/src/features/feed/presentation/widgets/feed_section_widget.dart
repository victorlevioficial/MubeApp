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
              GestureDetector(
                onTap: onSeeAllTap,
                child: Text(
                  'Ver todos',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),

        // Content
        SizedBox(
          height: 190, // Card height + spacing
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
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return FeedCardCompact(item: item, onTap: () => onItemTap(item));
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: const EdgeInsets.only(right: AppSpacing.s12),
          child: Column(
            children: [
              // Shimmer image placeholder
              AppShimmer.box(width: 140, height: 140, borderRadius: 12),
              const SizedBox(height: AppSpacing.s8),
              // Shimmer text placeholder
              AppShimmer.text(width: 100, height: 14),
              const SizedBox(height: 4),
              AppShimmer.text(width: 60, height: 12),
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
