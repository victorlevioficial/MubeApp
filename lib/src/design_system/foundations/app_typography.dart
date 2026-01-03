import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  const AppTypography._();

  // ---------------------------------------------------------------------------
  // Font Family
  // ---------------------------------------------------------------------------
  static const String fontFamily = 'Inter';

  // ---------------------------------------------------------------------------
  // Text Styles
  // ---------------------------------------------------------------------------

  // Headlines
  static TextStyle get headlineLarge =>
      GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700);

  static TextStyle get headlineMedium =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700);

  // Titles
  static TextStyle get titleLarge =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get titleMedium =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600);

  // Body
  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);
}
