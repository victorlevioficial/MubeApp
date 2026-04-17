import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../common_widgets/formatters/sentence_start_uppercase_formatter.dart';
import '../../../constants/app_constants.dart';
import '../../../core/errors/error_message_resolver.dart';
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
import '../../../routing/route_paths.dart';
import '../../../utils/instagram_utils.dart';
import '../../../utils/public_username.dart';
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

enum _UsernameAvailabilityState {
  idle,
  checking,
  available,
  unavailable,
  current,
  error,
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _bioFormatter = SentenceStartUppercaseTextInputFormatter();
  TabController? _tabController;
  final _profileFormKey = GlobalKey<FormState>();
  final _musicLinksFormKey = GlobalKey<FormState>();
  final Set<int> _visitedTabs = {0};
  Timer? _usernameValidationDebounce;
  final ValueNotifier<int> _usernameUiVersion = ValueNotifier<int>(0);
  _UsernameAvailabilityState _usernameAvailabilityState =
      _UsernameAvailabilityState.idle;
  String? _usernameAvailabilityMessage;
  int _usernameValidationRequestId = 0;

  // Controllers for text fields managed in UI state
  late TextEditingController _nomeController;
  late TextEditingController _nomeArtisticoController;
  late TextEditingController _celularController;
  late TextEditingController _dataNascimentoController;
  late TextEditingController _generoController;
  late TextEditingController _instagramController;
  late TextEditingController _bioController;
  late TextEditingController _usernameController;
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
    // Preload app config to avoid empty option lists on first modal open.
    unawaited(ref.read(appConfigProvider.future));
  }

  @override
  void dispose() {
    _usernameValidationDebounce?.cancel();
    _usernameUiVersion.dispose();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    if (_isControllersInitialized) {
      _nomeController.dispose();
      _nomeArtisticoController.dispose();
      _celularController.dispose();
      _dataNascimentoController.dispose();
      _generoController.dispose();
      _instagramController.dispose();
      _bioController.dispose();
      _usernameController.dispose();
      _spotifyController.dispose();
      _deezerController.dispose();
      _youtubeMusicController.dispose();
      _appleMusicController.dispose();
    }
    super.dispose();
  }

  void _handleTabChange() {
    final tabController = _tabController;
    if (tabController == null) return;

    if (tabController.index == tabController.previousIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_visitedTabs.add(tabController.index) && mounted) {
      setState(() {});
    }
  }

  int _tabCountForUser(AppUser user) {
    return user.tipoPerfil == AppUserType.contractor ? 2 : 3;
  }

  TabController get _activeTabController {
    final controller = _tabController;
    if (controller == null) {
      throw StateError('TabController should be initialized before use.');
    }
    return controller;
  }

  void _ensureTabControllerForUser(AppUser user) {
    final expectedLength = _tabCountForUser(user);
    final current = _tabController;

    if (current != null && current.length == expectedLength) {
      return;
    }

    final previousIndex = current?.index ?? 0;
    current?.removeListener(_handleTabChange);
    current?.dispose();

    final initialIndex = previousIndex.clamp(0, expectedLength - 1);
    final nextController = TabController(
      length: expectedLength,
      vsync: this,
      initialIndex: initialIndex,
    );
    nextController.addListener(_handleTabChange);
    _tabController = nextController;

    _visitedTabs.removeWhere((index) => index >= expectedLength);
    _visitedTabs.add(initialIndex);
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

    _nomeArtisticoController = TextEditingController(text: user.appDisplayName);
    _celularController = TextEditingController(text: user.profilePhone);
    _dataNascimentoController = TextEditingController(
      text: user.profileBirthDate,
    );
    _generoController = TextEditingController(
      text: normalizeGenderValue(user.profileGender),
    );
    _instagramController = TextEditingController(
      text: normalizeInstagramHandle(user.profileInstagram),
    );
    _usernameController = TextEditingController(
      text: user.publicUsername ?? '',
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

    _primeUsernameValidationState(user);
    _isControllersInitialized = true;
  }

  Map<String, TextEditingController> get _musicLinkControllers => {
    MusicLinkValidator.spotifyKey: _spotifyController,
    MusicLinkValidator.deezerKey: _deezerController,
    MusicLinkValidator.youtubeMusicKey: _youtubeMusicController,
    MusicLinkValidator.appleMusicKey: _appleMusicController,
  };

  void _primeUsernameValidationState(AppUser user) {
    final rawUsername = _usernameController.text.trim();
    final normalizedUsername = normalizedPublicUsernameOrNull(rawUsername);
    final currentUsername = normalizedPublicUsernameOrNull(user.publicUsername);
    final formatError = validatePublicUsername(rawUsername);

    if (normalizedUsername == null || formatError != null) {
      _usernameAvailabilityState = _UsernameAvailabilityState.idle;
      _usernameAvailabilityMessage = null;
      return;
    }

    if (normalizedUsername == currentUsername) {
      _usernameAvailabilityState = _UsernameAvailabilityState.current;
      _usernameAvailabilityMessage = 'Esse e o seu @usuario atual.';
      return;
    }

    _usernameAvailabilityState = _UsernameAvailabilityState.idle;
    _usernameAvailabilityMessage = null;
  }

  void _setUsernameAvailabilityState(
    _UsernameAvailabilityState nextState, {
    String? message,
  }) {
    if (_usernameAvailabilityState == nextState &&
        _usernameAvailabilityMessage == message) {
      return;
    }
    _usernameAvailabilityState = nextState;
    _usernameAvailabilityMessage = message;
    _usernameUiVersion.value++;
  }

  void _scheduleUsernameValidation(AppUser user) {
    _usernameValidationDebounce?.cancel();
    final rawUsername = _usernameController.text.trim();
    final normalizedUsername = normalizedPublicUsernameOrNull(rawUsername);
    final currentUsername = normalizedPublicUsernameOrNull(user.publicUsername);
    final formatError = validatePublicUsername(rawUsername);
    final requestId = ++_usernameValidationRequestId;

    if (normalizedUsername == null) {
      _setUsernameAvailabilityState(_UsernameAvailabilityState.idle);
      return;
    }

    if (formatError != null) {
      _setUsernameAvailabilityState(_UsernameAvailabilityState.idle);
      return;
    }

    if (normalizedUsername == currentUsername) {
      _setUsernameAvailabilityState(
        _UsernameAvailabilityState.current,
        message: 'Esse e o seu @usuario atual.',
      );
      return;
    }

    _setUsernameAvailabilityState(
      _UsernameAvailabilityState.checking,
      message: 'Verificando disponibilidade...',
    );

    _usernameValidationDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(
        _checkUsernameAvailability(
          user: user,
          normalizedUsername: normalizedUsername,
          requestId: requestId,
        ),
      );
    });
  }

  void _handleUsernameChanged(AppUser user, String _) {
    ref.read(editProfileControllerProvider(user.uid).notifier).markChanged();
    _scheduleUsernameValidation(user);
  }

  Future<void> _checkUsernameAvailability({
    required AppUser user,
    required String normalizedUsername,
    required int requestId,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .isPublicUsernameAvailable(normalizedUsername, excludingUid: user.uid);

    if (!mounted) return;

    final latestUsername = normalizedPublicUsernameOrNull(
      _usernameController.text.trim(),
    );
    if (requestId != _usernameValidationRequestId ||
        latestUsername != normalizedUsername) {
      return;
    }

    result.fold(
      (_) => _setUsernameAvailabilityState(
        _UsernameAvailabilityState.error,
        message: 'Nao foi possivel verificar esse @usuario agora.',
      ),
      (isAvailable) => _setUsernameAvailabilityState(
        isAvailable
            ? _UsernameAvailabilityState.available
            : _UsernameAvailabilityState.unavailable,
        message: isAvailable
            ? '@$normalizedUsername disponivel.'
            : 'Esse @usuario ja esta em uso. Escolha outro.',
      ),
    );
  }

  String? _usernameValidator(AppUser user, String? value) {
    final formatError = validatePublicUsername(value);
    if (formatError != null) {
      return formatError;
    }

    final normalizedUsername = normalizedPublicUsernameOrNull(value);
    final currentUsername = normalizedPublicUsernameOrNull(user.publicUsername);
    if (normalizedUsername == null || normalizedUsername == currentUsername) {
      return null;
    }

    switch (_usernameAvailabilityState) {
      case _UsernameAvailabilityState.available:
        return null;
      case _UsernameAvailabilityState.checking:
        return 'Aguarde a verificacao do @usuario.';
      case _UsernameAvailabilityState.unavailable:
      case _UsernameAvailabilityState.error:
        return _usernameAvailabilityMessage;
      case _UsernameAvailabilityState.idle:
        return 'Verifique a disponibilidade do @usuario.';
      case _UsernameAvailabilityState.current:
        return null;
    }
  }

  bool _canSaveWithUsername(AppUser user) {
    final rawUsername = _usernameController.text.trim();
    final formatError = validatePublicUsername(rawUsername);
    if (formatError != null) {
      return false;
    }

    final normalizedUsername = normalizedPublicUsernameOrNull(rawUsername);
    final currentUsername = normalizedPublicUsernameOrNull(user.publicUsername);
    if (normalizedUsername == null || normalizedUsername == currentUsername) {
      return true;
    }

    return _usernameAvailabilityState == _UsernameAvailabilityState.available;
  }

  Widget? _buildUsernameStatus(AppUser user) {
    final rawUsername = _usernameController.text.trim();
    if (rawUsername.isEmpty) return null;

    final formatError = validatePublicUsername(rawUsername);
    if (formatError != null) {
      return _buildUsernameStatusMessage(
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        message: formatError,
      );
    }

    final normalizedUsername = normalizedPublicUsernameOrNull(rawUsername);
    if (normalizedUsername == null) {
      return null;
    }

    IconData icon;
    Color color;
    String? message;

    switch (_usernameAvailabilityState) {
      case _UsernameAvailabilityState.checking:
        icon = Icons.hourglass_top_rounded;
        color = AppColors.textSecondary;
        message =
            _usernameAvailabilityMessage ?? 'Verificando disponibilidade...';
        break;
      case _UsernameAvailabilityState.available:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        message = _usernameAvailabilityMessage;
        break;
      case _UsernameAvailabilityState.unavailable:
        icon = Icons.highlight_off_rounded;
        color = AppColors.error;
        message = _usernameAvailabilityMessage;
        break;
      case _UsernameAvailabilityState.current:
        icon = Icons.verified_rounded;
        color = AppColors.success;
        message = _usernameAvailabilityMessage;
        break;
      case _UsernameAvailabilityState.error:
        icon = Icons.error_outline_rounded;
        color = AppColors.error;
        message =
            _usernameAvailabilityMessage ??
            'Nao foi possivel verificar esse @usuario agora.';
        break;
      case _UsernameAvailabilityState.idle:
        return null;
    }

    if (message == null || message.isEmpty) {
      return null;
    }

    return _buildUsernameStatusMessage(
      icon: icon,
      color: color,
      message: message,
    );
  }

  Widget _buildUsernameStatusMessage({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldBuildTab(int index) =>
      _visitedTabs.contains(index) || ((_tabController?.index ?? 0) == index);

  Future<bool> _validateProfileForm() async {
    final profileFormState = _profileFormKey.currentState;
    if (profileFormState == null) return true;

    final isValid = profileFormState.validate();
    if (!isValid && _activeTabController.index != 0) {
      _activeTabController.animateTo(0);
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

      if (_activeTabController.index != 2) {
        _activeTabController.animateTo(2);
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
      if (_activeTabController.index != 2) {
        _activeTabController.animateTo(2);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!mounted) return null;
      linksFormState.validate();
      AppSnackBar.warning(context, 'Revise os links musicais preenchidos.');
      return null;
    }

    return {...preservedUnsupportedLinks, ...sanitized};
  }

  void _leaveEditProfile() {
    final router = GoRouter.maybeOf(context);
    if (router?.canPop() ?? false) {
      context.pop();
      return;
    }

    final navigator = Navigator.maybeOf(context);
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
      return;
    }

    router?.go(RoutePaths.settings);
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

    if (!_canSaveWithUsername(user)) {
      if (mounted) {
        AppSnackBar.warning(
          context,
          _usernameValidator(user, _usernameController.text.trim()) ??
              'Revise o @usuario antes de salvar.',
        );
      }
      return;
    }

    final isProfileFormValid = await _validateProfileForm();
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
        username: _usernameController.text.trim(),
        nomeArtistico: _nomeArtisticoController.text.trim(),
        celular: _celularController.text.trim(),
        dataNascimento: _dataNascimentoController.text.trim(),
        genero: normalizeGenderValue(_generoController.text),
        instagram: normalizeInstagramHandle(_instagramController.text),
        musicLinks: musicLinks,
      );

      if (mounted) {
        AppSnackBar.success(context, 'Perfil atualizado com sucesso!');
        _leaveEditProfile();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, resolveErrorMessage(e));
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
      _leaveEditProfile();
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
      _leaveEditProfile();
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
        _ensureTabControllerForUser(user);
        final tabController = _activeTabController;

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
                    controller: tabController,
                    onTap: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
                    tabs: isContractor
                        ? const [Tab(text: 'Perfil'), Tab(text: 'Midia')]
                        : const [
                            Tab(text: 'Perfil'),
                            Tab(text: 'Midia'),
                            Tab(text: 'Links Musicais'),
                          ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      _buildProfileTab(user),
                      _shouldBuildTab(1)
                          ? MediaGallerySection(user: user)
                          : const SizedBox.shrink(),
                      if (!isContractor)
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
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _usernameController,
                  builder: (context, value, child) =>
                      ValueListenableBuilder<int>(
                        valueListenable: _usernameUiVersion,
                        builder: (context, version, innerChild) =>
                            AppButton.primary(
                              text: 'Salvar Alterações',
                              onPressed:
                                  editUiState.hasChanges &&
                                      !editUiState.isSaving &&
                                      !editUiState.isUploadingMedia &&
                                      _canSaveWithUsername(user)
                                  ? () => _handleSave(user)
                                  : null,
                              isLoading: editUiState.isSaving,
                              isFullWidth: true,
                              size: AppButtonSize.large,
                            ),
                      ),
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
            const SizedBox(height: AppSpacing.s16),
            _buildPublicLinkSection(user),
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
          nomeExibicaoController: _nomeArtisticoController,
          celularController: _celularController,
          celularMask: _celularMask,
          dataNascimentoController: _dataNascimentoController,
          generoController: _generoController,
          instagramController: _instagramController,
          bioController: _bioController,
          contractorVenueType: editState.contractorVenueType,
          contractorAmenities: editState.contractorAmenities,
          onVenueTypeChanged: notifier.setContractorVenueType,
          onAmenitiesChanged: notifier.updateContractorAmenities,
          onChanged: notifier.markChanged,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPublicLinkSection(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Link publico do perfil',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Escolha um @usuario para compartilhar seu perfil com um link curto.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _buildUsernameField(user),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _usernameController,
            builder: (context, value, _) {
              return ValueListenableBuilder<int>(
                valueListenable: _usernameUiVersion,
                builder: (context, version, child) {
                  final usernameStatus = _buildUsernameStatus(user);
                  final normalizedUsername = normalizedPublicUsernameOrNull(
                    value.text,
                  );
                  final hasValidUsername =
                      normalizedUsername != null &&
                      validatePublicUsername(normalizedUsername) == null;
                  final previewUrl = RoutePaths.publicProfileShareUrl(
                    uid: user.uid,
                    username: hasValidUsername
                        ? normalizedUsername
                        : user.publicUsername,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...(usernameStatus == null
                          ? const <Widget>[]
                          : <Widget>[usernameStatus]),
                      const SizedBox(height: AppSpacing.s10),
                      Text(
                        'Preview: $previewUrl',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '@usuario',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        TextFormField(
          controller: _usernameController,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          style: AppTypography.input.copyWith(color: AppColors.textPrimary),
          validator: (fieldValue) => _usernameValidator(user, fieldValue),
          onChanged: (value) => _handleUsernameChanged(user, value),
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(maxPublicUsernameLength + 1),
          ],
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'mubeoficial',
            hintStyle: AppTypography.inputHint,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.s16,
                right: AppSpacing.s8,
              ),
              child: Text(
                '@',
                style: AppTypography.input.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: AppSpacing.s16,
            ),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
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
