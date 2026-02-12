import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_effects.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import 'edit_profile/controllers/edit_profile_controller.dart';
import 'edit_profile/widgets/edit_profile_header.dart';
import 'edit_profile/widgets/forms/band_form_fields.dart';
import 'edit_profile/widgets/forms/contractor_form_fields.dart';
import 'edit_profile/widgets/forms/professional_form_fields.dart';
import 'edit_profile/widgets/forms/studio_form_fields.dart';
import 'edit_profile/widgets/media_gallery_section.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields managed in UI state
  late TextEditingController _nomeController;
  late TextEditingController _nomeArtisticoController;
  late TextEditingController _celularController;
  late TextEditingController _dataNascimentoController;
  late TextEditingController _generoController;
  late TextEditingController _instagramController;
  late TextEditingController _bioController;

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _isControllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Preload app config to avoid empty option lists on first modal open.
    unawaited(ref.read(appConfigProvider.future));
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isControllersInitialized) {
      _nomeController.dispose();
      _nomeArtisticoController.dispose();
      _celularController.dispose();
      _dataNascimentoController.dispose();
      _generoController.dispose();
      _instagramController.dispose();
      _bioController.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(AppUser user) {
    if (_isControllersInitialized) return;

    var registrationName = user.nome ?? '';
    if (registrationName.trim().isEmpty &&
        (user.tipoPerfil == AppUserType.band ||
            user.tipoPerfil == AppUserType.studio)) {
      registrationName = user.appDisplayName;
    }

    _nomeController = TextEditingController(text: registrationName);
    _bioController = TextEditingController(text: user.bio ?? '');

    String nomeArt = '';
    String cel = '';
    String dataNasc = '';
    String gen = '';
    String insta = '';

    switch (user.tipoPerfil) {
      case AppUserType.professional:
        final data = user.dadosProfissional ?? {};
        nomeArt = data['nomeArtistico'] ?? '';
        cel = data['celular'] ?? '';
        dataNasc = data['dataNascimento'] ?? '';
        gen = data['genero'] ?? '';
        insta = data['instagram'] ?? '';
        break;
      case AppUserType.band:
        final data = user.dadosBanda ?? {};
        nomeArt =
            data['nomeBanda'] ?? data['nomeArtistico'] ?? data['nome'] ?? '';
        break;
      case AppUserType.studio:
        final data = user.dadosEstudio ?? {};
        nomeArt =
            data['nomeEstudio'] ?? data['nomeArtistico'] ?? data['nome'] ?? '';
        cel = data['celular'] ?? '';
        break;
      case AppUserType.contractor:
        final data = user.dadosContratante ?? {};
        cel = data['celular'] ?? '';
        dataNasc = data['dataNascimento'] ?? '';
        gen = data['genero'] ?? '';
        insta = data['instagram'] ?? '';
        break;
      default:
        break;
    }

    if (nomeArt.isEmpty) {
      nomeArt = user.appDisplayName;
    }

    _nomeArtisticoController = TextEditingController(text: nomeArt);
    _celularController = TextEditingController(text: cel);
    _dataNascimentoController = TextEditingController(text: dataNasc);
    _generoController = TextEditingController(text: gen);
    _instagramController = TextEditingController(text: insta);

    // Listen for changes to mark state as dirty
    void markChanged() {
      ref.read(editProfileControllerProvider(user.uid).notifier).markChanged();
    }

    _nomeController.addListener(markChanged);
    _bioController.addListener(markChanged);
    _nomeArtisticoController.addListener(markChanged);
    _celularController.addListener(markChanged);
    _dataNascimentoController.addListener(markChanged);
    _generoController.addListener(markChanged);
    _instagramController.addListener(markChanged);

    _isControllersInitialized = true;
  }

  Future<void> _handleSave(AppUser user) async {
    final controller = ref.read(
      editProfileControllerProvider(user.uid).notifier,
    );

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    try {
      await controller.saveProfile(
        user: user,
        nome: _nomeController.text.trim(),
        bio: _bioController.text.trim(),
        nomeArtistico: _nomeArtisticoController.text.trim(),
        celular: _celularController.text.trim(),
        dataNascimento: _dataNascimentoController.text.trim(),
        genero: _generoController.text.trim(),
        instagram: _instagramController.text.trim(),
      );

      if (mounted) {
        AppSnackBar.success(context, 'Perfil atualizado com sucesso!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString());
      }
    }
  }

  Future<void> _handleBack(AppUser user) async {
    final state = ref.read(editProfileControllerProvider(user.uid));

    if (!state.hasChanges) {
      context.pop();
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Descartar alterações?',
        message:
            'Você tem alterações não salvas. Deseja realmente sair sem salvar?',
        confirmText: 'Descartar',
        cancelText: 'Continuar editando',
        isDestructive: true,
      ),
    );

    if (shouldLeave == true && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch current user to get ID and initial data
    final userAsync = ref.watch(currentUserProfileProvider);

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

        // Initialize controllers once
        if (!_isControllersInitialized) {
          _initializeControllers(user);
        }

        // Watch edit state
        final editState = ref.watch(editProfileControllerProvider(user.uid));
        final isContractor = user.tipoPerfil == AppUserType.contractor;

        return PopScope(
          canPop: !editState.hasChanges,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            unawaited(_handleBack(user));
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppAppBar(
              title: 'Editar Perfil',
              showBackButton: true,
              onBackPressed: () => _handleBack(user),
            ),
            body: Column(
              children: [
                if (!isContractor)
                  Container(
                    margin: const EdgeInsets.all(AppSpacing.s16),
                    height: AppSpacing.s48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.05),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.pill,
                        boxShadow: AppEffects.buttonShadow,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: AppColors.transparent,
                      padding: AppSpacing.all4,
                      tabs: const [
                        Tab(text: 'Perfil'),
                        Tab(text: 'Mídia & Portfólio'),
                      ],
                    ),
                  ),
                Expanded(
                  child: isContractor
                      ? _buildProfileTab(user)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProfileTab(user),
                            MediaGallerySection(user: user),
                          ],
                        ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(
                  left: AppSpacing.s16,
                  right: AppSpacing.s16,
                  bottom: AppSpacing.s16,
                ),
                padding: const EdgeInsets.all(AppSpacing.s10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surface,
                      AppColors.surface.withValues(alpha: 0.98),
                    ],
                  ),
                  borderRadius: AppRadius.all24,
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.background.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AppButton.primary(
                  text: 'Salvar Alterações',
                  onPressed: editState.hasChanges && !editState.isSaving
                      ? () => _handleSave(user)
                      : null,
                  isLoading: editState.isSaving,
                  isFullWidth: true,
                  size: AppButtonSize.large,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditProfileHeader(user: user, nomeController: _nomeController),
            const SizedBox(height: AppSpacing.s24),
            _buildTypeSpecificFields(user),
            // Bottom spacing
            const SizedBox(height: AppSpacing.s48 + AppSpacing.s32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields(AppUser user) {
    final editState = ref.watch(editProfileControllerProvider(user.uid));
    final notifier = ref.read(editProfileControllerProvider(user.uid).notifier);

    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return ProfessionalFormFields(
          nomeArtisticoController: _nomeArtisticoController,
          celularController: _celularController,
          dataNascimentoController: _dataNascimentoController,
          generoController: _generoController,
          instagramController: _instagramController,
          bioController: _bioController,
          celularMask: _celularMask,
          selectedCategories: editState.selectedCategories,
          selectedGenres: editState.selectedGenres,
          selectedInstruments: editState.selectedInstruments,
          selectedRoles: editState.selectedRoles,
          onCategoriesChanged: notifier.updateCategories,
          onGenresChanged: notifier.updateGenres,
          onInstrumentsChanged: notifier.updateInstruments,
          onRolesChanged: notifier.updateRoles,
          backingVocalMode: editState.backingVocalMode,
          onBackingVocalModeChanged: notifier.setBackingVocalMode,
          instrumentalistBackingVocal: editState.instrumentalistBackingVocal,
          onInstrumentalistBackingVocalChanged:
              notifier.setInstrumentalistBackingVocal,
          onStateChanged: notifier.markChanged,
        );
      case AppUserType.studio:
        return StudioFormFields(
          nomeEstudioController: _nomeArtisticoController,
          celularController: _celularController,
          celularMask: _celularMask,
          studioType: editState.studioType,
          onStudioTypeChanged: notifier.setStudioType,
          selectedServices: editState.selectedServices,
          onServicesChanged: notifier.updateServices,
          bioController: _bioController,
          onChanged: notifier.markChanged,
        );
      case AppUserType.band:
        return BandFormFields(
          nomeBandaController: _nomeArtisticoController,
          selectedGenres: editState.bandGenres,
          onGenresChanged: notifier.updateBandGenres,
          bioController: _bioController,
          onChanged: notifier.markChanged,
        );
      case AppUserType.contractor:
        return ContractorFormFields(
          celularController: _celularController,
          celularMask: _celularMask,
          dataNascimentoController: _dataNascimentoController,
          generoController: _generoController,
          instagramController: _instagramController,
          bioController: _bioController,
          onChanged: notifier.markChanged,
        );
      default:
        return const SizedBox();
    }
  }
}
