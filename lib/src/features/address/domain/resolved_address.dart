import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../settings/domain/saved_address.dart';

@immutable
class ResolvedAddress {
  const ResolvedAddress({
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
    required this.lat,
    required this.lng,
  });

  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final double? lat;
  final double? lng;

  factory ResolvedAddress.empty() {
    return const ResolvedAddress(
      logradouro: '',
      numero: '',
      bairro: '',
      cidade: '',
      estado: '',
      cep: '',
      lat: null,
      lng: null,
    );
  }

  factory ResolvedAddress.fromSavedAddress(SavedAddress address) {
    return ResolvedAddress(
      logradouro: address.logradouro,
      numero: address.numero,
      bairro: address.bairro,
      cidade: address.cidade,
      estado: address.estado,
      cep: address.cep,
      lat: address.lat,
      lng: address.lng,
    );
  }

  factory ResolvedAddress.fromLocationMap(Map<String, dynamic> map) {
    return ResolvedAddress(
      logradouro: (map['logradouro'] ?? '').toString().trim(),
      numero: (map['numero'] ?? '').toString().trim(),
      bairro: (map['bairro'] ?? '').toString().trim(),
      cidade: (map['cidade'] ?? '').toString().trim(),
      estado: (map['estado'] ?? '').toString().trim(),
      cep: (map['cep'] ?? '').toString().trim(),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: ((map['lng'] ?? map['long']) as num?)?.toDouble(),
    );
  }

  bool get hasCoordinates => lat != null && lng != null;

  bool get hasRequiredMetadata =>
      logradouro.trim().isNotEmpty &&
      cidade.trim().isNotEmpty &&
      estado.trim().isNotEmpty;

  bool get canConfirm =>
      numero.trim().isNotEmpty && hasCoordinates && hasRequiredMetadata;

  String? get confirmBlockingReason {
    if (!hasCoordinates) {
      return 'Endereco sem coordenadas validas. Tente outro resultado.';
    }
    if (logradouro.trim().isEmpty) {
      return 'Nao foi possivel determinar a rua desse endereco.';
    }
    if (cidade.trim().isEmpty || estado.trim().isEmpty) {
      return 'Nao foi possivel determinar cidade e estado desse endereco.';
    }
    if (numero.trim().isEmpty) {
      return 'Informe o numero para continuar.';
    }
    return null;
  }

  String get titleLine {
    final parts = <String>[
      logradouro.trim(),
      numero.trim(),
    ].where((value) => value.isNotEmpty).toList();
    return parts.join(', ');
  }

  String get subtitleLine {
    final cityState = [
      cidade.trim(),
      estado.trim(),
    ].where((value) => value.isNotEmpty).join(' - ');

    final parts = <String>[
      bairro.trim(),
      cityState,
    ].where((value) => value.isNotEmpty).toList();

    return parts.join(', ');
  }

  String get fullDisplay {
    final parts = <String>[
      titleLine,
      subtitleLine,
      cep.trim().isNotEmpty ? 'CEP: ${cep.trim()}' : '',
    ].where((value) => value.isNotEmpty).toList();
    return parts.join(' • ');
  }

  ResolvedAddress copyWith({
    String? logradouro,
    String? numero,
    String? bairro,
    String? cidade,
    String? estado,
    String? cep,
    double? lat,
    double? lng,
    bool clearLat = false,
    bool clearLng = false,
  }) {
    return ResolvedAddress(
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      cep: cep ?? this.cep,
      lat: clearLat ? null : (lat ?? this.lat),
      lng: clearLng ? null : (lng ?? this.lng),
    );
  }

  SavedAddress toSavedAddress({
    String? id,
    String nome = '',
    bool isPrimary = false,
    DateTime? createdAt,
  }) {
    return SavedAddress(
      id: id ?? const Uuid().v4(),
      nome: nome,
      logradouro: logradouro.trim(),
      numero: numero.trim(),
      bairro: bairro.trim(),
      cidade: cidade.trim(),
      estado: estado.trim(),
      cep: cep.trim(),
      lat: lat,
      lng: lng,
      isPrimary: isPrimary,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toLocationMap() {
    return {
      'logradouro': logradouro.trim(),
      'numero': numero.trim(),
      'bairro': bairro.trim(),
      'cidade': cidade.trim(),
      'estado': estado.trim(),
      'cep': cep.trim(),
      'lat': lat,
      'lng': lng,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResolvedAddress &&
        other.logradouro == logradouro &&
        other.numero == numero &&
        other.bairro == bairro &&
        other.cidade == cidade &&
        other.estado == estado &&
        other.cep == cep &&
        other.lat == lat &&
        other.lng == lng;
  }

  @override
  int get hashCode => Object.hash(
    logradouro,
    numero,
    bairro,
    cidade,
    estado,
    cep,
    lat,
    lng,
  );
}
