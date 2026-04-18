import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/patterns/full_width_selection_card.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

/// Professional category selection step with full-width cards.
///
/// Allows selecting from:
/// - Cantor(a)
/// - Instrumentista
/// - DJ
/// - Produção Musical
/// - Técnica de Palco
/// - Audiovisual e Fotografia
/// - Design Gráfico
/// - Social Media e Marketing
/// - Educação
/// - Luthier
/// - Performance
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
      'id': 'dj',
      'label': 'DJ',
      'description': 'Ex: DJ de festa, eventos e sets ao vivo',
      'icon': FontAwesomeIcons.compactDisc,
    },
    {
      'id': 'production',
      'label': 'Produção Musical',
      'description':
          'Ex: Produção, mixagem, composição, letra, arranjos e direção',
      'icon': FontAwesomeIcons.sliders,
    },
    {
      'id': 'stage_tech',
      'label': 'Técnica de Palco',
      'description': 'Ex: PA, monitor, RF, luz, LED, roadie e backline',
      'icon': FontAwesomeIcons.wrench,
    },
    {
      'id': 'audiovisual',
      'label': 'Audiovisual e Fotografia',
      'description':
          'Ex: Vídeo, fotografia, transmissão, captação, edição e motion',
      'icon': FontAwesomeIcons.camera,
    },
    {
      'id': 'graphic_design',
      'label': 'Design Gráfico',
      'description':
          'Ex: Capa de álbum, identidade visual e material de divulgação',
      'icon': FontAwesomeIcons.palette,
    },
    {
      'id': 'marketing',
      'label': 'Social Media e Marketing',
      'description':
          'Ex: Gestão de redes, campanhas, copywriting e lançamentos',
      'icon': FontAwesomeIcons.bullhorn,
    },
    {
      'id': 'education',
      'label': 'Educação',
      'description': 'Ex: Aulas, oficinas, mentoria, palestras e consultoria',
      'icon': Icons.school_outlined,
    },
    {
      'id': 'luthier',
      'label': 'Luthier',
      'description':
          'Ex: Ajuste, reparo, construção e manutenção de instrumentos',
      'icon': Icons.handyman_outlined,
    },
    {
      'id': 'performance',
      'label': 'Performance',
      'description': 'Ex: Cena, live acts, intervenção artística e corpo',
      'icon': Icons.auto_awesome_outlined,
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
        Text(
          'Qual é sua área?',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all20,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                'Você pode marcar mais de uma opção.',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
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
              const SizedBox(height: AppSpacing.s12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '${_selected.length} de ${_categories.length} selecionadas',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s32),

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
              selectionMode: SelectionMode.multi,
              onTap: () => _toggleCategory(category['id']),
            ),
          );
        }),

        const SizedBox(height: AppSpacing.s48),

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
