// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUser {

 String get uid; String get email;// Status do Cadastro (Controla o fluxo de Onboarding)
// Valores: 'tipo_pendente', 'perfil_pendente', 'concluido'
@JsonKey(name: 'cadastro_status') String get cadastroStatus;// Tipo de Perfil (Só preenchido após seleção)
@JsonKey(name: 'tipo_perfil') AppUserType? get tipoPerfil;// Status do Perfil (Visibilidade)
 String get status;// Dados Comuns / Específicos Mapeados
 String? get nome; String? get foto; String? get bio;// Localização (Obrigatório para todos)
// Armazenado como Map: { 'cidade': '...', 'estado': '...', 'lat': 0.0, 'long': 0.0 }
 Map<String, dynamic>? get location;// Dados Específicos (achatados ou em maps, conforme Spec diz "Maps Tipados" no security rules)
// Para simplificar e manter compatibilidade com Security Rules:
@JsonKey(name: 'profissional') Map<String, dynamic>? get dadosProfissional;@JsonKey(name: 'banda') Map<String, dynamic>? get dadosBanda;@JsonKey(name: 'estudio') Map<String, dynamic>? get dadosEstudio;@JsonKey(name: 'contratante') Map<String, dynamic>? get dadosContratante;// Metadata
@JsonKey(name: 'created_at') dynamic get createdAt;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.cadastroStatus, cadastroStatus) || other.cadastroStatus == cadastroStatus)&&(identical(other.tipoPerfil, tipoPerfil) || other.tipoPerfil == tipoPerfil)&&(identical(other.status, status) || other.status == status)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.foto, foto) || other.foto == foto)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other.location, location)&&const DeepCollectionEquality().equals(other.dadosProfissional, dadosProfissional)&&const DeepCollectionEquality().equals(other.dadosBanda, dadosBanda)&&const DeepCollectionEquality().equals(other.dadosEstudio, dadosEstudio)&&const DeepCollectionEquality().equals(other.dadosContratante, dadosContratante)&&const DeepCollectionEquality().equals(other.createdAt, createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,email,cadastroStatus,tipoPerfil,status,nome,foto,bio,const DeepCollectionEquality().hash(location),const DeepCollectionEquality().hash(dadosProfissional),const DeepCollectionEquality().hash(dadosBanda),const DeepCollectionEquality().hash(dadosEstudio),const DeepCollectionEquality().hash(dadosContratante),const DeepCollectionEquality().hash(createdAt));

