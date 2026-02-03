import 'package:flutter/material.dart';

/// Tokens de movimento do Design System Mube.
///
/// Define durações e curvas padrão para animações, permitindo uma
/// experiência de usuário consistente e polida.
class AppMotion {
  const AppMotion._();

  // ===========================================================================
  // DURATIONS
  // ===========================================================================

  /// Duração muito curta (100ms)
  ///
  /// Use para micro-interações como feedback de toque (hover, press).
  static const Duration short = Duration(milliseconds: 100);

  /// Duração curta (200ms)
  ///
  /// Use para transições simples, fades rápidos, mudanças de estado de botões.
  static const Duration medium = Duration(milliseconds: 200);

  /// Duração padrão (300ms)
  ///
  /// Use para navegação, abertura de diálogos, cards expandindo.
  static const Duration standard = Duration(milliseconds: 300);

  /// Duração longa (500ms)
  ///
  /// Use para transições complexas, carregamento, elementos que percorrem
  /// grandes distâncias na tela.
  static const Duration long = Duration(milliseconds: 500);

  // ===========================================================================
  // CURVES
  // ===========================================================================

  /// Curva padrão (Ease Out Cubic)
  ///
  /// Começa rápido e desacelera suavemente. Use para a maioria das animações de UI (entrada).
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Curva enfática (Ease In Out Cubic)
  ///
  /// Acelera e desacelera. Use para movimentos que precisam chamar atenção
  /// ou elementos que se movem de um ponto A para B visível.
  static const Curve emphasizedCurve = Curves.easeInOutCubic;

  /// Curva de saída (Ease In Cubic)
  ///
  /// Começa devagar e acelera. Use para elementos saindo da tela.
  static const Curve leavingCurve = Curves.easeInCubic;

  /// Curva elástica suave
  ///
  /// Use para feedback tátil visual (bouncy buttons).
  static const Curve bounceCurve = Curves.easeOutBack;
}
