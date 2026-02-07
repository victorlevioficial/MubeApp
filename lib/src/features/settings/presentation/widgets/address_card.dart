import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/saved_address.dart';

/// Card widget displaying a saved address with actions.
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
    return Card(
      color: address.isPrimary
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.all12,
        side: BorderSide(
          color: address.isPrimary
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surfaceHighlight,
          width: address.isPrimary ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all12,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: address.isPrimary
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceHighlight,
                  borderRadius: AppRadius.all12,
                ),
                child: Icon(
                  address.isPrimary ? Icons.star : Icons.location_on_outlined,
                  color: address.isPrimary
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),

              // Address info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.nome.isNotEmpty ? address.nome : 'Endereço',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: AppTypography.titleSmall.fontWeight,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (address.isPrimary) ...[
                          const SizedBox(width: AppSpacing.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s8,
                              vertical: AppSpacing.s2,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppRadius.all12,
                            ),
                            child: Text(
                              'Principal',
                              style: AppTypography.chipLabel.copyWith(
                                color: AppColors.background,
                                fontWeight: AppTypography.titleSmall.fontWeight,
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
                          : 'Endereço incompleto',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                elevation: 16,
                shadowColor: AppColors.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.all12,
                  side: BorderSide(
                    color: AppColors.surfaceHighlight,
                    width: 1,
                  ),
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
                  if (!address.isPrimary)
                    PopupMenuItem(
                      value: 'primary',
                      child: Row(
                        children: [
                          const Icon(Icons.star_outline, size: 20),
                          const SizedBox(width: AppSpacing.s12),
                          const Text('Definir como principal'),
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
                        Text(
                          'Excluir',
                          style: AppTypography.bodyMedium,
                        ),
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