@override
String toString() {
  return 'AppUser(uid: $uid, email: $email, cadastroStatus: $cadastroStatus, tipoPerfil: $tipoPerfil, status: $status, nome: $nome, foto: $foto, bio: $bio, location: $location, dadosProfissional: $dadosProfissional, dadosBanda: $dadosBanda, dadosEstudio: $dadosEstudio, dadosContratante: $dadosContratante, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String uid, String email,@JsonKey(name: 'cadastro_status') String cadastroStatus,@JsonKey(name: 'tipo_perfil') AppUserType? tipoPerfil, String status, String? nome, String? foto, String? bio, Map<String, dynamic>? location,@JsonKey(name: 'profissional') Map<String, dynamic>? dadosProfissional,@JsonKey(name: 'banda') Map<String, dynamic>? dadosBanda,@JsonKey(name: 'estudio') Map<String, dynamic>? dadosEstudio,@JsonKey(name: 'contratante') Map<String, dynamic>? dadosContratante,@JsonKey(name: 'created_at') dynamic createdAt
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? email = null,Object? cadastroStatus = null,Object? tipoPerfil = freezed,Object? status = null,Object? nome = freezed,Object? foto = freezed,Object? bio = freezed,Object? location = freezed,Object? dadosProfissional = freezed,Object? dadosBanda = freezed,Object? dadosEstudio = freezed,Object? dadosContratante = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,cadastroStatus: null == cadastroStatus ? _self.cadastroStatus : cadastroStatus // ignore: cast_nullable_to_non_nullable
as String,tipoPerfil: freezed == tipoPerfil ? _self.tipoPerfil : tipoPerfil // ignore: cast_nullable_to_non_nullable
as AppUserType?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,nome: freezed == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String?,foto: freezed == foto ? _self.foto : foto // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,dadosProfissional: freezed == dadosProfissional ? _self.dadosProfissional : dadosProfissional // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,dadosBanda: freezed == dadosBanda ? _self.dadosBanda : dadosBanda // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,dadosEstudio: freezed == dadosEstudio ? _self.dadosEstudio : dadosEstudio // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,dadosContratante: freezed == dadosContratante ? _self.dadosContratante : dadosContratante // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String email, @JsonKey(name: 'cadastro_status')  String cadastroStatus, @JsonKey(name: 'tipo_perfil')  AppUserType? tipoPerfil,  String status,  String? nome,  String? foto,  String? bio,  Map<String, dynamic>? location, @JsonKey(name: 'profissional')  Map<String, dynamic>? dadosProfissional, @JsonKey(name: 'banda')  Map<String, dynamic>? dadosBanda, @JsonKey(name: 'estudio')  Map<String, dynamic>? dadosEstudio, @JsonKey(name: 'contratante')  Map<String, dynamic>? dadosContratante, @JsonKey(name: 'created_at')  dynamic createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.email,_that.cadastroStatus,_that.tipoPerfil,_that.status,_that.nome,_that.foto,_that.bio,_that.location,_that.dadosProfissional,_that.dadosBanda,_that.dadosEstudio,_that.dadosContratante,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String email, @JsonKey(name: 'cadastro_status')  String cadastroStatus, @JsonKey(name: 'tipo_perfil')  AppUserType? tipoPerfil,  String status,  String? nome,  String? foto,  String? bio,  Map<String, dynamic>? location, @JsonKey(name: 'profissional')  Map<String, dynamic>? dadosProfissional, @JsonKey(name: 'banda')  Map<String, dynamic>? dadosBanda, @JsonKey(name: 'estudio')  Map<String, dynamic>? dadosEstudio, @JsonKey(name: 'contratante')  Map<String, dynamic>? dadosContratante, @JsonKey(name: 'created_at')  dynamic createdAt)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.uid,_that.email,_that.cadastroStatus,_that.tipoPerfil,_that.status,_that.nome,_that.foto,_that.bio,_that.location,_that.dadosProfissional,_that.dadosBanda,_that.dadosEstudio,_that.dadosContratante,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String email, @JsonKey(name: 'cadastro_status')  String cadastroStatus, @JsonKey(name: 'tipo_perfil')  AppUserType? tipoPerfil,  String status,  String? nome,  String? foto,  String? bio,  Map<String, dynamic>? location, @JsonKey(name: 'profissional')  Map<String, dynamic>? dadosProfissional, @JsonKey(name: 'banda')  Map<String, dynamic>? dadosBanda, @JsonKey(name: 'estudio')  Map<String, dynamic>? dadosEstudio, @JsonKey(name: 'contratante')  Map<String, dynamic>? dadosContratante, @JsonKey(name: 'created_at')  dynamic createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.email,_that.cadastroStatus,_that.tipoPerfil,_that.status,_that.nome,_that.foto,_that.bio,_that.location,_that.dadosProfissional,_that.dadosBanda,_that.dadosEstudio,_that.dadosContratante,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppUser extends AppUser {
  const _AppUser({required this.uid, required this.email, @JsonKey(name: 'cadastro_status') this.cadastroStatus = 'tipo_pendente', @JsonKey(name: 'tipo_perfil') this.tipoPerfil, this.status = 'ativo', this.nome, this.foto, this.bio, final  Map<String, dynamic>? location, @JsonKey(name: 'profissional') final  Map<String, dynamic>? dadosProfissional, @JsonKey(name: 'banda') final  Map<String, dynamic>? dadosBanda, @JsonKey(name: 'estudio') final  Map<String, dynamic>? dadosEstudio, @JsonKey(name: 'contratante') final  Map<String, dynamic>? dadosContratante, @JsonKey(name: 'created_at') this.createdAt}): _location = location,_dadosProfissional = dadosProfissional,_dadosBanda = dadosBanda,_dadosEstudio = dadosEstudio,_dadosContratante = dadosContratante,super._();
  factory _AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

@override final  String uid;
@override final  String email;
// Status do Cadastro (Controla o fluxo de Onboarding)
// Valores: 'tipo_pendente', 'perfil_pendente', 'concluido'
@override@JsonKey(name: 'cadastro_status') final  String cadastroStatus;
// Tipo de Perfil (Só preenchido após seleção)
@override@JsonKey(name: 'tipo_perfil') final  AppUserType? tipoPerfil;
// Status do Perfil (Visibilidade)
@override@JsonKey() final  String status;
// Dados Comuns / Específicos Mapeados
@override final  String? nome;
@override final  String? foto;
@override final  String? bio;
// Localização (Obrigatório para todos)
// Armazenado como Map: { 'cidade': '...', 'estado': '...', 'lat': 0.0, 'long': 0.0 }
 final  Map<String, dynamic>? _location;
// Localização (Obrigatório para todos)
// Armazenado como Map: { 'cidade': '...', 'estado': '...', 'lat': 0.0, 'long': 0.0 }
@override Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// Dados Específicos (achatados ou em maps, conforme Spec diz "Maps Tipados" no security rules)
// Para simplificar e manter compatibilidade com Security Rules:
 final  Map<String, dynamic>? _dadosProfissional;
// Dados Específicos (achatados ou em maps, conforme Spec diz "Maps Tipados" no security rules)
// Para simplificar e manter compatibilidade com Security Rules:
@override@JsonKey(name: 'profissional') Map<String, dynamic>? get dadosProfissional {
  final value = _dadosProfissional;
  if (value == null) return null;
  if (_dadosProfissional is EqualUnmodifiableMapView) return _dadosProfissional;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _dadosBanda;
@override@JsonKey(name: 'banda') Map<String, dynamic>? get dadosBanda {
  final value = _dadosBanda;
  if (value == null) return null;
  if (_dadosBanda is EqualUnmodifiableMapView) return _dadosBanda;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _dadosEstudio;
@override@JsonKey(name: 'estudio') Map<String, dynamic>? get dadosEstudio {
  final value = _dadosEstudio;
  if (value == null) return null;
  if (_dadosEstudio is EqualUnmodifiableMapView) return _dadosEstudio;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _dadosContratante;
@override@JsonKey(name: 'contratante') Map<String, dynamic>? get dadosContratante {
  final value = _dadosContratante;
  if (value == null) return null;
  if (_dadosContratante is EqualUnmodifiableMapView) return _dadosContratante;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// Metadata
@override@JsonKey(name: 'created_at') final  dynamic createdAt;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.cadastroStatus, cadastroStatus) || other.cadastroStatus == cadastroStatus)&&(identical(other.tipoPerfil, tipoPerfil) || other.tipoPerfil == tipoPerfil)&&(identical(other.status, status) || other.status == status)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.foto, foto) || other.foto == foto)&&(identical(other.bio, bio) || other.bio == bio)&&const DeepCollectionEquality().equals(other._location, _location)&&const DeepCollectionEquality().equals(other._dadosProfissional, _dadosProfissional)&&const DeepCollectionEquality().equals(other._dadosBanda, _dadosBanda)&&const DeepCollectionEquality().equals(other._dadosEstudio, _dadosEstudio)&&const DeepCollectionEquality().equals(other._dadosContratante, _dadosContratante)&&const DeepCollectionEquality().equals(other.createdAt, createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,email,cadastroStatus,tipoPerfil,status,nome,foto,bio,const DeepCollectionEquality().hash(_location),const DeepCollectionEquality().hash(_dadosProfissional),const DeepCollectionEquality().hash(_dadosBanda),const DeepCollectionEquality().hash(_dadosEstudio),const DeepCollectionEquality().hash(_dadosContratante),const DeepCollectionEquality().hash(createdAt));

@override
String toString() {
  return 'AppUser(uid: $uid, email: $email, cadastroStatus: $cadastroStatus, tipoPerfil: $tipoPerfil, status: $status, nome: $nome, foto: $foto, bio: $bio, location: $location, dadosProfissional: $dadosProfissional, dadosBanda: $dadosBanda, dadosEstudio: $dadosEstudio, dadosContratante: $dadosContratante, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String uid, String email,@JsonKey(name: 'cadastro_status') String cadastroStatus,@JsonKey(name: 'tipo_perfil') AppUserType? tipoPerfil, String status, String? nome, String? foto, String? bio, Map<String, dynamic>? location,@JsonKey(name: 'profissional') Map<String, dynamic>? dadosProfissional,@JsonKey(name: 'banda') Map<String, dynamic>? dadosBanda,@JsonKey(name: 'estudio') Map<String, dynamic>? dadosEstudio,@JsonKey(name: 'contratante') Map<String, dynamic>? dadosContratante,@JsonKey(name: 'created_at') dynamic createdAt
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? email = null,Object? cadastroStatus = null,Object? tipoPerfil = freezed,Object? status = null,Object? nome = freezed,Object? foto = freezed,Object? bio = freezed,Object? location = freezed,Object? dadosProfissional = freezed,Object? dadosBanda = freezed,Object? dadosEstudio = freezed,Object? dadosContratante = freezed,Object? createdAt = freezed,}) {
  return _then(_AppUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,cadastroStatus: null == cadastroStatus ? _self.cadastroStatus : cadastroStatus // ignore: cast_nullable_to_non_nullable
as String,tipoPerfil: freezed == tipoPerfil ? _self.tipoPerfil : tipoPerfil // ignore: cast_nullable_to_non_nullable
as AppUserType?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,nome: freezed == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String?,foto: freezed == foto ? _self.foto : foto // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,dadosProfissional: freezed == dadosProfissional ? _self._dadosProfissional : dadosProfissional // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,dadosBanda: freezed == dadosBanda ? _self._dadosBanda : dadosBanda // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,dadosEstudio: freezed == dadosEstudio ? _self._dadosEstudio : dadosEstudio // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,dadosContratante: freezed == dadosContratante ? _self._dadosContratante : dadosContratante // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
