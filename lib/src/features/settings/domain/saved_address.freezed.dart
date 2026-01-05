// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_address.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedAddress {

/// Unique identifier for this address.
 String get id;/// User-defined label (e.g., "Casa", "Trabalho").
 String get nome;/// Street name.
 String get logradouro;/// Street number.
 String get numero;/// Neighborhood.
 String get bairro;/// City name.
 String get cidade;/// State abbreviation (e.g., "SP").
 String get estado;/// Postal code.
 String get cep;/// Latitude coordinate.
 double? get lat;/// Longitude coordinate.
@JsonKey(name: 'long') double? get lng;/// Whether this is the primary/active address.
 bool get isPrimary;/// Creation timestamp.
@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of SavedAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedAddressCopyWith<SavedAddress> get copyWith => _$SavedAddressCopyWithImpl<SavedAddress>(this as SavedAddress, _$identity);

  /// Serializes this SavedAddress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedAddress&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.logradouro, logradouro) || other.logradouro == logradouro)&&(identical(other.numero, numero) || other.numero == numero)&&(identical(other.bairro, bairro) || other.bairro == bairro)&&(identical(other.cidade, cidade) || other.cidade == cidade)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.cep, cep) || other.cep == cep)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nome,logradouro,numero,bairro,cidade,estado,cep,lat,lng,isPrimary,createdAt);

