import 'package:flutter/material.dart';

class AppIcons {
  const AppIcons._();

  // ---------------------------------------------------------------------------
  // Arrows
  // ---------------------------------------------------------------------------
  /// Simple ">" arrow
  static const IconData arrowForward = Icons.arrow_forward_ios;

  /// Simple "<" arrow
  static const IconData arrowBack = Icons.arrow_back_ios;

  /// Dropdown arrow
  static const IconData dropdown = Icons.keyboard_arrow_down;

  // ---------------------------------------------------------------------------
  // Social
  // ---------------------------------------------------------------------------
  // Note: For social logos (Google, Apple), use SvgPicture assets instead of Icons if possible.
  // Here we keep placeholders if needed, but the Button component handles SVGs.

  // ---------------------------------------------------------------------------
  // Feedback
  // ---------------------------------------------------------------------------
  static const IconData error = Icons.error_outline;
  static const IconData success = Icons.check_circle_outline;
}
