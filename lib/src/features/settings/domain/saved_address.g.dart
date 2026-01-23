// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedAddress _$SavedAddressFromJson(Map<String, dynamic> json) =>
    _SavedAddress(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      logradouro: json['logradouro'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      bairro: json['bairro'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      cep: json['cep'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isPrimary: json['isPrimary'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SavedAddressToJson(_SavedAddress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'logradouro': instance.logradouro,
      'numero': instance.numero,
      'bairro': instance.bairro,
      'cidade': instance.cidade,
      'estado': instance.estado,
      'cep': instance.cep,
      'lat': instance.lat,
      'lng': instance.lng,
      'isPrimary': instance.isPrimary,
      'created_at': instance.createdAt?.toIso8601String(),
    };
