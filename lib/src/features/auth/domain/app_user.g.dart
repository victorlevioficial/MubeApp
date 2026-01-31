// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  uid: json['uid'] as String,
  email: json['email'] as String,
  cadastroStatus: json['cadastro_status'] as String? ?? 'tipo_pendente',
  tipoPerfil: $enumDecodeNullable(_$AppUserTypeEnumMap, json['tipo_perfil']),
  status: json['status'] as String? ?? 'ativo',
  nome: json['nome'] as String?,
  foto: json['foto'] as String?,
  bio: json['bio'] as String?,
  location: json['location'] as Map<String, dynamic>?,
  geohash: json['geohash'] as String?,
  addresses:
      (json['addresses'] as List<dynamic>?)
          ?.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  dadosProfissional: json['profissional'] as Map<String, dynamic>?,
  dadosBanda: json['banda'] as Map<String, dynamic>?,
  dadosEstudio: json['estudio'] as Map<String, dynamic>?,
  dadosContratante: json['contratante'] as Map<String, dynamic>?,
  plan: json['plan'] as String? ?? 'free',
  favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
  members:
      (json['members'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: json['created_at'],
  blockedUsers:
      (json['blocked_users'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  privacySettings:
      json['privacy_settings'] as Map<String, dynamic>? ?? const {},
  matchpointProfile: json['matchpoint_profile'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'cadastro_status': instance.cadastroStatus,
  'tipo_perfil': _$AppUserTypeEnumMap[instance.tipoPerfil],
  'status': instance.status,
  'nome': instance.nome,
  'foto': instance.foto,
  'bio': instance.bio,
  'location': instance.location,
  'geohash': instance.geohash,
  'addresses': instance.addresses,
  'profissional': instance.dadosProfissional,
  'banda': instance.dadosBanda,
  'estudio': instance.dadosEstudio,
  'contratante': instance.dadosContratante,
  'plan': instance.plan,
  'favorites_count': instance.favoritesCount,
  'members': instance.members,
  'created_at': instance.createdAt,
  'blocked_users': instance.blockedUsers,
  'privacy_settings': instance.privacySettings,
  'matchpoint_profile': instance.matchpointProfile,
};

const _$AppUserTypeEnumMap = {
  AppUserType.professional: 'profissional',
  AppUserType.studio: 'estudio',
  AppUserType.band: 'banda',
  AppUserType.contractor: 'contratante',
};
