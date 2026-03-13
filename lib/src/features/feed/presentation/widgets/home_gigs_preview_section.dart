import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../gigs/domain/gig.dart';
import '../../../gigs/domain/gig_date_mode.dart';
import '../../../gigs/domain/gig_location_type.dart';
import '../../../gigs/presentation/widgets/gig_visuals.dart';

class HomeGigsPreviewSection extends StatelessWidget {
  const HomeGigsPreviewSection({
    super.key,
    required this.gigsAsync,
    required this.onSeeAllTap,
    required this.onGigTap,
  });

  final AsyncValue<List<Gig>> gigsAsync;
  final VoidCallback onSeeAllTap;
  final ValueChanged<Gig> onGigTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _HomeGigsPreviewMetrics.fromViewportWidth(
          constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width,
        );

        return gigsAsync.when(
          data: (gigs) {
            if (gigs.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(onSeeAllTap: onSeeAllTap),
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  height: metrics.cardHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                    ),
                    itemCount: gigs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.s12),
                    itemBuilder: (context, index) => SizedBox(
                      width: metrics.cardWidth,
                      child: HomeGigPreviewCard(
                        gig: gigs[index],
                        onTap: () => onGigTap(gigs[index]),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(),
              const SizedBox(height: AppSpacing.s16),
              SizedBox(
                height: metrics.cardHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                  ),
                  child: SkeletonShimmer(
                    child: _SectionSkeleton(
                      cardWidth: metrics.cardWidth,
                      cardHeight: metrics.cardHeight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _HomeGigsPreviewMetrics {
  const _HomeGigsPreviewMetrics({
    required this.cardWidth,
    required this.cardHeight,
  });

  final double cardWidth;
  final double cardHeight;

  factory _HomeGigsPreviewMetrics.fromViewportWidth(double viewportWidth) {
    final availableWidth = (viewportWidth - (AppSpacing.s20 * 2)).clamp(
      0.0,
      double.infinity,
    );
    final isCompact = viewportWidth < 390;

    return _HomeGigsPreviewMetrics(
      cardWidth: (availableWidth * (isCompact ? 0.84 : 0.78)).clamp(
        228.0,
        264.0,
      ),
      cardHeight: isCompact ? 156.0 : 162.0,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({this.onSeeAllTap});

  final VoidCallback? onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.circular(AppRadius.r12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                Flexible(
                  child: Text(
                    'Gigs em aberto',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          GestureDetector(
            onTap: onSeeAllTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.circular(AppRadius.r20),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
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
    );
  }
}

class HomeGigPreviewCard extends StatelessWidget {
  const HomeGigPreviewCard({super.key, required this.gig, this.onTap});

  final Gig gig;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = gigAccentColor(gig.gigType);
    final locationLabel =
        gig.location?['label']?.toString().trim().isNotEmpty == true
        ? gig.location!['label'].toString().trim()
        : gig.locationType.label;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
        boxShadow: AppEffects.subtleShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all20,
          splashFactory: InkRipple.splashFactory,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactCard = constraints.maxWidth < 248;
              final iconSize = isCompactCard ? 38.0 : 40.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.65),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.r20),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s12,
                        AppSpacing.s12,
                        AppSpacing.s12,
                        AppSpacing.s12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: AppRadius.circular(
                                    AppRadius.r12,
                                  ),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Icon(
                                  gigTypeIcon(gig.gigType),
                                  size: 18,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      gig.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.s4),
                                    Text(
                                      '${gig.gigType.label} • ${gig.displayCompensation}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Expanded(
                            child: Text(
                              _supportingLabel(gig),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s10),
                          Row(
                            children: [
                              Expanded(
                                child: _PillTag(
                                  icon: Icons.calendar_today_outlined,
                                  label: _dateLabel(gig),
                                  expand: true,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              Expanded(
                                child: _PillTag(
                                  icon:
                                      gig.locationType == GigLocationType.remote
                                      ? Icons.wifi_tethering_rounded
                                      : Icons.location_on_outlined,
                                  label: locationLabel,
                                  expand: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _dateLabel(Gig gig) {
    return switch (gig.dateMode) {
      _ when gig.gigDate != null => DateFormat('dd/MM').format(gig.gigDate!),
      GigDateMode.toBeArranged => 'A combinar',
      _ => 'Sem data',
    };
  }

  String _supportingLabel(Gig gig) {
    final description = gig.description.trim();
    if (description.isNotEmpty) return description;

    final requirementGroups = [
      gig.requiredInstruments,
      gig.requiredCrewRoles,
      gig.requiredStudioServices,
      gig.genres,
    ];

    for (final group in requirementGroups) {
      if (group.isNotEmpty) {
        return group.take(3).join(' • ');
      }
    }

    final availableSlots = gig.availableSlots;
    return '$availableSlots vaga${availableSlots == 1 ? '' : 's'} disponive${availableSlots == 1 ? 'l' : 'is'}';
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({
    required this.icon,
    required this.label,
    this.expand = false,
  });

  final IconData icon;
  final String label;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: expand ? TextAlign.start : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.cardWidth, required this.cardHeight});

  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
      itemBuilder: (_, _) => SizedBox(
        width: cardWidth,
        child: _SkeletonCard(cardHeight: cardHeight),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.cardHeight});

  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 40, height: 40, borderRadius: AppRadius.r12),
              SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 172, height: 16),
                    SizedBox(height: AppSpacing.s4),
                    SkeletonText(width: 148, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.s10),
          SkeletonText(width: double.infinity, height: 14),
          SizedBox(height: AppSpacing.s4),
          SkeletonText(width: 188, height: 14),
          Spacer(),
          SizedBox(height: AppSpacing.s10),
          Row(
            children: [
              SkeletonBox(width: 86, height: 30, borderRadius: AppRadius.rPill),
              SizedBox(width: AppSpacing.s8),
              SkeletonBox(width: 96, height: 30, borderRadius: AppRadius.rPill),
            ],
          ),
        ],
      ),
    );
  }
}
