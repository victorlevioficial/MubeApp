// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedItem {

 String get uid; String get nome; String? get nomeArtistico; String? get foto; String? get categoria; List<String> get generosMusicais; String get tipoPerfil; Map<String, dynamic>? get location; int get likeCount; List<String> get skills; List<String> get subCategories;// @Default(false) bool isFavorited, // Removed
 double? get distanceKm;
/// Create a copy of FeedItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedItemCopyWith<FeedItem> get copyWith => _$FeedItemCopyWithImpl<FeedItem>(this as FeedItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedItem&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.nomeArtistico, nomeArtistico) || other.nomeArtistico == nomeArtistico)&&(identical(other.foto, foto) || other.foto == foto)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&const DeepCollectionEquality().equals(other.generosMusicais, generosMusicais)&&(identical(other.tipoPerfil, tipoPerfil) || other.tipoPerfil == tipoPerfil)&&const DeepCollectionEquality().equals(other.location, location)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&const DeepCollectionEquality().equals(other.skills, skills)&&const DeepCollectionEquality().equals(other.subCategories, subCategories)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm));
}


@override
int get hashCode => Object.hash(runtimeType,uid,nome,nomeArtistico,foto,categoria,const DeepCollectionEquality().hash(generosMusicais),tipoPerfil,const DeepCollectionEquality().hash(location),likeCount,const DeepCollectionEquality().hash(skills),const DeepCollectionEquality().hash(subCategories),distanceKm);

@override
String toString() {
  return 'FeedItem(uid: $uid, nome: $nome, nomeArtistico: $nomeArtistico, foto: $foto, categoria: $categoria, generosMusicais: $generosMusicais, tipoPerfil: $tipoPerfil, location: $location, likeCount: $likeCount, skills: $skills, subCategories: $subCategories, distanceKm: $distanceKm)';
}


}

/// @nodoc
abstract mixin class $FeedItemCopyWith<$Res>  {
  factory $FeedItemCopyWith(FeedItem value, $Res Function(FeedItem) _then) = _$FeedItemCopyWithImpl;
@useResult
$Res call({
 String uid, String nome, String? nomeArtistico, String? foto, String? categoria, List<String> generosMusicais, String tipoPerfil, Map<String, dynamic>? location, int likeCount, List<String> skills, List<String> subCategories, double? distanceKm
});




}
/// @nodoc
class _$FeedItemCopyWithImpl<$Res>
    implements $FeedItemCopyWith<$Res> {
  _$FeedItemCopyWithImpl(this._self, this._then);

  final FeedItem _self;
  final $Res Function(FeedItem) _then;

/// Create a copy of FeedItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? nome = null,Object? nomeArtistico = freezed,Object? foto = freezed,Object? categoria = freezed,Object? generosMusicais = null,Object? tipoPerfil = null,Object? location = freezed,Object? likeCount = null,Object? skills = null,Object? subCategories = null,Object? distanceKm = freezed,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,nomeArtistico: freezed == nomeArtistico ? _self.nomeArtistico : nomeArtistico // ignore: cast_nullable_to_non_nullable
as String?,foto: freezed == foto ? _self.foto : foto // ignore: cast_nullable_to_non_nullable
as String?,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,generosMusicais: null == generosMusicais ? _self.generosMusicais : generosMusicais // ignore: cast_nullable_to_non_nullable
as List<String>,tipoPerfil: null == tipoPerfil ? _self.tipoPerfil : tipoPerfil // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<String>,subCategories: null == subCategories ? _self.subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<String>,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedItem].
extension FeedItemPatterns on FeedItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedItem value)  $default,){
final _that = this;
switch (_that) {
case _FeedItem():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedItem value)?  $default,){
final _that = this;
switch (_that) {
case _FeedItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String nome,  String? nomeArtistico,  String? foto,  String? categoria,  List<String> generosMusicais,  String tipoPerfil,  Map<String, dynamic>? location,  int likeCount,  List<String> skills,  List<String> subCategories,  double? distanceKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedItem() when $default != null:
return $default(_that.uid,_that.nome,_that.nomeArtistico,_that.foto,_that.categoria,_that.generosMusicais,_that.tipoPerfil,_that.location,_that.likeCount,_that.skills,_that.subCategories,_that.distanceKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String nome,  String? nomeArtistico,  String? foto,  String? categoria,  List<String> generosMusicais,  String tipoPerfil,  Map<String, dynamic>? location,  int likeCount,  List<String> skills,  List<String> subCategories,  double? distanceKm)  $default,) {final _that = this;
switch (_that) {
case _FeedItem():
return $default(_that.uid,_that.nome,_that.nomeArtistico,_that.foto,_that.categoria,_that.generosMusicais,_that.tipoPerfil,_that.location,_that.likeCount,_that.skills,_that.subCategories,_that.distanceKm);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String nome,  String? nomeArtistico,  String? foto,  String? categoria,  List<String> generosMusicais,  String tipoPerfil,  Map<String, dynamic>? location,  int likeCount,  List<String> skills,  List<String> subCategories,  double? distanceKm)?  $default,) {final _that = this;
switch (_that) {
case _FeedItem() when $default != null:
return $default(_that.uid,_that.nome,_that.nomeArtistico,_that.foto,_that.categoria,_that.generosMusicais,_that.tipoPerfil,_that.location,_that.likeCount,_that.skills,_that.subCategories,_that.distanceKm);case _:
  return null;

}
}

}

