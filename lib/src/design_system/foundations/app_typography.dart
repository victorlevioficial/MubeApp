import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  // ... (keeping existing lines implied, but replacing header and problematic getter)

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

  static TextStyle get headlineSmall =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700);

  // Titles
  static TextStyle get titleLarge =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get titleMedium =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600);

  // Body
  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);

  // Labels
  static TextStyle get labelMedium =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500);

  // ---------------------------------------------------------------------------
  // Use Case Specific (Semantic)
  // ---------------------------------------------------------------------------

  /// Used for the main title in Vertical Feed Cards
  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, // Default for cards on dark bg
  );

  /// Used for small chips (skills, genres)
  static TextStyle get chipLabel =>
      GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500);
}
