// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FavoriteState {

/// Favoritos locais refletidos na UI instantaneamente (Optimistic UI)
 Set<String> get localFavorites;/// Favoritos confirmados pelo servidor (Source of Truth)
 Set<String> get serverFavorites;/// Indica se há sincronização pendente com o servidor
 bool get isSyncing;/// Mapa de contador de likes para cada item (targetId -> count)
 Map<String, int> get likeCounts;
/// Create a copy of FavoriteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteStateCopyWith<FavoriteState> get copyWith => _$FavoriteStateCopyWithImpl<FavoriteState>(this as FavoriteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteState&&const DeepCollectionEquality().equals(other.localFavorites, localFavorites)&&const DeepCollectionEquality().equals(other.serverFavorites, serverFavorites)&&(identical(other.isSyncing, isSyncing) || other.isSyncing == isSyncing)&&const DeepCollectionEquality().equals(other.likeCounts, likeCounts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(localFavorites),const DeepCollectionEquality().hash(serverFavorites),isSyncing,const DeepCollectionEquality().hash(likeCounts));

@override
String toString() {
  return 'FavoriteState(localFavorites: $localFavorites, serverFavorites: $serverFavorites, isSyncing: $isSyncing, likeCounts: $likeCounts)';
}


}

/// @nodoc
abstract mixin class $FavoriteStateCopyWith<$Res>  {
  factory $FavoriteStateCopyWith(FavoriteState value, $Res Function(FavoriteState) _then) = _$FavoriteStateCopyWithImpl;
@useResult
$Res call({
 Set<String> localFavorites, Set<String> serverFavorites, bool isSyncing, Map<String, int> likeCounts
});




}
/// @nodoc
class _$FavoriteStateCopyWithImpl<$Res>
    implements $FavoriteStateCopyWith<$Res> {
  _$FavoriteStateCopyWithImpl(this._self, this._then);

  final FavoriteState _self;
  final $Res Function(FavoriteState) _then;

/// Create a copy of FavoriteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localFavorites = null,Object? serverFavorites = null,Object? isSyncing = null,Object? likeCounts = null,}) {
  return _then(_self.copyWith(
localFavorites: null == localFavorites ? _self.localFavorites : localFavorites // ignore: cast_nullable_to_non_nullable
as Set<String>,serverFavorites: null == serverFavorites ? _self.serverFavorites : serverFavorites // ignore: cast_nullable_to_non_nullable
as Set<String>,isSyncing: null == isSyncing ? _self.isSyncing : isSyncing // ignore: cast_nullable_to_non_nullable
as bool,likeCounts: null == likeCounts ? _self.likeCounts : likeCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteState].
extension FavoriteStatePatterns on FavoriteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoriteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoriteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoriteState value)  $default,){
final _that = this;
switch (_that) {
case _FavoriteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoriteState value)?  $default,){
final _that = this;
switch (_that) {
case _FavoriteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> localFavorites,  Set<String> serverFavorites,  bool isSyncing,  Map<String, int> likeCounts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoriteState() when $default != null:
return $default(_that.localFavorites,_that.serverFavorites,_that.isSyncing,_that.likeCounts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> localFavorites,  Set<String> serverFavorites,  bool isSyncing,  Map<String, int> likeCounts)  $default,) {final _that = this;
switch (_that) {
case _FavoriteState():
return $default(_that.localFavorites,_that.serverFavorites,_that.isSyncing,_that.likeCounts);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> localFavorites,  Set<String> serverFavorites,  bool isSyncing,  Map<String, int> likeCounts)?  $default,) {final _that = this;
switch (_that) {
case _FavoriteState() when $default != null:
return $default(_that.localFavorites,_that.serverFavorites,_that.isSyncing,_that.likeCounts);case _:
  return null;

}
}

}

/// @nodoc


class _FavoriteState implements FavoriteState {
  const _FavoriteState({final  Set<String> localFavorites = const {}, final  Set<String> serverFavorites = const {}, this.isSyncing = false, final  Map<String, int> likeCounts = const {}}): _localFavorites = localFavorites,_serverFavorites = serverFavorites,_likeCounts = likeCounts;
  

/// Favoritos locais refletidos na UI instantaneamente (Optimistic UI)
 final  Set<String> _localFavorites;
/// Favoritos locais refletidos na UI instantaneamente (Optimistic UI)
@override@JsonKey() Set<String> get localFavorites {
  if (_localFavorites is EqualUnmodifiableSetView) return _localFavorites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_localFavorites);
}

/// Favoritos confirmados pelo servidor (Source of Truth)
 final  Set<String> _serverFavorites;
/// Favoritos confirmados pelo servidor (Source of Truth)
@override@JsonKey() Set<String> get serverFavorites {
  if (_serverFavorites is EqualUnmodifiableSetView) return _serverFavorites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_serverFavorites);
}

/// Indica se há sincronização pendente com o servidor
@override@JsonKey() final  bool isSyncing;
/// Mapa de contador de likes para cada item (targetId -> count)
 final  Map<String, int> _likeCounts;
/// Mapa de contador de likes para cada item (targetId -> count)
@override@JsonKey() Map<String, int> get likeCounts {
  if (_likeCounts is EqualUnmodifiableMapView) return _likeCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_likeCounts);
}


/// Create a copy of FavoriteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteStateCopyWith<_FavoriteState> get copyWith => __$FavoriteStateCopyWithImpl<_FavoriteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoriteState&&const DeepCollectionEquality().equals(other._localFavorites, _localFavorites)&&const DeepCollectionEquality().equals(other._serverFavorites, _serverFavorites)&&(identical(other.isSyncing, isSyncing) || other.isSyncing == isSyncing)&&const DeepCollectionEquality().equals(other._likeCounts, _likeCounts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_localFavorites),const DeepCollectionEquality().hash(_serverFavorites),isSyncing,const DeepCollectionEquality().hash(_likeCounts));

@override
String toString() {
  return 'FavoriteState(localFavorites: $localFavorites, serverFavorites: $serverFavorites, isSyncing: $isSyncing, likeCounts: $likeCounts)';
}


}

/// @nodoc
abstract mixin class _$FavoriteStateCopyWith<$Res> implements $FavoriteStateCopyWith<$Res> {
  factory _$FavoriteStateCopyWith(_FavoriteState value, $Res Function(_FavoriteState) _then) = __$FavoriteStateCopyWithImpl;
@override @useResult
$Res call({
 Set<String> localFavorites, Set<String> serverFavorites, bool isSyncing, Map<String, int> likeCounts
});




}
/// @nodoc
class __$FavoriteStateCopyWithImpl<$Res>
    implements _$FavoriteStateCopyWith<$Res> {
  __$FavoriteStateCopyWithImpl(this._self, this._then);

  final _FavoriteState _self;
  final $Res Function(_FavoriteState) _then;

/// Create a copy of FavoriteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localFavorites = null,Object? serverFavorites = null,Object? isSyncing = null,Object? likeCounts = null,}) {
  return _then(_FavoriteState(
localFavorites: null == localFavorites ? _self._localFavorites : localFavorites // ignore: cast_nullable_to_non_nullable
as Set<String>,serverFavorites: null == serverFavorites ? _self._serverFavorites : serverFavorites // ignore: cast_nullable_to_non_nullable
as Set<String>,isSyncing: null == isSyncing ? _self.isSyncing : isSyncing // ignore: cast_nullable_to_non_nullable
as bool,likeCounts: null == likeCounts ? _self._likeCounts : likeCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
