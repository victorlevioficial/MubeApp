// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hashtag_ranking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HashtagRanking {

 String get id; String get hashtag; String get displayName; int get useCount; int get currentPosition; int get previousPosition; String get trend; int get trendDelta; bool get isTrending;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) Timestamp get lastUpdated;
/// Create a copy of HashtagRanking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HashtagRankingCopyWith<HashtagRanking> get copyWith => _$HashtagRankingCopyWithImpl<HashtagRanking>(this as HashtagRanking, _$identity);

  /// Serializes this HashtagRanking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HashtagRanking&&(identical(other.id, id) || other.id == id)&&(identical(other.hashtag, hashtag) || other.hashtag == hashtag)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.currentPosition, currentPosition) || other.currentPosition == currentPosition)&&(identical(other.previousPosition, previousPosition) || other.previousPosition == previousPosition)&&(identical(other.trend, trend) || other.trend == trend)&&(identical(other.trendDelta, trendDelta) || other.trendDelta == trendDelta)&&(identical(other.isTrending, isTrending) || other.isTrending == isTrending)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,hashtag,displayName,useCount,currentPosition,previousPosition,trend,trendDelta,isTrending,lastUpdated);

@override
String toString() {
  return 'HashtagRanking(id: $id, hashtag: $hashtag, displayName: $displayName, useCount: $useCount, currentPosition: $currentPosition, previousPosition: $previousPosition, trend: $trend, trendDelta: $trendDelta, isTrending: $isTrending, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class $HashtagRankingCopyWith<$Res>  {
  factory $HashtagRankingCopyWith(HashtagRanking value, $Res Function(HashtagRanking) _then) = _$HashtagRankingCopyWithImpl;
@useResult
$Res call({
 String id, String hashtag, String displayName, int useCount, int currentPosition, int previousPosition, String trend, int trendDelta, bool isTrending,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) Timestamp lastUpdated
});




}
/// @nodoc
class _$HashtagRankingCopyWithImpl<$Res>
    implements $HashtagRankingCopyWith<$Res> {
  _$HashtagRankingCopyWithImpl(this._self, this._then);

  final HashtagRanking _self;
  final $Res Function(HashtagRanking) _then;

/// Create a copy of HashtagRanking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? hashtag = null,Object? displayName = null,Object? useCount = null,Object? currentPosition = null,Object? previousPosition = null,Object? trend = null,Object? trendDelta = null,Object? isTrending = null,Object? lastUpdated = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hashtag: null == hashtag ? _self.hashtag : hashtag // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,currentPosition: null == currentPosition ? _self.currentPosition : currentPosition // ignore: cast_nullable_to_non_nullable
as int,previousPosition: null == previousPosition ? _self.previousPosition : previousPosition // ignore: cast_nullable_to_non_nullable
as int,trend: null == trend ? _self.trend : trend // ignore: cast_nullable_to_non_nullable
as String,trendDelta: null == trendDelta ? _self.trendDelta : trendDelta // ignore: cast_nullable_to_non_nullable
as int,isTrending: null == isTrending ? _self.isTrending : isTrending // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as Timestamp,
  ));
}

}


