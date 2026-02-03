import 'package:flutter/widgets.dart';

/// Tokens de espaçamento do Design System Mube.
///
/// Todos os espaçamentos devem usar estas constantes para garantir
/// consistência e ritmo visual no aplicativo.
///
/// Uso recomendado:
/// ```dart
/// const SizedBox(height: AppSpacing.s16)
/// const Padding(padding: AppSpacing.all16)
/// ```
class AppSpacing {
  const AppSpacing._();

  // ===========================================================================
  // SCALE TOKENS (Base 4px)
  // ===========================================================================

  /// 2px - Micro espaçamento
  static const double s2 = 2.0;

  /// 4px - Extra small
  static const double s4 = 4.0;

  /// 6px - Small compact
  static const double s6 = 6.0;

  /// 8px - Small
  static const double s8 = 8.0;

  /// 12px - Small medium
  static const double s12 = 12.0;

  /// 16px - Medium (base)
  static const double s16 = 16.0;

  /// 20px - Medium large
  static const double s20 = 20.0;

  /// 24px - Large
  static const double s24 = 24.0;

  /// 32px - Extra large
  static const double s32 = 32.0;

  /// 40px - 2x Large
  static const double s40 = 40.0;

  /// 48px - 3x Large
  static const double s48 = 48.0;

  /// 64px - 4x Large
  static const double s64 = 64.0;

  // ===========================================================================
  // EDGE INSETS - ALL SIDES
  // ===========================================================================

  static const EdgeInsets all4 = EdgeInsets.all(s4);
  static const EdgeInsets all8 = EdgeInsets.all(s8);
  static const EdgeInsets all12 = EdgeInsets.all(s12);
  static const EdgeInsets all16 = EdgeInsets.all(s16);
  static const EdgeInsets all24 = EdgeInsets.all(s24);

  // ===========================================================================
  // EDGE INSETS - HORIZONTAL
  // ===========================================================================

  static const EdgeInsets h8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets h12 = EdgeInsets.symmetric(horizontal: s12);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets h20 = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: s24);
  static const EdgeInsets h32 = EdgeInsets.symmetric(horizontal: s32);

  // ===========================================================================
  // EDGE INSETS - VERTICAL
  // ===========================================================================

  static const EdgeInsets v8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets v12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets v20 = EdgeInsets.symmetric(vertical: s20);
  static const EdgeInsets v24 = EdgeInsets.symmetric(vertical: s24);
  static const EdgeInsets v32 = EdgeInsets.symmetric(vertical: s32);

  // ===========================================================================
  // EDGE INSETS - COMBINATIONS
  // ===========================================================================

  /// Horizontal 16 + Vertical 12
  static const EdgeInsets h16v12 = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s12,
  );

  /// Horizontal 16 + Vertical 8
  static const EdgeInsets h16v8 = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s8,
  );

  /// Horizontal 24 + Vertical 16
  static const EdgeInsets h24v16 = EdgeInsets.symmetric(
    horizontal: s24,
    vertical: s16,
  );

  // ===========================================================================
  // EDGE INSETS - SCREEN PADDING
  // ===========================================================================

  /// Padding padrão para telas
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s24,
  );

  /// Padding horizontal para telas
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: s16,
  );
}
