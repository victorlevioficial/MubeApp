import 'package:flutter/material.dart';

/// Tokens de cores do Design System Mube.
///
/// Todas as cores devem ser acessadas através desta classe para garantir
/// consistência visual em todo o aplicativo.
///
/// Estrutura:
/// - Raw Palette (privada): Cores base hexadecimais
/// - Semantic Tokens (público): Cores com significado semântico
class AppColors {
  const AppColors._();

  // ===========================================================================
  // RAW PALETTE (Private)
  // ===========================================================================

  // Brand Colors
  static const Color _primary = Color(0xFFD71E68); // Razzmatazz 300
  static const Color _secondaryGlow = Color(0xFFD71E68); // Neon Pink
  static const Color _gradientEnd = Color(0xFF990033);

  // Background Colors
  static const Color _bgDeep = Color(0xFF0A0A0A); // Deepest Black
  static const Color _bgSurface = Color(0xFF161616); // Zinc 900
  static const Color _bgHighlight = Color(0xFF202020); // Zinc 800
  static const Color _bgChipSkill = Color(0xFF2C2C2C); // L20
  static const Color _bgChipGenre = Color(0xFF3E3E3E); // L40

  // Text Colors
  static const Color _textWhite = Color(0xFFFFFFFF);
  static const Color _textGray = Color(0xFFB3B3B3); // Zinc 400
  static const Color _textDarkGray = Color(0xFF737373); // Zinc 600

  // Feedback Colors
  static const Color _error = Color(0xFFEF4444); // Red 500
  static const Color _success = Color(0xFF22C55E); // Green 500
  static const Color _info = Color(0xFF3B82F6); // Blue 500
  static const Color _warning = Color(0xFFF59E0B); // Amber 500

  // Badge Colors
  static const Color _badgeFuchsia = Color(0xFFC026D3); // Fuchsia/Purple
  static const Color _badgeRed = Color(0xFFDC2626); // Red
  static const Color _badgeChipBg = Color(0xFF1F1F23); // Dark gray

  // ===========================================================================
  // SEMANTIC TOKENS - BRAND
  // ===========================================================================

  /// Cor primária da marca (Razzmatazz)
  static const Color brandPrimary = _primary;

  /// Cor de brilho/destaque da marca
  static const Color brandGlow = _secondaryGlow;

  /// Cor secundária da marca
  static const Color brandSecondary = _secondaryGlow;

  /// Gradiente principal da marca
  static const LinearGradient brandGradient = LinearGradient(
    colors: [_primary, _gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // SEMANTIC TOKENS - BACKGROUND
  // ===========================================================================

  /// Cor de fundo principal (mais escura)
  static const Color background = _bgDeep;

  /// Cor de superfície para cards e containers
  static const Color surface = _bgSurface;

  /// Cor de superfície destacada
  static const Color surfaceHighlight = _bgHighlight;

  /// Cor de fundo para chips de habilidades
  static const Color chipSkill = _bgChipSkill;

  /// Cor de fundo para chips de gêneros
  static const Color chipGenre = _bgChipGenre;

  // ===========================================================================
  // SEMANTIC TOKENS - TEXT
  // ===========================================================================

  /// Texto primário (branco)
  static const Color textPrimary = _textWhite;

  /// Texto secundário (cinza claro)
  static const Color textSecondary = _textGray;

  /// Texto terciário (cinza escuro) - baixa ênfase
  static const Color textTertiary = _textDarkGray;

  /// Alias para textTertiary (placeholders)
  static const Color textPlaceholder = textTertiary;

  /// Texto desabilitado
  static Color get textDisabled => _textWhite.withValues(alpha: 0.5);

  // ===========================================================================
  // SEMANTIC TOKENS - ACTION
  // ===========================================================================

  /// Cor para elementos interativos (links, ícones, bordas)
  static const Color semanticAction = Color(0xFFFF5C8D);

  /// Alias para semanticAction
  static const Color textAction = semanticAction;

  // ===========================================================================
  // SEMANTIC TOKENS - BORDER
  // ===========================================================================

  /// Cor de borda padrão
  static const Color border = _bgHighlight;

  // ===========================================================================
  // SEMANTIC TOKENS - FEEDBACK
  // ===========================================================================

  /// Cor de erro
  static const Color error = _error;

  /// Cor de sucesso
  static const Color success = _success;

  /// Cor de informação
  static const Color info = _info;

  /// Cor de aviso
  static const Color warning = _warning;

  // ===========================================================================
  // SEMANTIC TOKENS - BADGES
  // ===========================================================================

  /// Badge para músicos/profissionais
  static const Color badgeMusician = brandPrimary;

  /// Badge para bandas
  static const Color badgeBand = _badgeFuchsia;

  /// Badge para estúdios
  static const Color badgeStudio = _badgeRed;

  /// Fundo do chip de badge
  static const Color badgeChipBackground = _badgeChipBg;

  // ===========================================================================
  // SEMANTIC TOKENS - SKELETON/LOADING
  // ===========================================================================

  /// Cor base para skeletons
  static const Color skeletonBase = _bgSurface;

  /// Cor de highlight para skeletons
  static const Color skeletonHighlight = _bgHighlight;

  // ===========================================================================
  // SEMANTIC TOKENS - STATE
  // ===========================================================================

  /// Cor primária desabilitada
  static Color get primaryDisabled => _primary.withValues(alpha: 0.5);

  // ===========================================================================
  // SEMANTIC TOKENS - AVATAR
  // ===========================================================================

  /// Paleta de cores para avatares
  static const List<Color> avatarColors = [
    Color(0xFFF472B6), // Pink 400
    Color(0xFFA78BFA), // Violet 400
    Color(0xFF60A5FA), // Blue 400
    Color(0xFF34D399), // Emerald 400
    Color(0xFFFBBF24), // Amber 400
    Color(0xFFF87171), // Red 400
  ];

  /// Cor de borda do avatar
  static const Color avatarBorder = _bgDeep;

  /// Opacidade da borda do avatar
  static const double avatarBorderOpacity = 1.0;
}
