import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Raw Palette (Private)
  // ---------------------------------------------------------------------------
  static const Color _primary = Color(0xFFD40055); // Razzmatazz 300
  static const Color _accent = Color(0xFFFF4892); // Razzmatazz 400
  static const Color _bgDark = Color(0xFF0E0E0E);
  static const Color _bgGray = Color(0xFF161718);
  static const Color _bgGrayLight = Color(0xFF2A2A2A);
  static const Color _textWhite = Color(0xFFFFFFFF);
  static const Color _textGray = Color(0xFFBEBEBE);
  static const Color _textPlaceholder = Color(0xFF707070);
  static const Color _error = Color(0xFFCF6679);

  // ---------------------------------------------------------------------------
  // Semantic Tokens (Public)
  // ---------------------------------------------------------------------------

  // Brand
  static const Color primary = _primary;
  static const Color accent = _accent;

  // Backgrounds
  static const Color background = _bgDark;
  static const Color surface = _bgGray;
  static const Color surfaceHighlight = _bgGrayLight;

  // Text
  static const Color textPrimary = _textWhite;
  static const Color textSecondary = _textGray;
  static const Color textPlaceholder = _textPlaceholder;

  // States & Feedback
  static const Color error = _error;
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
  static const Color warning = Color(0xFFFF9800);

  // ---------------------------------------------------------------------------
  // Avatar Palette (Modern Pastel Light)
  // ---------------------------------------------------------------------------
  static const List<Color> avatarColors = [
    Color(0xFFA5D6A7), // Soft Green
    Color(0xFF90CAF9), // Soft Blue
    Color(0xFFCE93D8), // Soft Purple
    Color(0xFFF48FB1), // Soft Pink
    Color(0xFFFFCC80), // Soft Orange
    Color(0xFFFFF59D), // Soft Yellow
    Color(0xFF80CBC4), // Soft Teal
    Color(0xFFBCAAA4), // Soft Brown
    Color(0xFFB0BEC5), // Soft Blue Grey
    Color(0xFF9FA8DA), // Soft Indigo
  ];

  static const Color avatarBorder = _bgGrayLight;
  static const double avatarBorderOpacity = 1.0;

  // New definitions to fix lints
  static const Color primaryDark = Color(0xFF6D002B); // Razzmatazz 200

  // Opacity variations
  static Color get primaryDisabled => _primary.withOpacity(0.5);
  static Color get textDisabled => _textWhite.withOpacity(0.5);
}
