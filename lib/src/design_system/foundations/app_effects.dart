import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized visual effects (Shadows, Blurs, Glassmorphism).
class AppEffects {
  const AppEffects._();

  // ---------------------------------------------------------------------------
  // Shadows (Glows & Depth)
  // ---------------------------------------------------------------------------

  /// Subtle glow for primary actions (Buttons, FABs)
  static final List<BoxShadow> primaryGlow = []; // Removed as per feedback

  /// Standard card elevation (Pro Depth)
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Deep shadow for floating elements (Modals, BottomSheets)
  static final List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.6),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Glassmorphism (Frosted Glass)
  // ---------------------------------------------------------------------------

  /// Blur amount for glass surfaces
  static const double glassBlur = 20.0;

  /// Background color for glass surfaces
  static final Color glassColor = AppColors.background.withValues(alpha: 0.7);

  /// Decoration for glass containers (Card, Navbar)
  static final BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.03),
    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
  );

  /// Helper to apply blur filter
  static ImageFilter get blurFilter =>
      ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur);
}
