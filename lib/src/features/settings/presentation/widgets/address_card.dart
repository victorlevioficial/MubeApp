import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/saved_address.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.onSetPrimary,
    required this.onDelete,
    this.canDelete = true,
  });

  final SavedAddress address;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final isPrimary = address.isPrimary;
    final accentColor = isPrimary ? AppColors.primary : AppColors.info;
    final title = address.nome.trim().isNotEmpty
        ? address.nome.trim()
        : (isPrimary ? 'Endereço principal' : 'Endereço salvo');
    final summary = isPrimary
        ? 'Em uso como referência principal.'
        : 'Disponível para virar endereço principal.';
    final metadata = <Widget>[
      _MetaPill(
        icon: Icons.location_city_rounded,
        label: address.shortDisplay,
        color: accentColor,
      ),
      if (address.bairro.trim().isNotEmpty)
        _MetaPill(
          icon: Icons.map_outlined,
          label: address.bairro.trim(),
          color: AppColors.info,
        ),
      if (address.cep.trim().isNotEmpty)
        _MetaPill(
          icon: Icons.local_post_office_outlined,
          label: 'CEP ${address.cep.trim()}',
          color: AppColors.textSecondary,
        ),
      if (address.lat != null && address.lng != null)
        const _MetaPill(
          icon: Icons.gps_fixed_rounded,
          label: 'GPS ok',
          color: AppColors.success,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: isPrimary ? 0.16 : 0.1),
            AppColors.surface.withValues(alpha: 0.98),
            AppColors.surface,
          ],
        ),
        borderRadius: AppRadius.all24,
        border: Border.all(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.textPrimary.withValues(alpha: 0.07),
        ),
        boxShadow: isPrimary ? AppEffects.cardShadow : AppEffects.subtleShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LeadingMarker(isPrimary: isPrimary, accentColor: accentColor),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.headlineSmall.copyWith(
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        summary,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.82,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                _StatusPill(
                  label: isPrimary ? 'Principal' : 'Salvo',
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s14),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.22),
                borderRadius: AppRadius.all16,
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.primaryLine,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.secondaryLine.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      address.secondaryLine.trim(),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.82),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: metadata,
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: isPrimary
                      ? const _PrimaryStateBanner()
                      : _InlineActionButton(
                          icon: Icons.star_outline_rounded,
                          label: 'Definir principal',
                          color: AppColors.primary,
                          onTap: onSetPrimary,
                        ),
                ),
                const SizedBox(width: AppSpacing.s8),
                _SquareActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  tooltip: canDelete
                      ? 'Excluir endereço'
                      : 'Pelo menos 1 endereço deve permanecer salvo',
                  onTap: canDelete ? onDelete : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingMarker extends StatelessWidget {
  const _LeadingMarker({required this.isPrimary, required this.accentColor});

  final bool isPrimary;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.18),
            accentColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: AppRadius.all16,
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Icon(
        isPrimary ? Icons.star_rounded : Icons.location_on_outlined,
        color: accentColor,
        size: 22,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: AppTypography.chipLabel.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = color == AppColors.textSecondary
        ? AppColors.textSecondary
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: resolvedIconColor),
          const SizedBox(width: AppSpacing.s4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStateBanner extends StatelessWidget {
  const _PrimaryStateBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            'Endereço ativo',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all16,
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.all16,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.s8),
              Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all16,
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.all16,
              border: Border.all(color: color.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
