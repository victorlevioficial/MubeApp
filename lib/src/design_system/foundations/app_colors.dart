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
  static const Color _bgSurface = Color(0xFF0E0E10); // Zinc 900
  static const Color _bgHighlight = Color(0xFF242428); // Zinc 800
  static const Color _bgChipSkill = Color(0xFF1A1A1D); // L20
  static const Color _bgChipGenre = Color(0xFF242428); // L40

  static const Color _textWhite = Color(0xFFFFFFFF);
  static const Color _textGray = Color(0xFFA1A1AA); // Zinc 400
  static const Color _textDarkGray = Color(0xFF52525B); // Zinc 600

  static const Color _error = Color(0xFFEF4444); // Red 500
  static const Color _success = Color(0xFF22C55E); // Green 500
  static const Color _info = Color(0xFF3B82F6); // Blue 500
  static const Color _warning = Color(0xFFF59E0B); // Amber 500

  // Profile Type Badge Colors
  static const Color _badgeFuchsia = Color(
    0xFFC026D3,
  ); // Fuchsia/Purple for Bands
  static const Color _badgeRed = Color(0xFFDC2626); // Red for Studios
  static const Color _badgeChipBg = Color(
    0xFF1F1F23,
  ); // Dark gray for badge chip

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
  // Specific Hierarchy
  static const Color chipSkill = _bgChipSkill;
  static const Color chipGenre = _bgChipGenre;

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

  // Profile Type Badge
  static const Color badgeMusician =
      brandPrimary; // Pink for Musicians/Professionals
  static const Color badgeBand = _badgeFuchsia; // Fuchsia for Bands
  static const Color badgeStudio = _badgeRed; // Red for Studios
  static const Color badgeChipBackground = _badgeChipBg; // Dark gray chip bg

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
