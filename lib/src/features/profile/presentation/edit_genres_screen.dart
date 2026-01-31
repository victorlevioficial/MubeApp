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
import '../../auth/domain/user_type.dart';
import 'profile_controller.dart';

/// Focused screen for editing music genres
class EditGenresScreen extends ConsumerStatefulWidget {
  const EditGenresScreen({super.key});

  @override
  ConsumerState<EditGenresScreen> createState() => _EditGenresScreenState();
}

class _EditGenresScreenState extends ConsumerState<EditGenresScreen> {
  late List<String> _selectedGenres;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  void _initFromUser(AppUser user) {
    if (_isInitialized) return;

    List<String> userGenres = [];
    if (user.tipoPerfil == AppUserType.professional) {
      final prof = user.dadosProfissional ?? {};
      userGenres =
          (prof['generos_musicais'] as List<dynamic>?)?.cast<String>() ?? [];
    } else if (user.tipoPerfil == AppUserType.band) {
      final band = user.dadosBanda ?? {};
      userGenres =
          (band['generos_musicais'] as List<dynamic>?)?.cast<String>() ?? [];
    }

    _selectedGenres = List.from(userGenres);
    _isInitialized = true;
  }

  Future<void> _openGenreSelector() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSelectionModal(
        title: 'Gêneros Musicais',
        items: genres,
        selectedItems: _selectedGenres,
        allowMultiple: true,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedGenres = result;
        _hasChanges = true;
      });
    }
  }

  void _removeGenre(String genre) {
    setState(() {
      _selectedGenres.remove(genre);
      _hasChanges = true;
    });
  }

  Future<void> _save(AppUser user) async {
    if (_isSaving) return;

    if (_selectedGenres.isEmpty) {
      AppSnackBar.error(context, 'Selecione pelo menos um gênero musical.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> updates = {};
      if (user.tipoPerfil == AppUserType.professional) {
        updates = {
          'profissional': {'generos_musicais': _selectedGenres},
        };
      } else if (user.tipoPerfil == AppUserType.band) {
        updates = {
          'banda': {'generos_musicais': _selectedGenres},
        };
      }

      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(currentUser: user, updates: updates);

      if (mounted) {
        AppSnackBar.success(context, 'Gêneros atualizados!');
        context.pop();
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar gêneros', e);
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
            appBar: const MubeAppBar(title: 'Gêneros Musicais'),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quais gêneros você toca?',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Selecione os gêneros musicais que representam seu trabalho.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  // Add button
                  SecondaryButton(
                    text: _selectedGenres.isEmpty
                        ? 'Selecionar gêneros'
                        : 'Editar seleção',
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: _openGenreSelector,
                  ),

                  const SizedBox(height: AppSpacing.s16),

                  // Selected genres chips
                  Expanded(
                    child: _selectedGenres.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum gênero selecionado',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _selectedGenres.map((genre) {
                                return AppFilterChip(
                                  label: genre,
                                  isSelected: true,
                                  onSelected: (_) {},
                                  onRemove: () => _removeGenre(genre),
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
