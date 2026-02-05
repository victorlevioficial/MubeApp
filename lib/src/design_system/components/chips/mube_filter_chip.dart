import 'package:flutter/material.dart';
import 'app_chip.dart';

/// Chip de filtro alternativo usado em algumas telas.
class MubeFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  const MubeFilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onSelected,
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
    );
  }
}
