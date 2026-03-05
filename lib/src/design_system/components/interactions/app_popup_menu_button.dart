import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

class AppPopupMenuAction<T> {
  final T value;
  final String label;
  final IconData icon;
  final bool isDestructive;
  final bool showDividerBefore;
  final bool enabled;

  const AppPopupMenuAction({
    required this.value,
    required this.label,
    required this.icon,
    this.isDestructive = false,
    this.showDividerBefore = false,
    this.enabled = true,
  });
}

class AppPopupMenuButton<T> extends StatelessWidget {
  final List<AppPopupMenuAction<T>> items;
  final ValueChanged<T>? onSelected;
  final bool enabled;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? menuConstraints;
  final double? iconSize;
  final String? tooltip;
  final Color menuColor;

  const AppPopupMenuButton({
    super.key,
    required this.items,
    this.onSelected,
    this.enabled = true,
    this.icon,
    this.padding,
    this.menuConstraints,
    this.iconSize,
    this.tooltip,
    this.menuColor = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      enabled: enabled,
      padding: padding ?? const EdgeInsets.all(AppSpacing.s8),
      constraints: menuConstraints,
      iconSize: iconSize,
      tooltip: tooltip,
      icon: icon,
      color: menuColor,
      surfaceTintColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.all12),
      onSelected: onSelected,
      itemBuilder: (context) => _buildItems(),
    );
  }

  List<PopupMenuEntry<T>> _buildItems() {
    final result = <PopupMenuEntry<T>>[];
    for (final item in items) {
      if (item.showDividerBefore) {
        result.add(const PopupMenuDivider());
      }
      result.add(
        PopupMenuItem<T>(
          enabled: item.enabled,
          value: item.value,
          child: Row(
            children: [
              Icon(item.icon, size: 18, color: _itemColor(item)),
              const SizedBox(width: AppSpacing.s12),
              Text(
                item.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: _itemColor(item),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return result;
  }

  Color _itemColor(AppPopupMenuAction<T> item) {
    if (item.isDestructive) {
      return AppColors.error;
    }
    if (!item.enabled) {
      return AppColors.textSecondary;
    }
    return AppColors.textPrimary;
  }
}
