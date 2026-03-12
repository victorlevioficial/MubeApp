import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/interactions/app_animated_press.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/gig.dart';
import '../../domain/gig_date_mode.dart';
import '../../domain/gig_location_type.dart';
import '../../domain/gig_status.dart';
import 'gig_status_badge.dart';
import 'gig_visuals.dart';

class GigCard extends StatelessWidget {
  const GigCard({
    super.key,
    required this.gig,
    this.creator,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  final Gig gig;
  final AppUser? creator;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = gigAccentColor(gig.gigType);
    final accentBarColor = accent.withValues(
      alpha: gig.status == GigStatus.open ? 0.72 : 0.42,
    );
    final locationLabel =
        gig.location?['label']?.toString().trim() ?? gig.locationType.label;

    final dateLabel = switch (gig.dateMode) {
      _ when gig.gigDate != null =>
        DateFormat('dd/MM/yyyy HH:mm').format(gig.gigDate!),
      GigDateMode.toBeArranged => 'A combinar',
      _ => 'Sem data',
    };

    return AppAnimatedPress(
      onPressed: onTap,
      scaleFactor: 0.97,
      capturesTap: false,
      child: Material(
        color: AppColors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.65),
            ),
            boxShadow: AppEffects.subtleShadow,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.all16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: accentBarColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.r16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s14,
                    AppSpacing.s16,
                    AppSpacing.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: AppRadius.all12,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Icon(
                              gigTypeIcon(gig.gigType),
                              size: 20,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gig.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    height: 1.3,
                                    letterSpacing: -0.15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                Wrap(
                                  spacing: AppSpacing.s8,
                                  runSpacing: AppSpacing.s4,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      gig.gigType.label,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: accent,
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
                          if (trailing != null) ...[
                            const SizedBox(width: AppSpacing.s10),
                            trailing!,
                          ] else ...[
                            const SizedBox(width: AppSpacing.s8),
                            GigStatusBadge(status: gig.status),
                          ],
                        ],
                      ),
                      if (creator != null) ...[
                        const SizedBox(height: AppSpacing.s12),
                        _GigCardCreatorRow(creator: creator!),
                      ],
                      if (!compact) ...[
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          gig.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s14),
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        children: [
                          _MetaPill(
                            icon: Icons.calendar_today_outlined,
                            label: dateLabel,
                          ),
                          _MetaPill(
                            icon: gig.locationType == GigLocationType.remote
                                ? Icons.wifi_tethering_rounded
                                : Icons.location_on_outlined,
                            label: locationLabel,
                          ),
                          _MetaPill(
                            icon: Icons.groups_outlined,
                            label: gig.availableSlots == 1
                                ? '1 vaga'
                                : '${gig.availableSlots} vagas',
                            highlight: gig.availableSlots <= 2 &&
                                gig.availableSlots > 0 &&
                                gig.status == GigStatus.open,
                          ),
                          if (gig.applicantCount > 0)
                            _MetaPill(
                              icon: Icons.how_to_reg_outlined,
                              label: '${gig.applicantCount} candidatura${gig.applicantCount == 1 ? '' : 's'}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GigCardCreatorRow extends StatelessWidget {
  const _GigCardCreatorRow({required this.creator});

  final AppUser creator;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(
          size: 22,
          photoUrl: creator.foto,
          name: creator.appDisplayName,
          showBorder: false,
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            creator.appDisplayName,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final pillColor = highlight
        ? AppColors.surface2
        : AppColors.surfaceHighlight.withValues(alpha: 0.72);
    final iconColor = highlight ? AppColors.primary : AppColors.textTertiary;
    final textColor = highlight
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppColors.border.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: AppSpacing.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: textColor,
                fontSize: 11,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
