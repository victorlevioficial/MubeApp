import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Estilos semânticos específicos para componentes do Design System Mube.
///
/// Este arquivo centraliza estilos que são aplicáveis a um ou poucos
/// componentes (chips, cards, badges, buttons, etc.) mantendo
/// [AppTypography] focado apenas em escalas de tipografia.
///
/// Uso:
/// ```dart
/// Text('Label', style: AppComponentStyles.chipLabel)
/// Text('Título do Card', style: AppComponentStyles.cardTitle)
/// ```
class AppComponentStyles {
  const AppComponentStyles._();

  // ===========================================================================
  // CHIP STYLES
  // ===========================================================================

  /// Estilo para labels de chips (skills, genres)
  static TextStyle get chipLabel => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  // ===========================================================================
  // CARD STYLES
  // ===========================================================================

  /// Estilo para títulos de cards verticais
  static TextStyle get cardTitle => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // ===========================================================================
  // SETTINGS STYLES
  // ===========================================================================

  /// Estilo para título de grupo em settings
  static TextStyle get settingsGroupTitle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 2.0,
  );

  // ===========================================================================
  // PROFILE BADGE STYLES
  // ===========================================================================

  /// Estilo para label do tipo de perfil
  static TextStyle get profileTypeLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 1.5,
  );

  // ===========================================================================
  // MATCHPOINT STYLES
  // ===========================================================================

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

  // ===========================================================================
  // BUTTON STYLES
  // ===========================================================================

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

  // ===========================================================================
  // INPUT STYLES
  // ===========================================================================

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

  // ===========================================================================
  // ERROR STYLES
  // ===========================================================================

  /// Estilo para erro
  static TextStyle get error => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    letterSpacing: 0,
  );
}
