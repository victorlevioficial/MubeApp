import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_selection_modal.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/secondary_button.dart';
import '../../../common_widgets/app_filter_chip.dart';
import '../../../constants/app_constants.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import 'profile_controller.dart';

/// Focused screen for editing instruments
class EditInstrumentsScreen extends ConsumerStatefulWidget {
  const EditInstrumentsScreen({super.key});

  @override
  ConsumerState<EditInstrumentsScreen> createState() =>
      _EditInstrumentsScreenState();
}

class _EditInstrumentsScreenState extends ConsumerState<EditInstrumentsScreen> {
  late List<String> _selectedInstruments;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  void _initFromUser(AppUser user) {
    if (_isInitialized) return;

    final prof = user.dadosProfissional ?? {};
    final userInstruments =
        (prof['instrumentos'] as List<dynamic>?)?.cast<String>() ?? [];
    _selectedInstruments = List.from(userInstruments);
    _isInitialized = true;
  }

  Future<void> _openInstrumentSelector() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSelectionModal(
        title: 'Instrumentos',
        items: instruments,
        selectedItems: _selectedInstruments,
        allowMultiple: true,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedInstruments = result;
        _hasChanges = true;
      });
    }
  }

  void _removeInstrument(String instrument) {
    setState(() {
      _selectedInstruments.remove(instrument);
      _hasChanges = true;
    });
  }

  Future<void> _save(AppUser user) async {
    if (_isSaving) return;

    // Check if user is still instrumentalist
    final prof = user.dadosProfissional ?? {};
    final categorias =
        (prof['categorias'] as List<dynamic>?)?.cast<String>() ?? [];
    final isInstrumentalist = categorias.contains('instrumentalist');

    if (isInstrumentalist && _selectedInstruments.isEmpty) {
      AppSnackBar.error(context, 'Selecione pelo menos um instrumento.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
            currentUser: user,
            updates: {
              'profissional': {'instrumentos': _selectedInstruments},
            },
          );

      if (mounted) {
        AppSnackBar.success(context, 'Instrumentos atualizados!');
        context.pop();
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar instrumentos', e);
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.error(context, 'Erro ao salvar: $e');
      }
    }
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
            appBar: const MubeAppBar(title: 'Instrumentos'),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quais instrumentos você toca?',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Selecione todos os instrumentos que você domina.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  SecondaryButton(
                    text: _selectedInstruments.isEmpty
                        ? 'Selecionar instrumentos'
                        : 'Editar seleção',
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: _openInstrumentSelector,
                  ),

                  const SizedBox(height: AppSpacing.s16),

                  Expanded(
                    child: _selectedInstruments.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum instrumento selecionado',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _selectedInstruments.map((instrument) {
                                return AppFilterChip(
                                  label: instrument,
                                  isSelected: true,
                                  onSelected: (_) {},
                                  onRemove: () => _removeInstrument(instrument),
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
