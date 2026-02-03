import 'package:flutter/material.dart';

import '../../components/chips/app_chip.dart';
import '../../components/chips/app_filter_chip.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

/// Seção de demonstração de Chips.
class ChipsSection extends StatefulWidget {
  const ChipsSection({super.key});

  @override
  State<ChipsSection> createState() => _ChipsSectionState();
}

class _ChipsSectionState extends State<ChipsSection> {
  bool _filterSelected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skill Chips', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppChip.skill(label: 'Guitarra'),
            AppChip.skill(label: 'Bateria'),
            AppChip.skill(label: 'Vocal'),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        Text('Genre Chips', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppChip.genre(label: 'Rock'),
            AppChip.genre(label: 'Pop'),
            AppChip.genre(label: 'Jazz'),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        Text('Filter Chips', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppFilterChip(
              label: 'Perto de mim',
              isSelected: _filterSelected,
              icon: Icons.location_on,
              onSelected: (v) => setState(() => _filterSelected = v),
            ),
            const AppFilterChip(label: 'Disponível', isSelected: true),
            const AppFilterChip(label: 'Online', isSelected: false),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        Text('Action Chips', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppChip.action(label: 'Adicionar', icon: Icons.add, onTap: () {}),
            AppChip.action(label: 'Editar', icon: Icons.edit, onTap: () {}),
          ],
        ),
      ],
    );
  }
}
