import 'package:flutter/material.dart';
import '../design_system/foundations/app_colors.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final VoidCallback? onRemove;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Theme(
        data: Theme.of(context).copyWith(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: FilterChip(
          showCheckmark: false,
          label: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
              height: 1.0,
            ),
          ),
          selected: isSelected,
          onSelected: onSelected,
          onDeleted: onRemove,
          deleteIcon: Icon(
            Icons.close,
            size: 14,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          deleteIconColor: isSelected
              ? AppColors.textPrimary
              : AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          pressElevation: 0,
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surfaceHighlight,
            ),
          ),
          labelPadding: onRemove != null
              ? const EdgeInsets.only(left: 12, right: 4)
              : const EdgeInsets.symmetric(horizontal: 12),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
