part of 'filter_modal.dart';

class _FilterSheetHeader extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback? onClearAll;

  const _FilterSheetHeader({
    required this.activeFilterCount,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.s16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: AppRadius.all8,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros avançados',
                      style: AppTypography.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Refine a busca com o que realmente importa para voce.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeFilterCount > 0)
                _CountBadge(
                  label:
                      '$activeFilterCount ativo${activeFilterCount > 1 ? 's' : ''}',
                ),
            ],
          ),
          if (onClearAll != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClearAll,
                child: Text(
                  'Limpar tudo',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        child,
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final Widget child;

  const _FilterPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SelectionLauncherCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> selectedItems;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SelectionLauncherCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selectedItems,
    required this.onTap,
    required this.onClear,
  });

  bool get _hasItems => selectedItems.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all16,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s14),
          decoration: BoxDecoration(
            color: _hasItems ? AppColors.surface : AppColors.surface2,
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: _hasItems
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SelectionIcon(icon: icon, isActive: _hasItems),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.titleSmall),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          _hasItems
                              ? '${selectedItems.length} selecionado${selectedItems.length > 1 ? 's' : ''}'
                              : description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasItems) ...[
                    _CountBadge(label: '${selectedItems.length}'),
                    const SizedBox(width: AppSpacing.s4),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceHighlight,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.all12,
                        ),
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.s4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
              if (_hasItems) ...[
                const SizedBox(height: AppSpacing.s12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chipMaxWidth = constraints.maxWidth * 0.58;
                    return Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final item in selectedItems.take(3))
                          _SummaryChip(label: item, maxWidth: chipMaxWidth),
                        if (selectedItems.length > 3)
                          _SummaryChip(
                            label: '+${selectedItems.length - 3}',
                            maxWidth: chipMaxWidth,
                            isCount: true,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _SelectionIcon({required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
      ),
      child: Icon(
        icon,
        size: 18,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double maxWidth;
  final bool isCount;

  const _SummaryChip({
    required this.label,
    required this.maxWidth,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: isCount
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surfaceHighlight,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isCount
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: isCount ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;

  const _CountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterSheetFooter extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const _FilterSheetFooter({
    required this.activeFilterCount,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final applyText = activeFilterCount > 0
        ? 'Aplicar ($activeFilterCount)'
        : 'Aplicar filtros';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.outline(text: 'Cancelar', onPressed: onCancel),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            flex: 2,
            child: AppButton.primary(text: applyText, onPressed: onApply),
          ),
        ],
      ),
    );
  }
}
