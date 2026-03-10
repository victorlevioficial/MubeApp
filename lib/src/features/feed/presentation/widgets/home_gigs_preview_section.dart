import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../gigs/domain/gig.dart';
import '../../../gigs/domain/gig_date_mode.dart';
import '../../../gigs/domain/gig_location_type.dart';
import '../../../gigs/domain/gig_type.dart';

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Column(
                children: [
                  for (var index = 0; index < gigs.length; index++) ...[
                    HomeGigPreviewCard(
                      gig: gigs[index],
                      onTap: () => onGigTap(gigs[index]),
                    ),
                    if (index < gigs.length - 1)
                      const SizedBox(height: AppSpacing.s12),
                  ],
                ],
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            child: _SectionSkeleton(),
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.circular(AppRadius.r12),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
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
                border: Border.all(color: AppColors.surfaceHighlight, width: 1),
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
    final accentColor = _accentColorForType(gig.gigType);
    final locationLabel =
        gig.location?['label']?.toString().trim().isNotEmpty == true
        ? gig.location!['label'].toString().trim()
        : gig.locationType.label;
    final requirementLabel = _buildRequirementLabel(gig);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface2, accentColor.withValues(alpha: 0.08)],
        ),
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all20,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.16),
                        borderRadius: AppRadius.all16,
                      ),
                      child: Icon(
                        _iconForType(gig.gigType),
                        size: 22,
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
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            '${gig.gigType.label} • ${gig.displayCompensation}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    _PillTag(
                      icon: Icons.groups_rounded,
                      label: gig.availableSlots == 1
                          ? '1 vaga'
                          : '${gig.availableSlots} vagas',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s14),
                Text(
                  gig.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.s14),
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
                    if (requirementLabel != null)
                      _PillTag(
                        icon: Icons.music_note_rounded,
                        label: requirementLabel,
                      ),
                  ],
                ),
              ],
            ),
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

  String? _buildRequirementLabel(Gig gig) {
    final items = [
      ...gig.requiredInstruments,
      ...gig.requiredCrewRoles,
      ...gig.requiredStudioServices,
      ...gig.genres,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);

    if (items.isEmpty) return null;
    if (items.length == 1) return items.first;
    return '${items.first} +${items.length - 1}';
  }

  Color _accentColorForType(GigType gigType) {
    switch (gigType) {
      case GigType.liveShow:
        return AppColors.primary;
      case GigType.privateEvent:
        return AppColors.warning;
      case GigType.recording:
        return AppColors.info;
      case GigType.rehearsalJam:
        return AppColors.success;
      case GigType.other:
        return AppColors.textSecondary;
    }
  }

  IconData _iconForType(GigType gigType) {
    switch (gigType) {
      case GigType.liveShow:
        return Icons.mic_external_on_rounded;
      case GigType.privateEvent:
        return Icons.celebration_rounded;
      case GigType.recording:
        return Icons.graphic_eq_rounded;
      case GigType.rehearsalJam:
        return Icons.queue_music_rounded;
      case GigType.other:
        return Icons.music_note_rounded;
    }
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.88),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
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
    return const SkeletonShimmer(
      child: Column(
        children: [
          _SkeletonCard(),
          SizedBox(height: AppSpacing.s12),
          _SkeletonCard(),
          SizedBox(height: AppSpacing.s12),
          _SkeletonCard(),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
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
          Row(
            children: [
              SkeletonBox(width: 86, height: 30, borderRadius: AppRadius.rPill),
              SizedBox(width: AppSpacing.s8),
              SkeletonBox(width: 96, height: 30, borderRadius: AppRadius.rPill),
              SizedBox(width: AppSpacing.s8),
              SkeletonBox(width: 78, height: 30, borderRadius: AppRadius.rPill),
            ],
          ),
        ],
      ),
    );
  }
}
