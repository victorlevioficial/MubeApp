import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:mube/src/utils/instagram_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common_widgets/location_service.dart';
import '../../address/domain/resolved_address.dart';
import '../../auth/data/auth_repository.dart';

class OnboardingFormState {
  final String? nome;
  final String? nomeArtistico;
  final String? celular;
  final String? dataNascimento;
  final String? genero;
  final String? instagram;

  // Professional
  final List<String> selectedCategories;
  final List<String> selectedGenres;
  final List<String> selectedInstruments;
  final List<String> selectedRoles;
  final String backingVocalMode;
  final bool instrumentalistBackingVocal;

  // Studio
  final String? studioType;
  final List<String> selectedServices;

  // Contractor / Location
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final double? selectedLat;
  final double? selectedLng;
  final String? initialLocationLabel;

  const OnboardingFormState({
    this.nome,
    this.nomeArtistico,
    this.celular,
    this.dataNascimento,
    this.genero,
    this.instagram,
    this.selectedCategories = const [],
    this.selectedGenres = const [],
    this.selectedInstruments = const [],
    this.selectedRoles = const [],
    this.backingVocalMode = '0',
    this.instrumentalistBackingVocal = false,
    this.studioType,
    this.selectedServices = const [],
    this.cep,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.selectedLat,
    this.selectedLng,
    this.initialLocationLabel,
  });

  OnboardingFormState copyWith({
    String? nome,
    String? nomeArtistico,
    String? celular,
    String? dataNascimento,
    String? genero,
    String? instagram,
    List<String>? selectedCategories,
    List<String>? selectedGenres,
    List<String>? selectedInstruments,
    List<String>? selectedRoles,
    String? backingVocalMode,
    bool? instrumentalistBackingVocal,
    String? studioType,
    List<String>? selectedServices,
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    String? cidade,
    String? estado,
    double? selectedLat,
    double? selectedLng,
    String? initialLocationLabel,
  }) {
    return OnboardingFormState(
      nome: nome ?? this.nome,
      nomeArtistico: nomeArtistico ?? this.nomeArtistico,
      celular: celular ?? this.celular,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      genero: genero ?? this.genero,
      instagram: instagram ?? this.instagram,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedInstruments: selectedInstruments ?? this.selectedInstruments,
      selectedRoles: selectedRoles ?? this.selectedRoles,
      backingVocalMode: backingVocalMode ?? this.backingVocalMode,
      instrumentalistBackingVocal:
          instrumentalistBackingVocal ?? this.instrumentalistBackingVocal,
      studioType: studioType ?? this.studioType,
      selectedServices: selectedServices ?? this.selectedServices,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      selectedLat: selectedLat ?? this.selectedLat,
      selectedLng: selectedLng ?? this.selectedLng,
      initialLocationLabel: initialLocationLabel ?? this.initialLocationLabel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'nomeArtistico': nomeArtistico,
      'celular': celular,
      'dataNascimento': dataNascimento,
      'genero': genero,
      'instagram': instagram,
      'selectedCategories': selectedCategories,
      'selectedGenres': selectedGenres,
      'selectedInstruments': selectedInstruments,
      'selectedRoles': selectedRoles,
      'backingVocalMode': backingVocalMode,
      'instrumentalistBackingVocal': instrumentalistBackingVocal,
      'studioType': studioType,
      'selectedServices': selectedServices,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'selectedLat': selectedLat,
      'selectedLng': selectedLng,
      'initialLocationLabel': initialLocationLabel,
    };
  }

