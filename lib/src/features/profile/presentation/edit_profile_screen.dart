import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../common_widgets/formatters/sentence_start_uppercase_formatter.dart';
import '../../../constants/app_constants.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_skeleton.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_effects.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../utils/instagram_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../domain/music_link_validator.dart';
import 'edit_profile/controllers/edit_profile_controller.dart';
import 'edit_profile/widgets/edit_profile_header.dart';
import 'edit_profile/widgets/forms/band_form_fields.dart';
import 'edit_profile/widgets/forms/contractor_form_fields.dart';
import 'edit_profile/widgets/forms/music_links_form.dart';
import 'edit_profile/widgets/forms/professional_form_fields.dart';
import 'edit_profile/widgets/forms/studio_form_fields.dart';
import 'edit_profile/widgets/media_gallery_section.dart';
import 'music_platform_catalog.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _bioFormatter = SentenceStartUppercaseTextInputFormatter();
  late TabController _tabController;
  final _profileFormKey = GlobalKey<FormState>();
  final _musicLinksFormKey = GlobalKey<FormState>();
  final Set<int> _visitedTabs = {0};

  // Controllers for text fields managed in UI state
  late TextEditingController _nomeController;
  late TextEditingController _nomeArtisticoController;
  late TextEditingController _celularController;
  late TextEditingController _dataNascimentoController;
  late TextEditingController _generoController;
  late TextEditingController _instagramController;
  late TextEditingController _bioController;
  late TextEditingController _spotifyController;
  late TextEditingController _deezerController;
  late TextEditingController _youtubeMusicController;
  late TextEditingController _appleMusicController;

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _isControllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    // Preload app config to avoid empty option lists on first modal open.
    unawaited(ref.read(appConfigProvider.future));
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    if (_isControllersInitialized) {
      _nomeController.dispose();
      _nomeArtisticoController.dispose();
      _celularController.dispose();
      _dataNascimentoController.dispose();
      _generoController.dispose();
      _instagramController.dispose();
      _bioController.dispose();
      _spotifyController.dispose();
      _deezerController.dispose();
      _youtubeMusicController.dispose();
      _appleMusicController.dispose();
    }
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == _tabController.previousIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_visitedTabs.add(_tabController.index) && mounted) {
      setState(() {});
    }
  }

  String _normalizeBio(String value) {
    final formatted = _bioFormatter.formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: value),
    );
    return formatted.text;
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
    _bioController = TextEditingController(text: user.profileBio ?? '');

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
        insta = data['instagram'] ?? '';
        break;
      case AppUserType.studio:
        final data = user.dadosEstudio ?? {};
        nomeArt =
            data['nomeEstudio'] ?? data['nomeArtistico'] ?? data['nome'] ?? '';
        cel = data['celular'] ?? '';
        insta = data['instagram'] ?? '';
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
    _generoController = TextEditingController(text: normalizeGenderValue(gen));
    _instagramController = TextEditingController(
      text: normalizeInstagramHandle(insta),
    );
    _spotifyController = TextEditingController(
      text: user.musicLinks[MusicLinkValidator.spotifyKey] ?? '',
    );
    _deezerController = TextEditingController(
      text: user.musicLinks[MusicLinkValidator.deezerKey] ?? '',
    );
    _youtubeMusicController = TextEditingController(
      text: user.musicLinks[MusicLinkValidator.youtubeMusicKey] ?? '',
    );
    _appleMusicController = TextEditingController(
      text: user.musicLinks[MusicLinkValidator.appleMusicKey] ?? '',
    );

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
    _spotifyController.addListener(markChanged);
    _deezerController.addListener(markChanged);
    _youtubeMusicController.addListener(markChanged);
    _appleMusicController.addListener(markChanged);

    _isControllersInitialized = true;
  }

  Map<String, TextEditingController> get _musicLinkControllers => {
    MusicLinkValidator.spotifyKey: _spotifyController,
    MusicLinkValidator.deezerKey: _deezerController,
    MusicLinkValidator.youtubeMusicKey: _youtubeMusicController,
    MusicLinkValidator.appleMusicKey: _appleMusicController,
  };

  bool _shouldBuildTab(int index) =>
      _visitedTabs.contains(index) || _tabController.index == index;

  Future<bool> _validateProfileForm({required bool isContractor}) async {
    final profileFormState = _profileFormKey.currentState;
    if (profileFormState == null) return true;

    final isValid = profileFormState.validate();
    if (!isValid && !isContractor && _tabController.index != 0) {
      _tabController.animateTo(0);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    return isValid;
  }

  Future<Map<String, String>?> _resolveMusicLinksForSave({
    required AppUser user,
    required bool isContractor,
  }) async {
    if (isContractor) {
      return const <String, String>{};
    }

    final preservedUnsupportedLinks = <String, String>{
      for (final entry in user.musicLinks.entries)
        if (!MusicLinkValidator.supportedKeys.contains(entry.key))
          entry.key: entry.value,
    };

    final sanitized = MusicLinkValidator.sanitize({
      for (final platform in musicPlatformCatalog)
        platform.key: _musicLinkControllers[platform.key]!.text,
    });

    for (final platform in musicPlatformCatalog) {
      final value = sanitized[platform.key];
      final error = MusicLinkValidator.validate(platform.key, value);
      if (error == null) continue;

      if (_tabController.index != 2) {
        _tabController.animateTo(2);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      if (!mounted) return null;
      _musicLinksFormKey.currentState?.validate();
      AppSnackBar.warning(context, error);
      return null;
    }

    final linksFormState = _musicLinksFormKey.currentState;
    if (linksFormState == null) {
      return {...preservedUnsupportedLinks, ...sanitized};
    }

    final isValid = linksFormState.validate();
    if (!isValid) {
      if (_tabController.index != 2) {
        _tabController.animateTo(2);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!mounted) return null;
      linksFormState.validate();
      AppSnackBar.warning(context, 'Revise os links musicais preenchidos.');
      return null;
    }

    return {...preservedUnsupportedLinks, ...sanitized};
  }

  Future<void> _handleSave(AppUser user) async {
    final editState = ref.read(editProfileControllerProvider(user.uid));
    final controller = ref.read(
      editProfileControllerProvider(user.uid).notifier,
    );
    final isContractor = user.tipoPerfil == AppUserType.contractor;

    if (editState.isUploadingMedia) {
      if (mounted) {
        AppSnackBar.warning(
          context,
          editState.uploadStatus.isNotEmpty
              ? editState.uploadStatus
              : 'Aguarde o envio da mídia terminar para salvar o perfil.',
        );
      }
      return;
    }

    final isProfileFormValid = await _validateProfileForm(
      isContractor: isContractor,
    );
    if (!isProfileFormValid) {
      return;
    }

    final musicLinks = await _resolveMusicLinksForSave(
      user: user,
      isContractor: isContractor,
    );
    if (musicLinks == null) {
      return;
    }

    try {
      await controller.saveProfile(
        user: user,
        nome: _nomeController.text.trim(),
        bio: _normalizeBio(_bioController.text.trim()),
        nomeArtistico: _nomeArtisticoController.text.trim(),
        celular: _celularController.text.trim(),
        dataNascimento: _dataNascimentoController.text.trim(),
        genero: normalizeGenderValue(_generoController.text),
        instagram: normalizeInstagramHandle(_instagramController.text),
        musicLinks: musicLinks,
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

    if (state.isUploadingMedia) {
      if (mounted) {
        AppSnackBar.warning(
          context,
          state.uploadStatus.isNotEmpty
              ? state.uploadStatus
              : 'Aguarde o processamento da mídia terminar antes de sair.',
        );
      }
      return;
    }

    if (!state.hasChanges) {
      context.pop();
      return;
    }

    final shouldLeave = await AppOverlay.dialog<bool>(
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
      loading: () => const _EditProfileScreenSkeleton(),
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
        final editUiState = ref.watch(
          editProfileControllerProvider(user.uid).select(
            (state) => (
              hasChanges: state.hasChanges,
              isSaving: state.isSaving,
              isUploadingMedia: state.isUploadingMedia,
              uploadStatus: state.uploadStatus,
            ),
          ),
        );
        final isContractor = user.tipoPerfil == AppUserType.contractor;

        return PopScope(
          canPop: !editUiState.hasChanges && !editUiState.isUploadingMedia,
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
                      onTap: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
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
                        Tab(text: 'Mídia'),
                        Tab(text: 'Links Musicais'),
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
                            _shouldBuildTab(1)
                                ? MediaGallerySection(user: user)
                                : const SizedBox.shrink(),
                            _shouldBuildTab(2)
                                ? Form(
                                    key: _musicLinksFormKey,
                                    child: MusicLinksForm(
                                      controllers: _musicLinkControllers,
                                      onChanged: ref
                                          .read(
                                            editProfileControllerProvider(
                                              user.uid,
                                            ).notifier,
                                          )
                                          .markChanged,
                                    ),
                                  )
                                : const SizedBox.shrink(),
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
                  onPressed:
                      editUiState.hasChanges &&
                          !editUiState.isSaving &&
                          !editUiState.isUploadingMedia
                      ? () => _handleSave(user)
                      : null,
                  isLoading: editUiState.isSaving,
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
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user.tipoPerfil == AppUserType.professional) ...[
              Text('Informações Pessoais', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.s16),
            ],
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
          offersRemoteRecording: editState.offersRemoteRecording,
          onOffersRemoteRecordingChanged: notifier.setOffersRemoteRecording,
          onStateChanged: notifier.markChanged,
        );
      case AppUserType.studio:
        return StudioFormFields(
          nomeEstudioController: _nomeArtisticoController,
          celularController: _celularController,
          instagramController: _instagramController,
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
          instagramController: _instagramController,
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

class _EditProfileScreenSkeleton extends StatelessWidget {
  const _EditProfileScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: 'Editar Perfil', showBackButton: true),
      body: SafeArea(
        child: SkeletonShimmer(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: SkeletonBox(
                  width: double.infinity,
                  height: AppSpacing.s48,
                  borderRadius: AppRadius.rPill,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppSpacing.s8),
                      Center(child: SkeletonCircle(size: 104)),
                      SizedBox(height: AppSpacing.s20),
                      SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonBox(height: 124, borderRadius: AppRadius.r12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: SkeletonShimmer(
            child: SkeletonBox(
              width: double.infinity,
              height: 56,
              borderRadius: AppRadius.r24,
            ),
          ),
        ),
      ),
    );
  }
}
