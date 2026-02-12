import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/saved_address.dart';

/// Address card with a muted chip-like visual style.
class AddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onTap;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  const AddressCard({
    super.key,
    required this.address,
    required this.onTap,
    required this.onSetPrimary,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = address.isPrimary;
    final backgroundColor = isPrimary
        ? AppColors.primaryMuted
        : AppColors.primaryMuted.withValues(alpha: 0.16);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all20,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.all20,
            border: Border.all(
              color: isPrimary
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceHighlight,
                  borderRadius: AppRadius.all12,
                ),
                child: Icon(
                  isPrimary ? Icons.star : Icons.location_on_outlined,
                  color: isPrimary
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.nome.isNotEmpty ? address.nome : 'Endereco',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: AppTypography.titleSmall.fontWeight,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: AppSpacing.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8,
                              vertical: AppSpacing.s2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryMuted,
                              borderRadius: AppRadius.pill,
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            child: Text(
                              'Principal',
                              style: AppTypography.chipLabel.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      address.displayAddress.isNotEmpty
                          ? address.displayAddress
                          : 'Endereco incompleto',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                elevation: 16,
                shadowColor: AppColors.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.all12,
                  side: BorderSide(color: AppColors.surfaceHighlight, width: 1),
                ),
                color: AppColors.surface,
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'primary':
                      onSetPrimary();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!isPrimary)
                    const PopupMenuItem(
                      value: 'primary',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline, size: 20),
                          SizedBox(width: AppSpacing.s12),
                          Text('Definir como principal'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Text('Excluir', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
