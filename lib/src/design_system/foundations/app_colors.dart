import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Raw Palette (Private)
  // ---------------------------------------------------------------------------
  static const Color _primary = Color(0xFFD40055); // Razzmatazz 300
  static const Color _secondaryGlow = Color(0xFFFF0066); // Neon Pink
  static const Color _gradientEnd = Color(0xFF990033);

  static const Color _bgDeep = Color(0xFF0A0A0A); // Deepest Black
  static const Color _bgSurface = Color(0xFF18181B); // Zinc 900
  static const Color _bgHighlight = Color(0xFF27272A); // Zinc 800

  static const Color _textWhite = Color(0xFFFFFFFF);
  static const Color _textGray = Color(0xFFA1A1AA); // Zinc 400
  static const Color _textDarkGray = Color(0xFF52525B); // Zinc 600

  static const Color _error = Color(0xFFEF4444); // Red 500
  static const Color _success = Color(0xFF22C55E); // Green 500
  static const Color _info = Color(0xFF3B82F6); // Blue 500
  static const Color _warning = Color(0xFFF59E0B); // Amber 500

  // ---------------------------------------------------------------------------
  // Semantic Tokens (Public)
  // ---------------------------------------------------------------------------

  // Brand Identity (Institutional Use - Logo, Gradients, Solid Buttons)
  // D40055 = Strong brand color, used for identity elements
  static const Color brandPrimary = _primary;
  static const Color brandGlow = _secondaryGlow;
  static const LinearGradient brandGradient = LinearGradient(
    colors: [_primary, _gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backgrounds
  static const Color background = _bgDeep;
  static const Color surface = _bgSurface;
  static const Color surfaceHighlight = _bgHighlight;

  // Text
  static const Color textPrimary = _textWhite;
  static const Color textSecondary = _textGray;
  static const Color textTertiary =
      _textDarkGray; // Low emphasis text & placeholders
  static const Color textPlaceholder = textTertiary; // Alias for consistency

  // Actionables (Interface Use - Links, Icons, Borders, Interactive Elements)
  // FF5C8D = Optimized for dark mode: high contrast, reduced eye strain
  static const Color semanticAction = Color(0xFFFF5C8D);
  static const Color textAction = semanticAction;

  // Borders
  static const Color border = _bgHighlight;

  // Feedback
  static const Color error = _error;
  static const Color success = _success;
  static const Color info = _info;
  static const Color warning = _warning;

  // Skeletons
  // Skeletons
  static const Color skeletonBase = _bgSurface;
  static const Color skeletonHighlight = _bgHighlight;

  // Avatar Palette (Refined)
  static const List<Color> avatarColors = [
    Color(0xFFF472B6), // Pink 400
    Color(0xFFA78BFA), // Violet 400
    Color(0xFF60A5FA), // Blue 400
    Color(0xFF34D399), // Emerald 400
    Color(0xFFFBBF24), // Amber 400
    Color(0xFFF87171), // Red 400
  ];

  static const Color avatarBorder = _bgDeep;
  static const double avatarBorderOpacity = 1.0;

  // Backward Compatibility (Deprecated but kept for safety)
  static const Color primary = brandPrimary;
  @Deprecated('Use semanticAction')
  static const Color accent = semanticAction;

  // Opacity variations
  static Color get primaryDisabled => _primary.withValues(alpha: 0.5);
  static Color get textDisabled => _textWhite.withValues(alpha: 0.5);
}
