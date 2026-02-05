import 'dart:ui';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens de efeitos visuais do Design System Mube.
///
/// Inclui sombras, blur, glassmorphism e outros efeitos visuais.
///
/// Uso recomendado:
/// ```dart
/// Container(decoration: BoxDecoration(boxShadow: AppEffects.cardShadow))
/// BackdropFilter(filter: AppEffects.blurFilter)
/// ```
class AppEffects {
  const AppEffects._();

  // ===========================================================================
  // SHADOWS
  // ===========================================================================

  /// Sombra padrão para cards
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sombra profunda para elementos flutuantes
  static final List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.6),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  /// Sombra sutil para elementos elevados
  static final List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sombra para botões
  static final List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Sem sombra
  static const List<BoxShadow> none = [];

  // ===========================================================================
  // BLUR
  // ===========================================================================

  /// Quantidade de blur para superfícies glass
  static const double glassBlur = 20.0;

  /// Quantidade de blur leve
  static const double lightBlur = 10.0;

  /// Quantidade de blur pesado
  static const double heavyBlur = 40.0;

  /// Filtro de blur padrão
  static ImageFilter get blurFilter =>
      ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur);

  /// Filtro de blur leve
  static ImageFilter get lightBlurFilter =>
      ImageFilter.blur(sigmaX: lightBlur, sigmaY: lightBlur);

  // ===========================================================================
  // GLASSMORPHISM
  // ===========================================================================

  /// Cor de fundo para superfícies glass
  static final Color glassColor = AppColors.background.withValues(alpha: 0.7);

  /// Decoração para containers glass
  static final BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.03),
    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
  );

  /// Decoração para cards glass
  static final BoxDecoration glassCardDecoration = BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.8),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
  );

  // ===========================================================================
  // OPACITY
  // ===========================================================================

  /// Opacidade para elementos desabilitados
  static const double disabledOpacity = 0.5;

  /// Opacidade para elementos secundários
  static const double secondaryOpacity = 0.7;

  /// Opacidade para elementos terciários
  static const double tertiaryOpacity = 0.5;

  /// Opacidade para hover
  static const double hoverOpacity = 0.1;

  /// Opacidade para press
  static const double pressOpacity = 0.2;

  // ===========================================================================
  // ANIMATION DURATIONS
  // ===========================================================================

  /// Duração rápida para micro-interações
  static const Duration fast = Duration(milliseconds: 150);

  /// Duração normal para transições
  static const Duration normal = Duration(milliseconds: 300);

  /// Duração lenta para animações elaboradas
  static const Duration slow = Duration(milliseconds: 500);

  /// Duração para entrada de elementos
  static const Duration entrance = Duration(milliseconds: 400);
}