@override
String toString() {
  return 'SavedAddress(id: $id, nome: $nome, logradouro: $logradouro, numero: $numero, bairro: $bairro, cidade: $cidade, estado: $estado, cep: $cep, lat: $lat, lng: $lng, isPrimary: $isPrimary, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SavedAddressCopyWith<$Res>  {
  factory $SavedAddressCopyWith(SavedAddress value, $Res Function(SavedAddress) _then) = _$SavedAddressCopyWithImpl;
@useResult
$Res call({
 String id, String nome, String logradouro, String numero, String bairro, String cidade, String estado, String cep, double? lat,@JsonKey(name: 'long') double? lng, bool isPrimary,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$SavedAddressCopyWithImpl<$Res>
    implements $SavedAddressCopyWith<$Res> {
  _$SavedAddressCopyWithImpl(this._self, this._then);

  final SavedAddress _self;
  final $Res Function(SavedAddress) _then;

/// Create a copy of SavedAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nome = null,Object? logradouro = null,Object? numero = null,Object? bairro = null,Object? cidade = null,Object? estado = null,Object? cep = null,Object? lat = freezed,Object? lng = freezed,Object? isPrimary = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,logradouro: null == logradouro ? _self.logradouro : logradouro // ignore: cast_nullable_to_non_nullable
as String,numero: null == numero ? _self.numero : numero // ignore: cast_nullable_to_non_nullable
as String,bairro: null == bairro ? _self.bairro : bairro // ignore: cast_nullable_to_non_nullable
as String,cidade: null == cidade ? _self.cidade : cidade // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,cep: null == cep ? _self.cep : cep // ignore: cast_nullable_to_non_nullable
as String,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedAddress].
extension SavedAddressPatterns on SavedAddress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedAddress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedAddress value)  $default,){
final _that = this;
switch (_that) {
case _SavedAddress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedAddress value)?  $default,){
final _that = this;
switch (_that) {
case _SavedAddress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nome,  String logradouro,  String numero,  String bairro,  String cidade,  String estado,  String cep,  double? lat, @JsonKey(name: 'long')  double? lng,  bool isPrimary, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedAddress() when $default != null:
return $default(_that.id,_that.nome,_that.logradouro,_that.numero,_that.bairro,_that.cidade,_that.estado,_that.cep,_that.lat,_that.lng,_that.isPrimary,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nome,  String logradouro,  String numero,  String bairro,  String cidade,  String estado,  String cep,  double? lat, @JsonKey(name: 'long')  double? lng,  bool isPrimary, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SavedAddress():
return $default(_that.id,_that.nome,_that.logradouro,_that.numero,_that.bairro,_that.cidade,_that.estado,_that.cep,_that.lat,_that.lng,_that.isPrimary,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nome,  String logradouro,  String numero,  String bairro,  String cidade,  String estado,  String cep,  double? lat, @JsonKey(name: 'long')  double? lng,  bool isPrimary, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SavedAddress() when $default != null:
return $default(_that.id,_that.nome,_that.logradouro,_that.numero,_that.bairro,_that.cidade,_that.estado,_that.cep,_that.lat,_that.lng,_that.isPrimary,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedAddress extends SavedAddress {
  const _SavedAddress({required this.id, this.nome = '', this.logradouro = '', this.numero = '', this.bairro = '', this.cidade = '', this.estado = '', this.cep = '', this.lat, @JsonKey(name: 'long') this.lng, this.isPrimary = false, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _SavedAddress.fromJson(Map<String, dynamic> json) => _$SavedAddressFromJson(json);

/// Unique identifier for this address.
@override final  String id;
/// User-defined label (e.g., "Casa", "Trabalho").
@override@JsonKey() final  String nome;
/// Street name.
@override@JsonKey() final  String logradouro;
/// Street number.
@override@JsonKey() final  String numero;
/// Neighborhood.
@override@JsonKey() final  String bairro;
/// City name.
@override@JsonKey() final  String cidade;
/// State abbreviation (e.g., "SP").
@override@JsonKey() final  String estado;
/// Postal code.
@override@JsonKey() final  String cep;
/// Latitude coordinate.
@override final  double? lat;
/// Longitude coordinate.
@override@JsonKey(name: 'long') final  double? lng;
/// Whether this is the primary/active address.
@override@JsonKey() final  bool isPrimary;
/// Creation timestamp.
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of SavedAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedAddressCopyWith<_SavedAddress> get copyWith => __$SavedAddressCopyWithImpl<_SavedAddress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedAddressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedAddress&&(identical(other.id, id) || other.id == id)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.logradouro, logradouro) || other.logradouro == logradouro)&&(identical(other.numero, numero) || other.numero == numero)&&(identical(other.bairro, bairro) || other.bairro == bairro)&&(identical(other.cidade, cidade) || other.cidade == cidade)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.cep, cep) || other.cep == cep)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nome,logradouro,numero,bairro,cidade,estado,cep,lat,lng,isPrimary,createdAt);

@override
String toString() {
  return 'SavedAddress(id: $id, nome: $nome, logradouro: $logradouro, numero: $numero, bairro: $bairro, cidade: $cidade, estado: $estado, cep: $cep, lat: $lat, lng: $lng, isPrimary: $isPrimary, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SavedAddressCopyWith<$Res> implements $SavedAddressCopyWith<$Res> {
  factory _$SavedAddressCopyWith(_SavedAddress value, $Res Function(_SavedAddress) _then) = __$SavedAddressCopyWithImpl;
@override @useResult
$Res call({
 String id, String nome, String logradouro, String numero, String bairro, String cidade, String estado, String cep, double? lat,@JsonKey(name: 'long') double? lng, bool isPrimary,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$SavedAddressCopyWithImpl<$Res>
    implements _$SavedAddressCopyWith<$Res> {
  __$SavedAddressCopyWithImpl(this._self, this._then);

  final _SavedAddress _self;
  final $Res Function(_SavedAddress) _then;

/// Create a copy of SavedAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nome = null,Object? logradouro = null,Object? numero = null,Object? bairro = null,Object? cidade = null,Object? estado = null,Object? cep = null,Object? lat = freezed,Object? lng = freezed,Object? isPrimary = null,Object? createdAt = freezed,}) {
  return _then(_SavedAddress(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,logradouro: null == logradouro ? _self.logradouro : logradouro // ignore: cast_nullable_to_non_nullable
as String,numero: null == numero ? _self.numero : numero // ignore: cast_nullable_to_non_nullable
as String,bairro: null == bairro ? _self.bairro : bairro // ignore: cast_nullable_to_non_nullable
as String,cidade: null == cidade ? _self.cidade : cidade // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,cep: null == cep ? _self.cep : cep // ignore: cast_nullable_to_non_nullable
as String,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
