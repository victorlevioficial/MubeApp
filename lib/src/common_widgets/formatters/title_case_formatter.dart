import 'package:flutter/services.dart';

class TitleCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String newText = newValue.text;

    // Capitalize first letter of each word
    newText = newText
        .split(' ')
        .map((word) {
          if (word.isNotEmpty) {
            return word[0].toUpperCase() + word.substring(1);
          }
          return '';
        })
        .join(' ');

    return newValue.copyWith(text: newText);
  }
}
