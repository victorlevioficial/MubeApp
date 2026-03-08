import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/gig.dart';
import '../../domain/gig_date_mode.dart';
import '../../domain/gig_location_type.dart';
import 'gig_compensation_chip.dart';
import 'gig_status_badge.dart';
import 'gig_type_chip.dart';

class GigCard extends StatelessWidget {
  const GigCard({
    super.key,
    required this.gig,
    this.onTap,
    this.trailing,
  });

  final Gig gig;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final locationLabel =
        gig.location?['label']?.toString().trim() ?? gig.locationType.label;

    final dateLabel = switch (gig.dateMode) {
      _ when gig.gigDate != null => DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(gig.gigDate!),
      GigDateMode.toBeArranged => 'A combinar',
      _ => 'Sem data',
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all16,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gig.title,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Wrap(
                            spacing: AppSpacing.s8,
                            runSpacing: AppSpacing.s8,
                            children: [
                              GigStatusBadge(status: gig.status),
                              GigTypeChip(gigType: gig.gigType),
                              GigCompensationChip(gig: gig),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.s12),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  gig.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s8,
                  children: [
                    _MetaItem(
                      icon: Icons.calendar_today_outlined,
                      label: dateLabel,
                    ),
                    _MetaItem(
                      icon: gig.locationType == GigLocationType.remote
                          ? Icons.wifi_tethering_rounded
                          : Icons.location_on_outlined,
                      label: locationLabel,
                    ),
                    _MetaItem(
                      icon: Icons.groups_outlined,
                      label:
                          '${gig.availableSlots}/${gig.slotsTotal} vagas livres',
                    ),
                    _MetaItem(
                      icon: Icons.how_to_reg_outlined,
                      label: '${gig.applicantCount} candidaturas',
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
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
