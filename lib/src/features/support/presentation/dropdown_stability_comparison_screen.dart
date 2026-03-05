import 'package:flutter/material.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';

enum _CategoryInputMode { dropdownOverlay, modalBottomSheet }

class DropdownStabilityComparisonScreen extends StatefulWidget {
  const DropdownStabilityComparisonScreen({super.key});

  @override
  State<DropdownStabilityComparisonScreen> createState() =>
      _DropdownStabilityComparisonScreenState();
}

class _DropdownStabilityComparisonScreenState
    extends State<DropdownStabilityComparisonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _modalCategoryController = TextEditingController();

  final Map<String, String> _categories = const {
    'bug': 'Reportar um Problema',
    'feedback': 'Sugestão ou Feedback',
    'account': 'Problema na Conta',
    'other': 'Outro Assunto',
  };

  _CategoryInputMode _mode = _CategoryInputMode.dropdownOverlay;
  String _selectedCategory = 'feedback';

  @override
  void initState() {
    super.initState();
    _syncModalCategoryLabel();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _modalCategoryController.dispose();
    super.dispose();
  }

  String get _selectedCategoryLabel =>
      _categories[_selectedCategory] ?? _selectedCategory;

  String get _selectedModeLabel {
    return _mode == _CategoryInputMode.dropdownOverlay
        ? 'Dropdown com Overlay'
        : 'Modal Bottom Sheet';
  }

  void _syncModalCategoryLabel() {
    _modalCategoryController.text = _selectedCategoryLabel;
  }

  void _setSelectedCategory(String value) {
    if (!_categories.containsKey(value)) return;
    setState(() {
      _selectedCategory = value;
      _syncModalCategoryLabel();
    });
  }

  Future<void> _openSingleSelectModal() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.top24),
      builder: (context) => AppSelectionModal(
        title: 'Categoria do Ticket',
        items: _categories.keys.toList(),
        selectedItems: [_selectedCategory],
        allowMultiple: false,
        searchHint: 'Buscar categoria...',
        itemLabelBuilder: (item) => _categories[item] ?? item,
      ),
    );

    if (!mounted || selected == null || selected.isEmpty) return;
    _setSelectedCategory(selected.first);
  }

  void _submitSimulation() {
    if (!_formKey.currentState!.validate()) return;
    AppSnackBar.info(
      context,
      'Modo: $_selectedModeLabel | Categoria: $_selectedCategoryLabel',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Comparativo de Dropdown'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tela de comparação em contexto real',
                style: AppTypography.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Alterne entre o dropdown atual e a alternativa por modal para comparar estabilidade e usabilidade.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              _buildModeSelectorCard(),
              const SizedBox(height: AppSpacing.s16),
              _buildCategoryField(),
              const SizedBox(height: AppSpacing.s16),
              AppTextField(
                controller: _titleController,
                label: 'Assunto',
                hint: 'Resumo do problema',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o assunto'
                    : null,
              ),
              const SizedBox(height: AppSpacing.s16),
              AppTextField(
                controller: _descriptionController,
                label: 'Descrição Detalhada',
                hint: 'Conte detalhes do que aconteceu...',
                maxLines: 5,
                validator: (value) => value == null || value.trim().length < 10
                    ? 'Descreva com mais detalhes'
                    : null,
              ),
              const SizedBox(height: AppSpacing.s24),
              AppButton.primary(
                text: 'Simular Envio',
                onPressed: _submitSimulation,
                isFullWidth: true,
              ),
              const SizedBox(height: AppSpacing.s12),
              Container(
                padding: AppSpacing.all12,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.all12,
                  border: Border.all(color: AppColors.surfaceHighlight),
                ),
                child: Text(
                  'Modo ativo: $_selectedModeLabel\nCategoria selecionada: $_selectedCategoryLabel',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelectorCard() {
    return Container(
      padding: AppSpacing.all12,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Modo de seleção da categoria', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.s10),
          SegmentedButton<_CategoryInputMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<_CategoryInputMode>(
                value: _CategoryInputMode.dropdownOverlay,
                label: Text('Atual'),
                icon: Icon(Icons.arrow_drop_down_circle_outlined, size: 18),
              ),
              ButtonSegment<_CategoryInputMode>(
                value: _CategoryInputMode.modalBottomSheet,
                label: Text('Alternativa'),
                icon: Icon(Icons.view_agenda_outlined, size: 18),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              setState(() => _mode = selection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    if (_mode == _CategoryInputMode.dropdownOverlay) {
      return AppDropdownField<String>(
        label: 'Categoria',
        value: _selectedCategory,
        items: _categories.entries
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          _setSelectedCategory(value);
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Selecione uma categoria' : null,
      );
    }

    return AppTextField(
      controller: _modalCategoryController,
      label: 'Categoria',
      hint: 'Selecione',
      readOnly: true,
      canRequestFocus: false,
      onTap: _openSingleSelectModal,
      validator: (_) =>
          _selectedCategory.isEmpty ? 'Selecione uma categoria' : null,
      suffixIcon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.textSecondary,
      ),
    );
  }
}