/// @nodoc


class _FeedItem extends FeedItem {
  const _FeedItem({required this.uid, required this.nome, this.nomeArtistico, this.foto, this.categoria, final  List<String> generosMusicais = const [], required this.tipoPerfil, final  Map<String, dynamic>? location, this.likeCount = 0, final  List<String> skills = const [], final  List<String> subCategories = const [], this.distanceKm}): _generosMusicais = generosMusicais,_location = location,_skills = skills,_subCategories = subCategories,super._();
  

@override final  String uid;
@override final  String nome;
@override final  String? nomeArtistico;
@override final  String? foto;
@override final  String? categoria;
 final  List<String> _generosMusicais;
@override@JsonKey() List<String> get generosMusicais {
  if (_generosMusicais is EqualUnmodifiableListView) return _generosMusicais;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_generosMusicais);
}

@override final  String tipoPerfil;
 final  Map<String, dynamic>? _location;
@override Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  int likeCount;
 final  List<String> _skills;
@override@JsonKey() List<String> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

 final  List<String> _subCategories;
@override@JsonKey() List<String> get subCategories {
  if (_subCategories is EqualUnmodifiableListView) return _subCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subCategories);
}

// @Default(false) bool isFavorited, // Removed
@override final  double? distanceKm;

/// Create a copy of FeedItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedItemCopyWith<_FeedItem> get copyWith => __$FeedItemCopyWithImpl<_FeedItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedItem&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.nome, nome) || other.nome == nome)&&(identical(other.nomeArtistico, nomeArtistico) || other.nomeArtistico == nomeArtistico)&&(identical(other.foto, foto) || other.foto == foto)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&const DeepCollectionEquality().equals(other._generosMusicais, _generosMusicais)&&(identical(other.tipoPerfil, tipoPerfil) || other.tipoPerfil == tipoPerfil)&&const DeepCollectionEquality().equals(other._location, _location)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&const DeepCollectionEquality().equals(other._skills, _skills)&&const DeepCollectionEquality().equals(other._subCategories, _subCategories)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm));
}


@override
int get hashCode => Object.hash(runtimeType,uid,nome,nomeArtistico,foto,categoria,const DeepCollectionEquality().hash(_generosMusicais),tipoPerfil,const DeepCollectionEquality().hash(_location),likeCount,const DeepCollectionEquality().hash(_skills),const DeepCollectionEquality().hash(_subCategories),distanceKm);

@override
String toString() {
  return 'FeedItem(uid: $uid, nome: $nome, nomeArtistico: $nomeArtistico, foto: $foto, categoria: $categoria, generosMusicais: $generosMusicais, tipoPerfil: $tipoPerfil, location: $location, likeCount: $likeCount, skills: $skills, subCategories: $subCategories, distanceKm: $distanceKm)';
}


}

/// @nodoc
abstract mixin class _$FeedItemCopyWith<$Res> implements $FeedItemCopyWith<$Res> {
  factory _$FeedItemCopyWith(_FeedItem value, $Res Function(_FeedItem) _then) = __$FeedItemCopyWithImpl;
@override @useResult
$Res call({
 String uid, String nome, String? nomeArtistico, String? foto, String? categoria, List<String> generosMusicais, String tipoPerfil, Map<String, dynamic>? location, int likeCount, List<String> skills, List<String> subCategories, double? distanceKm
});




}
/// @nodoc
class __$FeedItemCopyWithImpl<$Res>
    implements _$FeedItemCopyWith<$Res> {
  __$FeedItemCopyWithImpl(this._self, this._then);

  final _FeedItem _self;
  final $Res Function(_FeedItem) _then;

/// Create a copy of FeedItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? nome = null,Object? nomeArtistico = freezed,Object? foto = freezed,Object? categoria = freezed,Object? generosMusicais = null,Object? tipoPerfil = null,Object? location = freezed,Object? likeCount = null,Object? skills = null,Object? subCategories = null,Object? distanceKm = freezed,}) {
  return _then(_FeedItem(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,nome: null == nome ? _self.nome : nome // ignore: cast_nullable_to_non_nullable
as String,nomeArtistico: freezed == nomeArtistico ? _self.nomeArtistico : nomeArtistico // ignore: cast_nullable_to_non_nullable
as String?,foto: freezed == foto ? _self.foto : foto // ignore: cast_nullable_to_non_nullable
as String?,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,generosMusicais: null == generosMusicais ? _self._generosMusicais : generosMusicais // ignore: cast_nullable_to_non_nullable
as List<String>,tipoPerfil: null == tipoPerfil ? _self.tipoPerfil : tipoPerfil // ignore: cast_nullable_to_non_nullable
as String,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<String>,subCategories: null == subCategories ? _self._subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<String>,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
