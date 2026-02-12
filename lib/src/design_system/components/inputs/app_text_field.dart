import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Campo de texto do Design System Mube.
///
/// Componente oficial para todos os casos de entrada de texto no app.
/// Suporta formularios simples e campos multiline.
///
/// Uso:
/// ```dart
/// AppTextField(
///   controller: _controller,
///   label: 'Email',
///   hint: 'Digite seu email',
///   validator: (value) => value?.isEmpty ?? false ? 'Campo obrigatório' : null,
/// )
/// ```
class AppTextField extends StatelessWidget {
  /// Controlador do texto. Se null, um controlador interno será criado.
  final TextEditingController? controller;

  /// Rótulo superior do campo.
  final String? label;

  /// Texto de dica exibido dentro do campo quando vazio.
  final String? hint;

  /// Se true, oculta o texto (para senhas).
  final bool obscureText;

  /// Tipo de teclado a ser exibido (email, number, etc).
  final TextInputType keyboardType;

  /// Função validadora. Retorna string de erro ou null se válido.
  final String? Function(String?)? validator;

  /// Ícone exibido à esquerda do texto.
  final Widget? prefixIcon;

  /// Ícone exibido à direita do texto.
  final Widget? suffixIcon;

  /// Callback para alternar visibilidade de senha.
  /// Se fornecido, exibe ícone de olho automaticamente.
  final VoidCallback? onToggleVisibility;

  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final bool canRequestFocus;
  final VoidCallback? onTap;
  final Key? fieldKey;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final bool showCounter;
  final EdgeInsets scrollPadding;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  /// Texto de erro forçado. Se não null, o campo fica em estado de erro.
  final String? errorText;

  const AppTextField({
    super.key,
    this.controller,
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
    this.onSubmitted,
    this.readOnly = false,
    this.canRequestFocus = true,
    this.onTap,
    this.fieldKey,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = true,
    this.scrollPadding = AppSpacing.all16,
    this.focusNode,
    this.textInputAction,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
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
            focusNode: focusNode,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            readOnly: readOnly,
            canRequestFocus: canRequestFocus,
            onTap: onTap,
            obscureText: obscureText,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: obscureText ? 1 : maxLines,
            maxLength: maxLength,
            buildCounter: showCounter
                ? null
                : (
                    BuildContext context, {
                    required int currentLength,
                    required bool isFocused,
                    int? maxLength,
                  }) => null,
            textCapitalization: textCapitalization,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            style: AppTypography.input.copyWith(color: AppColors.textPrimary),
            validator: validator,
            scrollPadding: scrollPadding,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.inputHint,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: AppSpacing.s16,
              ),
              prefixIcon: prefixIcon != null
                  ? IconTheme(
                      data: const IconThemeData(
                        color: AppColors.textPlaceholder,
                      ),
                      child: prefixIcon!,
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(),
              errorText: errorText,
              border: const OutlineInputBorder(
                borderRadius: AppRadius.all12,
                borderSide: BorderSide(color: AppColors.border),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (onToggleVisibility != null) {
      return SizedBox(
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
              color: AppColors.textPlaceholder,
              size: 20,
            ),
          ),
        ),
      );
    }
    return suffixIcon;
  }
}
