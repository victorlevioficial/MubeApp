import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_typography.dart';
import 'app_back_button.dart';

/// AppBar padronizada do Design System Mube.
///
/// Substitui o AppBar padrão do Flutter para garantir consistência visual
/// em todas as telas do aplicativo.
///
/// Features:
/// - Ícone de voltar padronizado (iOS style)
/// - Cores consistentes
/// - Título centralizado por padrão
/// - Suporte a ações e bottom widget
///
/// Uso:
/// ```dart
/// Scaffold(
///   appBar: AppAppBar(title: 'Minha Tela'),
///   body: ...,
/// )
/// ```
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Título da AppBar (String ou Widget).
  final dynamic title;

  /// Ações da AppBar (lado direito).
  final List<Widget>? actions;

  /// Se deve mostrar o botão de voltar. Padrão: true se Navigator.canPop().
  final bool? showBackButton;

  /// Callback customizado para o botão de voltar.
  final VoidCallback? onBackPressed;

  /// Se o título deve ser centralizado. Padrão: true.
  final bool centerTitle;

  /// Widget bottom (ex: TabBar).
  final PreferredSizeWidget? bottom;

  /// Cor de fundo opcional.
  final Color? backgroundColor;

  /// Elevação da sombra.
  final double? elevation;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton,
    this.onBackPressed,
    this.centerTitle = true,
    this.bottom,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? canPop;

    return AppBar(
      backgroundColor:
          backgroundColor ?? AppColors.background.withValues(alpha: 0.8),
      elevation: elevation,
      leading: shouldShowBack ? AppBackButton(onPressed: onBackPressed) : null,
      title: title is String
          ? Text(
              title as String,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: AppTypography.buttonPrimary.fontWeight,
              ),
            )
          : (title as Widget?),
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}

/// Alias deprecado para backward compatibility
@Deprecated('Use AppAppBar instead')
typedef MubeAppBar = AppAppBar;
