import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final String hint;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    this.hint = 'Selecione',
  });

  T? _safeValue(List<DropdownMenuEntry<T>> entries) {
    if (value == null) return null;
    final hasValue = entries.any((entry) => entry.value == value);
    return hasValue ? value : null;
  }

  List<DropdownMenuEntry<T>> _buildEntries() {
    return items.where((item) => item.value != null).map((item) {
      final itemValue = item.value as T;
      final label = _extractLabel(item, itemValue);
      return DropdownMenuEntry<T>(
        value: itemValue,
        label: label,
        labelWidget: item.child,
        enabled: item.enabled,
      );
    }).toList();
  }

  String _extractLabel(DropdownMenuItem<T> item, T fallbackValue) {
    final child = item.child;
    if (child is Text) {
      return child.data ?? fallbackValue.toString();
    }
    return fallbackValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();
    final effectiveValue = _safeValue(entries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : null;

            return DropdownMenuFormField<T>(
              initialSelection: effectiveValue,
              width: fieldWidth,
              menuHeight: 300,
              requestFocusOnTap: false,
              enableSearch: false,
              closeBehavior: DropdownMenuCloseBehavior.all,
              dropdownMenuEntries: entries,
              onSelected: onChanged,
              validator: validator,
              textStyle: AppTypography.input.copyWith(
                color: AppColors.textPrimary,
              ),
              hintText: hint,
              trailingIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 24,
              ),
              selectedTrailingIcon: const Icon(
                Icons.keyboard_arrow_up,
                color: AppColors.textSecondary,
                size: 24,
              ),
              inputDecorationTheme: InputDecorationTheme(
                hintStyle: AppTypography.inputHint,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: 14,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.all12,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.all12,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.all12,
                  borderSide: BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: AppRadius.all12,
                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