  factory OnboardingFormState.fromMap(Map<String, dynamic> map) {
    return OnboardingFormState(
      nome: map['nome'],
      nomeArtistico: map['nomeArtistico'],
      celular: map['celular'],
      dataNascimento: map['dataNascimento'],
      genero: map['genero'],
      instagram: map['instagram'],
      selectedCategories: List<String>.from(map['selectedCategories'] ?? []),
      selectedGenres: List<String>.from(map['selectedGenres'] ?? []),
      selectedInstruments: List<String>.from(map['selectedInstruments'] ?? []),
      selectedRoles: List<String>.from(map['selectedRoles'] ?? []),
      backingVocalMode: map['backingVocalMode'] ?? '0',
      instrumentalistBackingVocal: map['instrumentalistBackingVocal'] ?? false,
      studioType: map['studioType'],
      selectedServices: List<String>.from(map['selectedServices'] ?? []),
      cep: map['cep'],
      logradouro: map['logradouro'],
      numero: map['numero'],
      bairro: map['bairro'],
      cidade: map['cidade'],
      estado: map['estado'],
      selectedLat: map['selectedLat'],
      selectedLng: map['selectedLng'],
      initialLocationLabel: map['initialLocationLabel'],
    );
  }

  String toJson() => json.encode(toMap());

  factory OnboardingFormState.fromJson(String source) =>
      OnboardingFormState.fromMap(json.decode(source));

  ResolvedAddress? get resolvedAddress {
    final address = ResolvedAddress(
      logradouro: logradouro?.trim() ?? '',
      numero: numero?.trim() ?? '',
      bairro: bairro?.trim() ?? '',
      cidade: cidade?.trim() ?? '',
      estado: estado?.trim() ?? '',
      cep: cep?.trim() ?? '',
      lat: selectedLat,
      lng: selectedLng,
    );

    if (address.logradouro.isEmpty &&
        address.cidade.isEmpty &&
        address.estado.isEmpty &&
        !address.hasCoordinates) {
      return null;
    }
    return address;
  }

  Map<String, dynamic> get locationMap => {
    'cep': cep,
    'logradouro': logradouro,
    'numero': numero,
    'bairro': bairro,
    'cidade': cidade,
    'estado': estado,
    'lat': selectedLat,
    'lng': selectedLng,
  };
}

class OnboardingFormNotifier extends Notifier<OnboardingFormState> {
  static const _storageKey = 'onboarding_form_state';
  static const _persistDebounce = Duration(milliseconds: 350);
  static const _storageUidKey = 'uid';
  static const _storageStateKey = 'state';

  final _locationService = LocationService();
  SharedPreferences? _prefs;
  Timer? _persistTimer;

  @override
  OnboardingFormState build() {
    ref.onDispose(() {
      _persistTimer?.cancel();
    });
    _loadState();
    return const OnboardingFormState();
  }

  Future<SharedPreferences> _getPrefs() async {
    final prefs = _prefs;
    if (prefs != null) return prefs;
    final instance = await ref.read(sharedPreferencesLoaderProvider)();
    _prefs = instance;
    return instance;
  }

