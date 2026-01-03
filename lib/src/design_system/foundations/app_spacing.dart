import 'package:flutter/widgets.dart';

class AppSpacing {
  const AppSpacing._();

  // ---------------------------------------------------------------------------
  // Spacing Constants
  // ---------------------------------------------------------------------------
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // ---------------------------------------------------------------------------
  // EdgeInsets Helpers
  // ---------------------------------------------------------------------------

  // All
  static const EdgeInsets all4 = EdgeInsets.all(s4);
  static const EdgeInsets all8 = EdgeInsets.all(s8);
  static const EdgeInsets all12 = EdgeInsets.all(s12);
  static const EdgeInsets all16 = EdgeInsets.all(s16);
  static const EdgeInsets all24 = EdgeInsets.all(s24);

  // Horizontal
  static const EdgeInsets h8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: s24);

  // Vertical
  static const EdgeInsets v8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets v24 = EdgeInsets.symmetric(vertical: s24);

  // Combinations (Common patterns)
  static const EdgeInsets h16v12 = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s12,
  );
}
