import 'package:flutter/widgets.dart';

/// Tokens de bordas arredondadas do Design System Mube.
///
/// Todos os border radius devem usar estas constantes para garantir
/// consistência visual nos componentes.
///
/// Uso recomendado:
/// ```dart
/// BorderRadius.circular(AppRadius.r12)
/// Container(decoration: BoxDecoration(borderRadius: AppRadius.all12))
/// ```
class AppRadius {
  const AppRadius._();

  // ===========================================================================
  // RADIUS TOKENS
  // ===========================================================================

  /// 4px - Micro radius
  static const double r4 = 4.0;

  /// 8px - Small radius
  static const double r8 = 8.0;

  /// 12px - Medium radius
  static const double r12 = 12.0;

  /// 16px - Large radius
  static const double r16 = 16.0;

  /// 24px - Extra large radius
  static const double r24 = 24.0;

  /// 999px - Pill/Full radius
  static const double rPill = 999.0;

  // ===========================================================================
  // SEMANTIC RADIUS
  // ===========================================================================

  /// Radius para bubbles de chat
  static const double chatBubble = 12.0;

  /// Radius para cards
  static const double card = 16.0;

  /// Radius para bottom sheets
  static const double bottomSheet = 24.0;

  /// Radius para modais
  static const double modal = 24.0;

  /// Radius para inputs
  static const double input = 12.0;

  /// Radius para botões
  static const double button = rPill;

  /// Radius para chips
  static const double chip = rPill;

  /// Radius para avatares
  static const double avatar = 100.0;

  // ===========================================================================
  // BORDER RADIUS - ALL SIDES
  // ===========================================================================

  static const BorderRadius all4 = BorderRadius.all(Radius.circular(r4));
  static const BorderRadius all8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius all12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius all16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius all24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(rPill));

  // ===========================================================================
  // BORDER RADIUS - VERTICAL ONLY
  // ===========================================================================

  /// Topo arredondado (para bottom sheets)
  static const BorderRadius top24 = BorderRadius.vertical(
    top: Radius.circular(r24),
  );

  static const BorderRadius top16 = BorderRadius.vertical(
    top: Radius.circular(r16),
  );

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Cria um BorderRadius circular com valor customizado
  static BorderRadius circular(double radius) =>
      BorderRadius.all(Radius.circular(radius));

  /// Cria um BorderRadius horizontal (esquerda ou direita)
  static BorderRadius horizontal({double left = 0, double right = 0}) =>
      BorderRadius.horizontal(
        left: Radius.circular(left),
        right: Radius.circular(right),
      );

  /// Cria um BorderRadius vertical (topo ou base)
  static BorderRadius vertical({double top = 0, double bottom = 0}) =>
      BorderRadius.vertical(
        top: Radius.circular(top),
        bottom: Radius.circular(bottom),
      );
}
