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

  /// 8px - Small radius
  static const double r8 = 8.0;

  /// 12px - Medium radius
  static const double r12 = 12.0;

  /// 16px - Large radius
  static const double r16 = 16.0;

  /// 20px - Extra large radius
  static const double r20 = 20.0;

  /// 24px - 2x Large radius
  static const double r24 = 24.0;

  /// 28px - 3x Large radius
  static const double r28 = 28.0;

  /// 100px - Pill/Full radius
  static const double rPill = 100.0;

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
  static const double button = 28.0;

  /// Radius para chips
  static const double chip = 20.0;

  /// Radius para avatares
  static const double avatar = 100.0;

  // ===========================================================================
  // BORDER RADIUS - ALL SIDES
  // ===========================================================================

  static const BorderRadius all8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius all12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius all16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius all20 = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius all24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius all28 = BorderRadius.all(Radius.circular(r28));
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