  Future<void> _loadState() async {
    final prefs = await _getPrefs();
    if (!ref.mounted) return;
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final restoredState = _decodePersistedState(jsonStr);
        if (restoredState != null) {
          state = restoredState;
        } else {
          await prefs.remove(_storageKey);
        }
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Falha ao restaurar estado do onboarding',
          error,
          stackTrace,
        );
      }
    }
  }

  Future<void> _saveState() async {
    final prefs = await _getPrefs();
    if (!ref.mounted) return;
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }

    final payload = json.encode({
      _storageUidKey: currentUserId,
      _storageStateKey: state.toMap(),
    });
    await prefs.setString(_storageKey, payload);
  }

  OnboardingFormState? _decodePersistedState(String rawJson) {
    final decoded = json.decode(rawJson);
    if (decoded is! Map) {
      return null;
    }

    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      return null;
    }

    final storedUserId = decoded[_storageUidKey];
    final stateMap = decoded[_storageStateKey];
    if (storedUserId is! String || stateMap is! Map) {
      return null;
    }

    if (storedUserId != currentUserId) {
      return null;
    }

    return OnboardingFormState.fromMap(Map<String, dynamic>.from(stateMap));
  }

  void _scheduleSave() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, () {
      unawaited(_saveState());
    });
  }

  Future<void> clearState() async {
    _persistTimer?.cancel();
    state = const OnboardingFormState();
    final prefs = await _getPrefs();
    await prefs.remove(_storageKey);
  }

  Future<void> fetchInitialLocation() async {
    if (state.logradouro != null && state.logradouro!.isNotEmpty) return;

    try {
      if (!LocationService.isConfigured) return;

      final position = await _locationService.getCurrentPosition();
      final details = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (details == null) return;

      final parts = <String>[
        details.titleLine,
        details.subtitleLine,
      ].where((value) => value.trim().isNotEmpty).toList();
      final label = parts.isEmpty ? 'Localização atual' : parts.join(' - ');
      state = state.copyWith(initialLocationLabel: label);
    } on LocationServiceException {
      // Preview is optional; ignore operational location errors here.
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao buscar localização inicial no onboarding',
        error,
        stackTrace,
      );
    }
  }

  void updateNome(String value) {
    if (state.nome == value) return;
    state = state.copyWith(nome: value);
    _scheduleSave();
  }

  void updateNomeArtistico(String value) {
    if (state.nomeArtistico == value) return;
    state = state.copyWith(nomeArtistico: value);
    _scheduleSave();
  }

  void updateCelular(String value) {
    if (state.celular == value) return;
    state = state.copyWith(celular: value);
    _scheduleSave();
  }

  void updateDataNascimento(String value) {
    if (state.dataNascimento == value) return;
    state = state.copyWith(dataNascimento: value);
    _scheduleSave();
  }

  void updateGenero(String value) {
    if (state.genero == value) return;
    state = state.copyWith(genero: value);
    _scheduleSave();
  }

  void updateInstagram(String value) {
    final normalized = normalizeInstagramHandle(value);
    if (state.instagram == normalized) return;
    state = state.copyWith(instagram: normalized);
    _scheduleSave();
  }

  void updateCategories(List<String> value) => updateSelectedCategories(value);
  void updateGenres(List<String> value) => updateSelectedGenres(value);
  void updateInstruments(List<String> value) =>
      updateSelectedInstruments(value);
  void updateRoles(List<String> value) => updateSelectedRoles(value);
  void updateServices(List<String> value) => updateSelectedServices(value);

  void updateSelectedCategories(List<String> value) {
    state = state.copyWith(selectedCategories: value);
    _scheduleSave();
  }

  void updateSelectedGenres(List<String> value) {
    state = state.copyWith(selectedGenres: value);
    _scheduleSave();
  }

  void updateSelectedInstruments(List<String> value) {
    state = state.copyWith(selectedInstruments: value);
    _scheduleSave();
  }

  void updateSelectedRoles(List<String> value) {
    state = state.copyWith(selectedRoles: value);
    _scheduleSave();
  }

  void updateBackingVocalMode(String value) {
    if (state.backingVocalMode == value) return;
    state = state.copyWith(backingVocalMode: value);
    _scheduleSave();
  }

  void updateInstrumentalistBackingVocal(bool value) {
    if (state.instrumentalistBackingVocal == value) return;
    state = state.copyWith(instrumentalistBackingVocal: value);
    _scheduleSave();
  }

  void updateStudioType(String value) {
    if (state.studioType == value) return;
    state = state.copyWith(studioType: value);
    _scheduleSave();
  }

  void updateSelectedServices(List<String> value) {
    state = state.copyWith(selectedServices: value);
    _scheduleSave();
  }

  void updateAddress({
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    String? cidade,
    String? estado,
    double? lat,
    double? lng,
  }) {
    state = state.copyWith(
      cep: cep ?? state.cep,
      logradouro: logradouro ?? state.logradouro,
      numero: numero ?? state.numero,
      bairro: bairro ?? state.bairro,
      cidade: cidade ?? state.cidade,
      estado: estado ?? state.estado,
      selectedLat: lat ?? state.selectedLat,
      selectedLng: lng ?? state.selectedLng,
    );
    _scheduleSave();
  }

  void updateResolvedAddress(ResolvedAddress address) {
    updateAddress(
      cep: address.cep,
      logradouro: address.logradouro,
      numero: address.numero,
      bairro: address.bairro,
      cidade: address.cidade,
      estado: address.estado,
      lat: address.lat,
      lng: address.lng,
    );
  }
}

final onboardingFormProvider =
    NotifierProvider<OnboardingFormNotifier, OnboardingFormState>(
      OnboardingFormNotifier.new,
    );
