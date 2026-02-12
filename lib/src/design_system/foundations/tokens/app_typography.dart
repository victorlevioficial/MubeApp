import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tokens de tipografia do Design System Mube.
///
/// Todas as fontes e estilos de texto devem usar estas constantes
/// para garantir consistência tipográfica no aplicativo.
///
/// Uso recomendado:
/// ```dart
/// Text('Título', style: AppTypography.titleLarge)
/// Text('Body', style: AppTypography.bodyMedium)
/// ```
class AppTypography {
  const AppTypography._();

  // ===========================================================================
  // FONT FAMILY
  // ===========================================================================

  /// Fonte para titulos e subtitulos
  static const String fontFamilyDisplay = 'Poppins';

  /// Fonte para textos e labels
  static const String fontFamilyBody = 'Inter';

  // ===========================================================================
  // HEADLINES
  // ===========================================================================

  /// Headline Large - 28px, Bold
  /// Uso: Títulos principais de tela
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Headline Compact - 24px, Bold
  /// Uso: Títulos de tela mais compactos
  static TextStyle get headlineCompact => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  /// Headline Medium - 20px, Bold
  /// Uso: Títulos de seção
  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  /// Headline Small - 18px, Bold
  /// Uso: Subtítulos
  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // ===========================================================================
  // TITLES
  // ===========================================================================

  /// Title Large - 18px, Semi-bold
  /// Uso: Títulos de cards
  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  /// Title Medium - 16px, Semi-bold
  /// Uso: Títulos de listas
  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  /// Title Small - 14px, Semi-bold
  /// Uso: Labels importantes
  static TextStyle get titleSmall => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // ===========================================================================
  // BODY
  // ===========================================================================

  /// Body Large - 16px, Medium
  /// Uso: Texto principal
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Body Medium - 14px, Medium
  /// Uso: Texto secundário
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Body Small - 12px, Medium
  /// Uso: Texto terciário, captions
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0,
    height: 1.3,
  );

  // ===========================================================================
  // LABELS
  // ===========================================================================

  /// Label Large - 14px, Medium
  /// Uso: Labels de formulário
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  /// Label Medium - 13px, Medium
  /// Uso: Labels de botões
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  /// Label Small - 11px, Medium
  /// Uso: Tags, badges
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  // ===========================================================================
  // SEMANTIC STYLES - COMPONENT SPECIFIC
  // ===========================================================================

  /// Estilo para títulos de cards verticais
  static TextStyle get cardTitle => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  /// Estilo para labels de chips (skills, genres)
  static TextStyle get chipLabel => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  /// Estilo para título de grupo em settings
  static TextStyle get settingsGroupTitle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 2.0,
  );

  /// Estilo para label do tipo de perfil
  static TextStyle get profileTypeLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 1.5,
  );

  /// Estilo para título do Match Success
  static TextStyle get matchSuccessTitle => GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    color: AppColors.primary,
    letterSpacing: 2,
  );

  /// Estilo para kicker do Match Success
  static TextStyle get matchSuccessKicker => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 4,
  );

  /// Estilo para botão primário
  static TextStyle get buttonPrimary => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  /// Estilo para botão secundário
  static TextStyle get buttonSecondary => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  /// Estilo para input
  static TextStyle get input => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  /// Estilo para hint/placeholder
  static TextStyle get inputHint => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPlaceholder,
    letterSpacing: 0,
  );

  /// Estilo para erro
  static TextStyle get error => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    letterSpacing: 0,
  );

  /// Estilo para links de texto
  static TextStyle get link => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 0,
  );
}
