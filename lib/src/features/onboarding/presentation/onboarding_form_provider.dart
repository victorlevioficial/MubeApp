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
  final _locationService = LocationService();

  @override
  OnboardingFormState build() {
    _loadState();
    return const OnboardingFormState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      state = OnboardingFormState.fromJson(jsonStr);
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, state.toJson());
  }

  Future<void> clearState() async {
    state = const OnboardingFormState();
    final prefs = await SharedPreferences.getInstance();
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
          final label =
              '${details['logradouro']} - ${details['bairro']} - ${details['cidade']}';
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
    state = state.copyWith(nome: val);
    _saveState();
  }

  void updateNomeArtistico(String val) {
    state = state.copyWith(nomeArtistico: val);
    _saveState();
  }

  void updateCelular(String val) {
    state = state.copyWith(celular: val);
    _saveState();
  }

  void updateDataNascimento(String val) {
    state = state.copyWith(dataNascimento: val);
    _saveState();
  }

  void updateGenero(String val) {
    state = state.copyWith(genero: val);
    _saveState();
  }

  void updateInstagram(String val) {
    state = state.copyWith(instagram: val);
    _saveState();
  }

  void updateCategories(List<String> val) => updateSelectedCategories(val);
  void updateGenres(List<String> val) => updateSelectedGenres(val);
  void updateInstruments(List<String> val) => updateSelectedInstruments(val);
  void updateRoles(List<String> val) => updateSelectedRoles(val);
  void updateServices(List<String> val) => updateSelectedServices(val);

  void updateSelectedCategories(List<String> val) {
    state = state.copyWith(selectedCategories: val);
    _saveState();
  }

  void updateSelectedGenres(List<String> val) {
    state = state.copyWith(selectedGenres: val);
    _saveState();
  }

  void updateSelectedInstruments(List<String> val) {
    state = state.copyWith(selectedInstruments: val);
    _saveState();
  }

  void updateSelectedRoles(List<String> val) {
    state = state.copyWith(selectedRoles: val);
    _saveState();
  }

  void updateBackingVocalMode(String val) {
    state = state.copyWith(backingVocalMode: val);
    _saveState();
  }

  void updateInstrumentalistBackingVocal(bool val) {
    state = state.copyWith(instrumentalistBackingVocal: val);
    _saveState();
  }

  // Studio
  void updateStudioType(String val) {
    state = state.copyWith(studioType: val);
    _saveState();
  }

  void updateSelectedServices(List<String> val) {
    state = state.copyWith(selectedServices: val);
    _saveState();
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
    _saveState();
  }
}

final onboardingFormProvider =
    NotifierProvider<OnboardingFormNotifier, OnboardingFormState>(
      OnboardingFormNotifier.new,
    );


