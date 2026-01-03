import 'package:flutter/widgets.dart';

class AppRadius {
  const AppRadius._();

  // ---------------------------------------------------------------------------
  // Radius Constants
  // ---------------------------------------------------------------------------
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r24 = 24.0;
  static const double r28 = 28.0;
  static const double rPill = 100.0;

  // ---------------------------------------------------------------------------
  // BorderRadius Helpers
  // ---------------------------------------------------------------------------

  static const BorderRadius all8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius all12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius all16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius all24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(rPill));

  static BorderRadius circular(double radius) =>
      BorderRadius.all(Radius.circular(radius));
}
