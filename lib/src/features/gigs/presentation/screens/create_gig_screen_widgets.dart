part of 'create_gig_screen.dart';

// ── Form section header ───────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.pill,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(label.toUpperCase(), style: AppTypography.settingsGroupTitle),
          ],
        ),
        const SizedBox(height: AppSpacing.s14),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

// ── Date picker tile ──────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.gigDate,
    required this.enabled,
    required this.errorText,
    required this.onTap,
  });

  final DateTime? gigDate;
  final bool enabled;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDate = gigDate != null;
    final hasError = errorText != null;
    final label = hasDate
        ? '${gigDate!.day.toString().padLeft(2, '0')}/${gigDate!.month.toString().padLeft(2, '0')}/${gigDate!.year}  ${gigDate!.hour.toString().padLeft(2, '0')}:${gigDate!.minute.toString().padLeft(2, '0')}'
        : 'Selecionar data e horário';

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.all12,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: AppRadius.all12,
          border: Border.all(
            color: hasError
                ? AppColors.error.withValues(alpha: 0.7)
                : hasDate
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: hasError
                      ? AppColors.error
                      : hasDate
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: hasError
                          ? AppColors.error
                          : hasDate
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                errorText!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Locked fields banner ──────────────────────────────────────────────────────

class _LockedFieldsBanner extends StatelessWidget {
  const _LockedFieldsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              'Como esta gig já recebeu candidaturas, apenas a descrição pode ser alterada.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementsIntroCard extends StatelessWidget {
  const _RequirementsIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: AppRadius.all8,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              'Esses blocos são opcionais e independentes. Abra somente o que fizer sentido para esta gig.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementCategoryCard extends StatelessWidget {
  const _RequirementCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedCount,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int selectedCount;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final isHighlighted = isExpanded || hasSelection;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: AppRadius.all12,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : AppColors.surface2,
                        borderRadius: AppRadius.all12,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isHighlighted
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              _RequirementBadge(
                                label: hasSelection
                                    ? '$selectedCount selecionado${selectedCount == 1 ? '' : 's'}'
                                    : 'Opcional',
                                isHighlighted: hasSelection,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: !isExpanded
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s12,
                        0,
                        AppSpacing.s12,
                        AppSpacing.s12,
                      ),
                      child: child,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementBadge extends StatelessWidget {
  const _RequirementBadge({required this.label, required this.isHighlighted});

  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surface2,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Multi-select field ────────────────────────────────────────────────────────

class _ConfigMultiSelectField extends StatelessWidget {
  const _ConfigMultiSelectField({
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    this.showTitle = true,
    this.emptyLabel = 'Selecionar',
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final List<ConfigItem> items;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final bool showTitle;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final selectedItems = items
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        InkWell(
          onTap: !enabled
              ? null
              : () async {
                  final result =
                      await EnhancedMultiSelectModal.show<ConfigItem>(
                        context: context,
                        title: title,
                        subtitle: subtitle,
                        items: items,
                        selectedItems: selectedItems,
                        itemLabel: (item) => item.label,
                      );
                  if (result == null) return;
                  onChanged(
                    result.map((item) => item.id).toList(growable: false),
                  );
                },
          borderRadius: AppRadius.all12,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s14,
              vertical: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all12,
              border: Border.all(
                color: selectedItems.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItems.isEmpty
                        ? emptyLabel
                        : '${selectedItems.length} selecionado${selectedItems.length == 1 ? '' : 's'}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: enabled
                          ? (selectedItems.isNotEmpty
                                ? AppColors.textPrimary
                                : AppColors.textTertiary)
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: selectedItems
                .map((item) => AppChip.skill(label: item.label))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
