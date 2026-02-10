import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_typography.dart';
import 'app_back_button.dart';

/// AppBar padronizada do Design System Mube.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Titulo da AppBar (String ou Widget).
  final dynamic title;

  /// Acoes da AppBar (lado direito).
  final List<Widget>? actions;

  /// Widget customizado no lado esquerdo.
  final Widget? leading;

  /// Se deve mostrar o botao de voltar. Padrao: true se Navigator.canPop().
  final bool? showBackButton;

  /// Callback customizado para o botao de voltar.
  final VoidCallback? onBackPressed;

  /// Se o titulo deve ser centralizado. Padrao: true.
  final bool centerTitle;

  /// Widget bottom (ex: TabBar).
  final PreferredSizeWidget? bottom;

  /// Cor de fundo opcional.
  final Color? backgroundColor;

  /// Elevacao da sombra.
  final double? elevation;

  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
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
    final resolvedLeading =
        leading ??
        (shouldShowBack ? AppBackButton(onPressed: onBackPressed) : null);

    return AppBar(
      backgroundColor:
          backgroundColor ?? AppColors.background.withValues(alpha: 0.8),
      elevation: elevation,
      leading: resolvedLeading,
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
