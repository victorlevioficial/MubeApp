import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/foundations/app_spacing.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onToggleVisibility;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool canRequestFocus;
  final Key? fieldKey; // Key for the actual TextFormField

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onToggleVisibility,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.readOnly = false,
    this.canRequestFocus = true,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        Semantics(
          label: label,
          textField: true,
          obscured: obscureText,
          child: TextFormField(
            key: fieldKey,
            controller: controller,
            onChanged: onChanged,
            readOnly: readOnly,
            canRequestFocus: canRequestFocus,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            validator: validator,
            cursorColor: Theme.of(context).colorScheme.primary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: AppSpacing.s16,
              ),
              prefixIcon: prefixIcon != null
                  ? IconTheme(
                      data: IconThemeData(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      child: prefixIcon!,
                    )
                  : null,
              suffixIcon: onToggleVisibility != null
                  ? SizedBox(
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: onToggleVisibility,
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Icon(
                            obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  : suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
