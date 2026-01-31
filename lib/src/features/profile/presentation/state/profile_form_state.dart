import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user.dart';
import '../../domain/validators/profile_validator.dart';

/// State class for profile form
/// Tracks all editable fields and their dirty state
class ProfileFormState {
  final String name;
  final String bio;
  final String artisticName;
  final String phone;
  final String birthDate;
  final String gender;
  final String instagram;

  // Professional fields
  final List<String> categories;
  final List<String> genres;
  final List<String> instruments;
  final List<String> roles;
  final String backingVocalMode;
  final bool instrumentalistBackingVocal;

  // Studio fields
  final String studioType;
  final List<String> services;

  // Band fields
  final List<String> bandGenres;

  // State flags
  final bool isDirty;
  final bool isSaving;
  final bool isInitialized;

  const ProfileFormState({
    this.name = '',
    this.bio = '',
    this.artisticName = '',
    this.phone = '',
    this.birthDate = '',
    this.gender = '',
    this.instagram = '',
    this.categories = const [],
    this.genres = const [],
    this.instruments = const [],
    this.roles = const [],
    this.backingVocalMode = '0',
    this.instrumentalistBackingVocal = false,
    this.studioType = '',
    this.services = const [],
    this.bandGenres = const [],
    this.isDirty = false,
    this.isSaving = false,
    this.isInitialized = false,
  });

  /// Create from existing user
  factory ProfileFormState.fromUser(AppUser user) {
    final prof = user.dadosProfissional;
    final studio = user.dadosEstudio;
    final band = user.dadosBanda;
    final contractor = user.dadosContratante;

    return ProfileFormState(
      name: user.nome ?? '',
      bio: user.bio ?? '',
      artisticName: prof?.nomeArtistico ?? studio?.nomeArtistico ?? '',
      phone: prof?.celular ?? studio?.celular ?? contractor?.celular ?? '',
      birthDate: prof?.dataNascimento ?? contractor?.dataNascimento ?? '',
      gender: prof?.genero ?? contractor?.genero ?? '',
      instagram: prof?.instagram ?? contractor?.instagram ?? '',
      categories: prof?.categorias ?? [],
      genres: prof?.generosMusicais ?? [],
      instruments: prof?.instrumentos ?? [],
      roles: prof?.funcoes ?? [],
      backingVocalMode: prof?.backingVocalMode ?? '0',
      instrumentalistBackingVocal: prof?.instrumentalistBackingVocal ?? false,
      studioType: studio?.studioType ?? '',
      services: studio?.servicosOferecidos ?? [],
      bandGenres: band?.generosMusicais ?? [],
      isInitialized: true,
    );
  }

  ProfileFormState copyWith({
    String? name,
    String? bio,
    String? artisticName,
    String? phone,
    String? birthDate,
    String? gender,
    String? instagram,
    List<String>? categories,
    List<String>? genres,
    List<String>? instruments,
    List<String>? roles,
    String? backingVocalMode,
    bool? instrumentalistBackingVocal,
    String? studioType,
    List<String>? services,
    List<String>? bandGenres,
    bool? isDirty,
    bool? isSaving,
    bool? isInitialized,
  }) {
    return ProfileFormState(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      artisticName: artisticName ?? this.artisticName,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      instagram: instagram ?? this.instagram,
      categories: categories ?? this.categories,
      genres: genres ?? this.genres,
      instruments: instruments ?? this.instruments,
      roles: roles ?? this.roles,
      backingVocalMode: backingVocalMode ?? this.backingVocalMode,
      instrumentalistBackingVocal:
          instrumentalistBackingVocal ?? this.instrumentalistBackingVocal,
      studioType: studioType ?? this.studioType,
      services: services ?? this.services,
      bandGenres: bandGenres ?? this.bandGenres,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// Convert to validation data map
  Map<String, dynamic> toValidationData() {
    return {
      'categories': categories,
      'instruments': instruments,
      'genres': genres,
      'roles': roles,
      'services': services,
      'bandGenres': bandGenres,
    };
  }
}

/// StateNotifier for managing profile form state
class ProfileFormNotifier extends StateNotifier<ProfileFormState> {
  final AppUser _originalUser;
  final ProfileValidator _validator;

  ProfileFormNotifier(this._originalUser)
    : _validator = ProfileValidator.forUserType(_originalUser.tipoPerfil),
      super(ProfileFormState.fromUser(_originalUser));

  /// Update a field and mark as dirty
  void updateField<T>(
    T Function(ProfileFormState) getter,
    T value,
    ProfileFormState Function(ProfileFormState, T) updater,
  ) {
    state = updater(state, value).copyWith(isDirty: true);
  }

  // Field-specific updaters
  void updateName(String value) {
    state = state.copyWith(name: value, isDirty: true);
  }

  void updateBio(String value) {
    state = state.copyWith(bio: value, isDirty: true);
  }

  void updateCategories(List<String> value) {
    // Clear dependent fields when category is removed
    var newInstruments = state.instruments;
    var newRoles = state.roles;
    var newBackingVocalMode = state.backingVocalMode;
    var newInstrumentalistBackingVocal = state.instrumentalistBackingVocal;

    if (!value.contains('instrumentalist')) {
      newInstruments = [];
      newInstrumentalistBackingVocal = false;
    }
    if (!value.contains('crew')) {
      newRoles = [];
    }
    if (!value.contains('singer')) {
      newBackingVocalMode = '0';
    }

    state = state.copyWith(
      categories: value,
      instruments: newInstruments,
      roles: newRoles,
      backingVocalMode: newBackingVocalMode,
      instrumentalistBackingVocal: newInstrumentalistBackingVocal,
      isDirty: true,
    );
  }

  void updateGenres(List<String> value) {
    state = state.copyWith(genres: value, isDirty: true);
  }

  void updateInstruments(List<String> value) {
    state = state.copyWith(instruments: value, isDirty: true);
  }

  void updateRoles(List<String> value) {
    state = state.copyWith(roles: value, isDirty: true);
  }

  void updateServices(List<String> value) {
    state = state.copyWith(services: value, isDirty: true);
  }

  void updateBandGenres(List<String> value) {
    state = state.copyWith(bandGenres: value, isDirty: true);
  }

  /// Validate the current state
  ValidationResult validate() {
    return _validator.validate(state.toValidationData());
  }

  /// Get all validation errors
  List<String> getAllErrors() {
    return _validator.getAllErrors(state.toValidationData());
  }

  /// Mark as saving
  void startSaving() {
    state = state.copyWith(isSaving: true);
  }

  /// Mark save complete
  void finishSaving({bool success = true}) {
    state = state.copyWith(
      isSaving: false,
      isDirty: success ? false : state.isDirty,
    );
  }

  /// Reset to original user state
  void reset() {
    state = ProfileFormState.fromUser(_originalUser);
  }
}

/// Provider family - one notifier per user
final profileFormProvider =
    StateNotifierProvider.family<
      ProfileFormNotifier,
      ProfileFormState,
      AppUser
    >((ref, user) => ProfileFormNotifier(user));
