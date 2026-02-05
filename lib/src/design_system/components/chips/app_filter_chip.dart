import 'package:flutter/material.dart';
import 'app_chip.dart';

/// Chip de filtro selecionável do Design System.
///
/// Use [AppChip.filter] para novos componentes.
class AppFilterChip extends StatelessWidget {
  /// Texto exibido no chip.
  final String label;

  /// Se o chip está selecionado (ativo).
  final bool isSelected;

  /// Callback simples de toque (opcional se usar onSelected).
  final VoidCallback? onTap;

  /// Callback que retorna o novo estado booleano.
  final ValueChanged<bool>? onSelected;

  /// Callback para remover o chip (exibe ícone 'X').
  final VoidCallback? onRemove;

  /// Ícone opcional à esquerda do texto.
  final IconData? icon;

  const AppFilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onSelected,
    this.onRemove,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppChip.filter(
      label: label,
      isSelected: isSelected,
      icon: icon,
      onTap: () {
        onTap?.call();
        onSelected?.call(!isSelected);
      },
      onDeleted: onRemove,
    );
  }
}
