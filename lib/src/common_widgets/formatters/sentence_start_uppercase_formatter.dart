import 'package:flutter/services.dart';

/// Forces the first non-whitespace character to be uppercase.
class SentenceStartUppercaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final firstIndex = text.indexOf(RegExp(r'\S'));
    if (firstIndex < 0) return newValue;

    final firstChar = text[firstIndex];
    final upper = firstChar.toUpperCase();
    if (firstChar == upper) return newValue;

    final updated =
        '${text.substring(0, firstIndex)}$upper${text.substring(firstIndex + 1)}';
    return newValue.copyWith(text: updated);
  }
}
