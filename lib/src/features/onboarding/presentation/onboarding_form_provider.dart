import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common_widgets/location_service.dart';

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
  final String? initialLocationLabel; // Cached preview label

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
}

class OnboardingFormNotifier extends Notifier<OnboardingFormState> {
  static const _storageKey = 'onboarding_form_state';
  static const _persistDebounce = Duration(milliseconds: 350);
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
    final instance = await SharedPreferences.getInstance();
    _prefs = instance;
    return instance;
  }

  Future<void> _loadState() async {
    final prefs = await _getPrefs();
    if (!ref.mounted) return;
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        state = OnboardingFormState.fromJson(jsonStr);
      } catch (e, st) {
        AppLogger.warning('Falha ao restaurar estado do onboarding', e, st);
      }
    }
  }

  Future<void> _saveState() async {
    final prefs = await _getPrefs();
    if (!ref.mounted) return;
    await prefs.setString(_storageKey, state.toJson());
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

  // Fetch initial location preview if not already set
  Future<void> fetchInitialLocation() async {
    // If we already have a full address selected, we don't need a vague preview
    if (state.logradouro != null && state.logradouro!.isNotEmpty) return;

    // If not, try to get current location
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final details = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (details != null) {
          final parts = <String>[
            (details['logradouro'] ?? '').toString(),
            (details['bairro'] ?? '').toString(),
            (details['cidade'] ?? '').toString(),
          ].where((value) => value.trim().isNotEmpty).toList();
          final label = parts.isEmpty ? 'Localizacao atual' : parts.join(' - ');
          state = state.copyWith(initialLocationLabel: label);
          // We don't necessarily save this to disk as it's transient/ephemeral
        }
      }
    } catch (e, st) {
      AppLogger.warning(
        'Falha ao buscar localização inicial no onboarding',
        e,
        st,
      );
    }
  }

  void updateNome(String val) {
    if (state.nome == val) return;
    state = state.copyWith(nome: val);
    _scheduleSave();
  }

  void updateNomeArtistico(String val) {
    if (state.nomeArtistico == val) return;
    state = state.copyWith(nomeArtistico: val);
    _scheduleSave();
  }

  void updateCelular(String val) {
    if (state.celular == val) return;
    state = state.copyWith(celular: val);
    _scheduleSave();
  }

  void updateDataNascimento(String val) {
    if (state.dataNascimento == val) return;
    state = state.copyWith(dataNascimento: val);
    _scheduleSave();
  }

  void updateGenero(String val) {
    if (state.genero == val) return;
    state = state.copyWith(genero: val);
    _scheduleSave();
  }

  void updateInstagram(String val) {
    if (state.instagram == val) return;
    state = state.copyWith(instagram: val);
    _scheduleSave();
  }

  void updateCategories(List<String> val) => updateSelectedCategories(val);
  void updateGenres(List<String> val) => updateSelectedGenres(val);
  void updateInstruments(List<String> val) => updateSelectedInstruments(val);
  void updateRoles(List<String> val) => updateSelectedRoles(val);
  void updateServices(List<String> val) => updateSelectedServices(val);

  void updateSelectedCategories(List<String> val) {
    state = state.copyWith(selectedCategories: val);
    _scheduleSave();
  }

  void updateSelectedGenres(List<String> val) {
    state = state.copyWith(selectedGenres: val);
    _scheduleSave();
  }

  void updateSelectedInstruments(List<String> val) {
    state = state.copyWith(selectedInstruments: val);
    _scheduleSave();
  }

  void updateSelectedRoles(List<String> val) {
    state = state.copyWith(selectedRoles: val);
    _scheduleSave();
  }

  void updateBackingVocalMode(String val) {
    if (state.backingVocalMode == val) return;
    state = state.copyWith(backingVocalMode: val);
    _scheduleSave();
  }

  void updateInstrumentalistBackingVocal(bool val) {
    if (state.instrumentalistBackingVocal == val) return;
    state = state.copyWith(instrumentalistBackingVocal: val);
    _scheduleSave();
  }

  // Studio
  void updateStudioType(String val) {
    if (state.studioType == val) return;
    state = state.copyWith(studioType: val);
    _scheduleSave();
  }

  void updateSelectedServices(List<String> val) {
    state = state.copyWith(selectedServices: val);
    _scheduleSave();
  }

  // Address
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
}

final onboardingFormProvider =
    NotifierProvider<OnboardingFormNotifier, OnboardingFormState>(
      OnboardingFormNotifier.new,
    );
