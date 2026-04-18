part of 'edit_profile_screen.dart';

extension _EditProfileScreenActions on _EditProfileScreenState {
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
      AppSnackBar.warning(
        context,
        AppLocalizations.of(context)!.edit_profile_music_links_revise,
      );
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
        AppSnackBar.success(
          context,
          AppLocalizations.of(context)!.edit_profile_update_success,
        );
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
              : AppLocalizations.of(
                  context,
                )!.edit_profile_media_still_processing,
        );
      }
      return;
    }

    if (!state.hasChanges) {
      _leaveEditProfile();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final shouldLeave = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: l10n.edit_profile_discard_title,
        message: l10n.edit_profile_discard_message,
        confirmText: l10n.edit_profile_discard_confirm,
        cancelText: l10n.common_cancel,
        isDestructive: true,
      ),
    );

    if (shouldLeave == true && mounted) {
      _leaveEditProfile();
    }
  }
}