/// Adds pattern-matching-related methods to [HashtagRanking].
extension HashtagRankingPatterns on HashtagRanking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HashtagRanking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HashtagRanking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HashtagRanking value)  $default,){
final _that = this;
switch (_that) {
case _HashtagRanking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HashtagRanking value)?  $default,){
final _that = this;
switch (_that) {
case _HashtagRanking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String hashtag,  String displayName,  int useCount,  int currentPosition,  int previousPosition,  String trend,  int trendDelta,  bool isTrending, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  Timestamp lastUpdated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HashtagRanking() when $default != null:
return $default(_that.id,_that.hashtag,_that.displayName,_that.useCount,_that.currentPosition,_that.previousPosition,_that.trend,_that.trendDelta,_that.isTrending,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String hashtag,  String displayName,  int useCount,  int currentPosition,  int previousPosition,  String trend,  int trendDelta,  bool isTrending, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  Timestamp lastUpdated)  $default,) {final _that = this;
switch (_that) {
case _HashtagRanking():
return $default(_that.id,_that.hashtag,_that.displayName,_that.useCount,_that.currentPosition,_that.previousPosition,_that.trend,_that.trendDelta,_that.isTrending,_that.lastUpdated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String hashtag,  String displayName,  int useCount,  int currentPosition,  int previousPosition,  String trend,  int trendDelta,  bool isTrending, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  Timestamp lastUpdated)?  $default,) {final _that = this;
switch (_that) {
case _HashtagRanking() when $default != null:
return $default(_that.id,_that.hashtag,_that.displayName,_that.useCount,_that.currentPosition,_that.previousPosition,_that.trend,_that.trendDelta,_that.isTrending,_that.lastUpdated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HashtagRanking implements HashtagRanking {
  const _HashtagRanking({required this.id, required this.hashtag, required this.displayName, required this.useCount, required this.currentPosition, required this.previousPosition, required this.trend, required this.trendDelta, required this.isTrending, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) required this.lastUpdated});
  factory _HashtagRanking.fromJson(Map<String, dynamic> json) => _$HashtagRankingFromJson(json);

@override final  String id;
@override final  String hashtag;
@override final  String displayName;
@override final  int useCount;
@override final  int currentPosition;
@override final  int previousPosition;
@override final  String trend;
@override final  int trendDelta;
@override final  bool isTrending;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  Timestamp lastUpdated;

/// Create a copy of HashtagRanking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HashtagRankingCopyWith<_HashtagRanking> get copyWith => __$HashtagRankingCopyWithImpl<_HashtagRanking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HashtagRankingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HashtagRanking&&(identical(other.id, id) || other.id == id)&&(identical(other.hashtag, hashtag) || other.hashtag == hashtag)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.currentPosition, currentPosition) || other.currentPosition == currentPosition)&&(identical(other.previousPosition, previousPosition) || other.previousPosition == previousPosition)&&(identical(other.trend, trend) || other.trend == trend)&&(identical(other.trendDelta, trendDelta) || other.trendDelta == trendDelta)&&(identical(other.isTrending, isTrending) || other.isTrending == isTrending)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,hashtag,displayName,useCount,currentPosition,previousPosition,trend,trendDelta,isTrending,lastUpdated);

@override
String toString() {
  return 'HashtagRanking(id: $id, hashtag: $hashtag, displayName: $displayName, useCount: $useCount, currentPosition: $currentPosition, previousPosition: $previousPosition, trend: $trend, trendDelta: $trendDelta, isTrending: $isTrending, lastUpdated: $lastUpdated)';
}


}

/// @nodoc
abstract mixin class _$HashtagRankingCopyWith<$Res> implements $HashtagRankingCopyWith<$Res> {
  factory _$HashtagRankingCopyWith(_HashtagRanking value, $Res Function(_HashtagRanking) _then) = __$HashtagRankingCopyWithImpl;
@override @useResult
$Res call({
 String id, String hashtag, String displayName, int useCount, int currentPosition, int previousPosition, String trend, int trendDelta, bool isTrending,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) Timestamp lastUpdated
});




}
/// @nodoc
class __$HashtagRankingCopyWithImpl<$Res>
    implements _$HashtagRankingCopyWith<$Res> {
  __$HashtagRankingCopyWithImpl(this._self, this._then);

  final _HashtagRanking _self;
  final $Res Function(_HashtagRanking) _then;

/// Create a copy of HashtagRanking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? hashtag = null,Object? displayName = null,Object? useCount = null,Object? currentPosition = null,Object? previousPosition = null,Object? trend = null,Object? trendDelta = null,Object? isTrending = null,Object? lastUpdated = null,}) {
  return _then(_HashtagRanking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hashtag: null == hashtag ? _self.hashtag : hashtag // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,currentPosition: null == currentPosition ? _self.currentPosition : currentPosition // ignore: cast_nullable_to_non_nullable
as int,previousPosition: null == previousPosition ? _self.previousPosition : previousPosition // ignore: cast_nullable_to_non_nullable
as int,trend: null == trend ? _self.trend : trend // ignore: cast_nullable_to_non_nullable
as String,trendDelta: null == trendDelta ? _self.trendDelta : trendDelta // ignore: cast_nullable_to_non_nullable
as int,isTrending: null == isTrending ? _self.isTrending : isTrending // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as Timestamp,
  ));
}


}

// dart format on
