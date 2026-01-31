import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../constants/app_constants.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import 'profile_controller.dart';

/// Focused screen for editing professional categories
class EditCategoriesScreen extends ConsumerStatefulWidget {
  const EditCategoriesScreen({super.key});

  @override
  ConsumerState<EditCategoriesScreen> createState() =>
      _EditCategoriesScreenState();
}

class _EditCategoriesScreenState extends ConsumerState<EditCategoriesScreen> {
  late List<String> _selectedCategories;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  void _initFromUser(AppUser user) {
    if (_isInitialized) return;

    final prof = user.dadosProfissional ?? {};
    final cats = (prof['categorias'] as List<dynamic>?)?.cast<String>() ?? [];
    _selectedCategories = List.from(cats);
    _isInitialized = true;
  }

  void _onCategoryToggle(String categoryId, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategories.add(categoryId);
      } else {
        _selectedCategories.remove(categoryId);
      }
      _hasChanges = true;
    });
  }

  Future<void> _save(AppUser user) async {
    if (_isSaving) return;

    // Validate
    if (_selectedCategories.isEmpty) {
      AppSnackBar.error(context, 'Selecione pelo menos uma categoria.');
      return;
    }

    // Check for dependent data that will be lost
    final prof = user.dadosProfissional ?? {};
    final oldCategories =
        (prof['categorias'] as List<dynamic>?)?.cast<String>() ?? [];
    final removingInstrumentalist =
        oldCategories.contains('instrumentalist') &&
        !_selectedCategories.contains('instrumentalist');
    final removingCrew =
        oldCategories.contains('crew') && !_selectedCategories.contains('crew');

    if (removingInstrumentalist || removingCrew) {
      final confirmed = await _showConfirmationDialog(
        removingInstrumentalist: removingInstrumentalist,
        removingCrew: removingCrew,
      );
      if (!confirmed) return;
    }

    setState(() => _isSaving = true);

    try {
      // Build updates - clear dependent data if category removed
      final Map<String, dynamic> updates = {
        'profissional': {
          'categorias': _selectedCategories,
          if (removingInstrumentalist) 'instrumentos': <String>[],
          if (removingInstrumentalist) 'instrumentalist_backing_vocal': false,
          if (removingCrew) 'funcoes': <String>[],
          if (!_selectedCategories.contains('singer'))
            'backing_vocal_mode': '0',
        },
      };

      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(currentUser: user, updates: updates);

      if (mounted) {
        AppSnackBar.success(context, 'Categorias atualizadas!');
        context.pop();
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar categorias', e);
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.error(context, 'Erro ao salvar: $e');
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required bool removingInstrumentalist,
    required bool removingCrew,
  }) async {
    final items = <String>[];
    if (removingInstrumentalist) items.add('instrumentos');
    if (removingCrew) items.add('funções técnicas');

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Atenção'),
            content: Text(
              'Ao remover essa categoria, seus ${items.join(" e ")} selecionados serão limpos. Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Continuar',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final isLoading = ref.watch(profileControllerProvider).isLoading;

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erro: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Usuário não encontrado')),
          );
        }

        _initFromUser(user);

        return PopScope(
          canPop: !_hasChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _hasChanges) {
              _showDiscardDialog();
            }
          },
          child: Scaffold(
            appBar: const MubeAppBar(title: 'Categorias'),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('O que você faz?', style: AppTypography.headlineMedium),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Selecione todas as categorias que se aplicam a você.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  // Category chips
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        children: professionalCategories.map((cat) {
                          final id = cat['id'] as String;
                          final label = cat['label'] as String;
                          final isSelected = _selectedCategories.contains(id);

                          return FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) =>
                                _onCategoryToggle(id, selected),
                            selectedColor: AppColors.semanticAction.withOpacity(
                              0.2,
                            ),
                            checkmarkColor: AppColors.semanticAction,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.semanticAction
                                  : AppColors.surfaceHighlight,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.s16),

                  PrimaryButton(
                    text: 'Salvar',
                    isLoading: isLoading || _isSaving,
                    onPressed: _hasChanges ? () => _save(user) : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você tem alterações não salvas. Deseja realmente sair sem salvar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text('Descartar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
