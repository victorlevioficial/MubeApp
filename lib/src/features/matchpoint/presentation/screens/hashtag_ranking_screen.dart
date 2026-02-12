import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/loading/app_shimmer.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import '../controllers/matchpoint_controller.dart';

class HashtagRankingScreen extends ConsumerWidget {
  const HashtagRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(hashtagRankingProvider(50));

    return rankingAsync.when(
      data: (rankings) => _buildRankingList(rankings, ref),
      loading: () => _buildLoadingState(),
      error: (error, stack) => EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Erro ao carregar ranking',
        subtitle: 'Tente novamente mais tarde',
        actionButton: TextButton(
          onPressed: () => ref.refresh(hashtagRankingProvider(50)),
          child: Text(
            'Tentar novamente',
            style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
          child: AppShimmer(
            child: Container(
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.all12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingList(List<HashtagRanking> rankings, WidgetRef ref) {
    final visibleRankings = rankings
        .where((item) => item.useCount > 0)
        .toList();

    if (visibleRankings.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.tag,
        title: 'Nenhuma hashtag ainda',
        subtitle: 'As hashtags mais populares aparecerão aqui',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(hashtagRankingProvider(50)),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.s16),
        itemCount: visibleRankings.length + 1, // +1 para header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }

          final hashtag = visibleRankings[index - 1];
          return _buildHashtagCard(hashtag, fallbackPosition: index);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hashtags em Alta',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Descubra os estilos musicais mais populares',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          const Divider(color: AppColors.border),
        ],
      ),
    );
  }

  Widget _buildHashtagCard(
    HashtagRanking item, {
    required int fallbackPosition,
  }) {
    final trendColor = _getTrendColor(item.trend);
    final trendIcon = _getTrendIcon(item.trend);
    final displayName = item.displayName.startsWith('#')
        ? item.displayName.substring(1)
        : item.displayName;
    final position = item.currentPosition > 0
        ? item.currentPosition
        : fallbackPosition;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
        boxShadow: AppEffects.subtleShadow,
        border: item.isTrending
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          children: [
            // Posição
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getPositionColor(position),
                borderRadius: AppRadius.all8,
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),

            // Hashtag info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#$displayName',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.isTrending) ...[
                        const SizedBox(width: AppSpacing.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            'Em Alta',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '${item.useCount} músicos usam esta hashtag',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Trend indicator
            if (!item.isStable)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.all8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 16, color: trendColor),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      '${item.trendDelta}',
                      style: AppTypography.labelMedium.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return AppColors.medalGold;
      case 2:
        return AppColors.medalSilver;
      case 3:
        return AppColors.medalBronze;
      default:
        return AppColors.surfaceHighlight;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return AppColors.success;
      case 'down':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.arrow_upward_rounded;
      case 'down':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.remove_rounded;
    }
  }
}
