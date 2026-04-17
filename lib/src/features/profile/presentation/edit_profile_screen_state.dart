part of 'edit_profile_screen.dart';

extension _EditProfileScreenStateSetup on _EditProfileScreenState {
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
}
