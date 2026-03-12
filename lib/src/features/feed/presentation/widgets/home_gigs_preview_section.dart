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
    return gigsAsync.when(
      data: (gigs) {
        if (gigs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(onSeeAllTap: onSeeAllTap),
            const SizedBox(height: AppSpacing.s16),
            SizedBox(
              height: 214,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
                itemCount: gigs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.s12),
                itemBuilder: (context, index) => SizedBox(
                  width: 288,
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
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(),
          SizedBox(height: AppSpacing.s16),
          SizedBox(
            height: 214,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: _SectionSkeleton(),
            ),
          ),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Text(
                'Gigs em aberto',
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
          child: Column(
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
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: AppRadius.circular(14),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Icon(
                              gigTypeIcon(gig.gigType),
                              size: 20,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
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
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                Wrap(
                                  spacing: AppSpacing.s8,
                                  runSpacing: AppSpacing.s4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      gig.gigType.label,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: accentColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const _InlineDot(),
                                    Text(
                                      gig.displayCompensation,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          _PillTag(
                            icon: Icons.groups_rounded,
                            label: gig.availableSlots == 1
                                ? '1 vaga'
                                : '${gig.availableSlots} vagas',
                            highlight: gig.availableSlots <= 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        gig.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        children: [
                          _PillTag(
                            icon: Icons.calendar_today_outlined,
                            label: _dateLabel(gig),
                          ),
                          _PillTag(
                            icon: gig.locationType == GigLocationType.remote
                                ? Icons.wifi_tethering_rounded
                                : Icons.location_on_outlined,
                            label: locationLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
}

class _PillTag extends StatelessWidget {
  const _PillTag({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: highlight ? AppColors.surface2 : AppColors.surfaceHighlight,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.border.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 122),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: highlight
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s12),
      itemBuilder: (_, _) => const SizedBox(
        width: 288,
        child: SkeletonShimmer(child: _SkeletonCard()),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
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
              SkeletonBox(width: 46, height: 46, borderRadius: AppRadius.r16),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 180, height: 18),
                    SizedBox(height: AppSpacing.s8),
                    SkeletonText(width: 132, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              SkeletonBox(width: 72, height: 32, borderRadius: AppRadius.rPill),
            ],
          ),
          SizedBox(height: AppSpacing.s16),
          SkeletonText(width: double.infinity, height: 14),
          SizedBox(height: AppSpacing.s8),
          SkeletonText(width: 220, height: 14),
          SizedBox(height: AppSpacing.s16),
          Spacer(),
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

class _InlineDot extends StatelessWidget {
  const _InlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: AppColors.textTertiary,
        shape: BoxShape.circle,
      ),
    );
  }
}
