import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/patterns/full_width_selection_card.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

/// Professional category selection step with full-width cards.
///
/// Allows selecting from:
/// - Cantor(a)
/// - Instrumentista
/// - Equipe Técnica
/// - DJ
///
/// Uses the modern full-width card design instead of grid.
class ProfessionalCategoryStep extends StatefulWidget {
  final List<String> selectedCategories;
  final ValueChanged<List<String>> onCategoriesChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ProfessionalCategoryStep({
    super.key,
    required this.selectedCategories,
    required this.onCategoriesChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ProfessionalCategoryStep> createState() =>
      _ProfessionalCategoryStepState();
}

class _ProfessionalCategoryStepState extends State<ProfessionalCategoryStep> {
  late List<String> _selected;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'singer',
      'label': 'Cantor(a)',
      'description': 'Ex: Vocalista principal, coral, backing vocal',
      'icon': FontAwesomeIcons.microphone,
    },
    {
      'id': 'instrumentalist',
      'label': 'Instrumentista',
      'description': 'Ex: Guitarra, bateria, piano, baixo, cordas, sopros',
      'icon': FontAwesomeIcons.guitar,
    },
    {
      'id': 'crew',
      'label': 'Equipe Técnica',
      'description': 'Ex: Técnico de som, luz, roadie, produtor musical',
      'icon': FontAwesomeIcons.wrench,
    },
    {
      'id': 'dj',
      'label': 'DJ',
      'description': 'Ex: DJ de festa e eventos',
      'icon': FontAwesomeIcons.compactDisc,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedCategories);
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selected.contains(categoryId)) {
        _selected.remove(categoryId);
      } else {
        _selected.add(categoryId);
      }
    });
    widget.onCategoriesChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          'Qual é sua área?',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Selecione uma ou mais categorias que descrevem\nsua atuação profissional',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.s32),

        // Category Cards
        ...List.generate(_categories.length, (index) {
          final category = _categories[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _categories.length - 1 ? AppSpacing.s16 : 0,
            ),
            child: FullWidthSelectionCard(
              icon: category['icon'],
              title: category['label'],
              description: category['description'],
              isSelected: _selected.contains(category['id']),
              onTap: () => _toggleCategory(category['id']),
            ),
          );
        }),

        const SizedBox(height: AppSpacing.s48),

        // Continue Button
        SizedBox(
          height: 56,
          child: AppButton.primary(
            text: 'Continuar',
            size: AppButtonSize.large,
            onPressed: _selected.isNotEmpty ? widget.onNext : null,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}
