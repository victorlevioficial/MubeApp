// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gig_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GigDraft {

 String get title; String get description; GigType get gigType; GigDateMode get dateMode; DateTime? get gigDate; GigLocationType get locationType; Map<String, dynamic>? get location; String? get geohash; List<String> get genres; List<String> get requiredInstruments; List<String> get requiredCrewRoles; List<String> get requiredStudioServices; int get slotsTotal; CompensationType get compensationType; int? get compensationValue;
/// Create a copy of GigDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GigDraftCopyWith<GigDraft> get copyWith => _$GigDraftCopyWithImpl<GigDraft>(this as GigDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GigDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.gigType, gigType) || other.gigType == gigType)&&(identical(other.dateMode, dateMode) || other.dateMode == dateMode)&&(identical(other.gigDate, gigDate) || other.gigDate == gigDate)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&const DeepCollectionEquality().equals(other.location, location)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.requiredInstruments, requiredInstruments)&&const DeepCollectionEquality().equals(other.requiredCrewRoles, requiredCrewRoles)&&const DeepCollectionEquality().equals(other.requiredStudioServices, requiredStudioServices)&&(identical(other.slotsTotal, slotsTotal) || other.slotsTotal == slotsTotal)&&(identical(other.compensationType, compensationType) || other.compensationType == compensationType)&&(identical(other.compensationValue, compensationValue) || other.compensationValue == compensationValue));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,gigType,dateMode,gigDate,locationType,const DeepCollectionEquality().hash(location),geohash,const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(requiredInstruments),const DeepCollectionEquality().hash(requiredCrewRoles),const DeepCollectionEquality().hash(requiredStudioServices),slotsTotal,compensationType,compensationValue);

@override
String toString() {
  return 'GigDraft(title: $title, description: $description, gigType: $gigType, dateMode: $dateMode, gigDate: $gigDate, locationType: $locationType, location: $location, geohash: $geohash, genres: $genres, requiredInstruments: $requiredInstruments, requiredCrewRoles: $requiredCrewRoles, requiredStudioServices: $requiredStudioServices, slotsTotal: $slotsTotal, compensationType: $compensationType, compensationValue: $compensationValue)';
}


}

/// @nodoc
abstract mixin class $GigDraftCopyWith<$Res>  {
  factory $GigDraftCopyWith(GigDraft value, $Res Function(GigDraft) _then) = _$GigDraftCopyWithImpl;
@useResult
$Res call({
 String title, String description, GigType gigType, GigDateMode dateMode, DateTime? gigDate, GigLocationType locationType, Map<String, dynamic>? location, String? geohash, List<String> genres, List<String> requiredInstruments, List<String> requiredCrewRoles, List<String> requiredStudioServices, int slotsTotal, CompensationType compensationType, int? compensationValue
});




}
/// @nodoc
class _$GigDraftCopyWithImpl<$Res>
    implements $GigDraftCopyWith<$Res> {
  _$GigDraftCopyWithImpl(this._self, this._then);

  final GigDraft _self;
  final $Res Function(GigDraft) _then;

/// Create a copy of GigDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? gigType = null,Object? dateMode = null,Object? gigDate = freezed,Object? locationType = null,Object? location = freezed,Object? geohash = freezed,Object? genres = null,Object? requiredInstruments = null,Object? requiredCrewRoles = null,Object? requiredStudioServices = null,Object? slotsTotal = null,Object? compensationType = null,Object? compensationValue = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gigType: null == gigType ? _self.gigType : gigType // ignore: cast_nullable_to_non_nullable
as GigType,dateMode: null == dateMode ? _self.dateMode : dateMode // ignore: cast_nullable_to_non_nullable
as GigDateMode,gigDate: freezed == gigDate ? _self.gigDate : gigDate // ignore: cast_nullable_to_non_nullable
as DateTime?,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as GigLocationType,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,geohash: freezed == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,requiredInstruments: null == requiredInstruments ? _self.requiredInstruments : requiredInstruments // ignore: cast_nullable_to_non_nullable
as List<String>,requiredCrewRoles: null == requiredCrewRoles ? _self.requiredCrewRoles : requiredCrewRoles // ignore: cast_nullable_to_non_nullable
as List<String>,requiredStudioServices: null == requiredStudioServices ? _self.requiredStudioServices : requiredStudioServices // ignore: cast_nullable_to_non_nullable
as List<String>,slotsTotal: null == slotsTotal ? _self.slotsTotal : slotsTotal // ignore: cast_nullable_to_non_nullable
as int,compensationType: null == compensationType ? _self.compensationType : compensationType // ignore: cast_nullable_to_non_nullable
as CompensationType,compensationValue: freezed == compensationValue ? _self.compensationValue : compensationValue // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GigDraft].
extension GigDraftPatterns on GigDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GigDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GigDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GigDraft value)  $default,){
final _that = this;
switch (_that) {
case _GigDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GigDraft value)?  $default,){
final _that = this;
switch (_that) {
case _GigDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  GigType gigType,  GigDateMode dateMode,  DateTime? gigDate,  GigLocationType locationType,  Map<String, dynamic>? location,  String? geohash,  List<String> genres,  List<String> requiredInstruments,  List<String> requiredCrewRoles,  List<String> requiredStudioServices,  int slotsTotal,  CompensationType compensationType,  int? compensationValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GigDraft() when $default != null:
return $default(_that.title,_that.description,_that.gigType,_that.dateMode,_that.gigDate,_that.locationType,_that.location,_that.geohash,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.compensationType,_that.compensationValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  GigType gigType,  GigDateMode dateMode,  DateTime? gigDate,  GigLocationType locationType,  Map<String, dynamic>? location,  String? geohash,  List<String> genres,  List<String> requiredInstruments,  List<String> requiredCrewRoles,  List<String> requiredStudioServices,  int slotsTotal,  CompensationType compensationType,  int? compensationValue)  $default,) {final _that = this;
switch (_that) {
case _GigDraft():
return $default(_that.title,_that.description,_that.gigType,_that.dateMode,_that.gigDate,_that.locationType,_that.location,_that.geohash,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.compensationType,_that.compensationValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  GigType gigType,  GigDateMode dateMode,  DateTime? gigDate,  GigLocationType locationType,  Map<String, dynamic>? location,  String? geohash,  List<String> genres,  List<String> requiredInstruments,  List<String> requiredCrewRoles,  List<String> requiredStudioServices,  int slotsTotal,  CompensationType compensationType,  int? compensationValue)?  $default,) {final _that = this;
switch (_that) {
case _GigDraft() when $default != null:
return $default(_that.title,_that.description,_that.gigType,_that.dateMode,_that.gigDate,_that.locationType,_that.location,_that.geohash,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.compensationType,_that.compensationValue);case _:
  return null;

}
}

}

/// @nodoc


class _GigDraft extends GigDraft {
  const _GigDraft({required this.title, required this.description, required this.gigType, required this.dateMode, this.gigDate, required this.locationType, final  Map<String, dynamic>? location, this.geohash, final  List<String> genres = const [], final  List<String> requiredInstruments = const [], final  List<String> requiredCrewRoles = const [], final  List<String> requiredStudioServices = const [], required this.slotsTotal, required this.compensationType, this.compensationValue}): _location = location,_genres = genres,_requiredInstruments = requiredInstruments,_requiredCrewRoles = requiredCrewRoles,_requiredStudioServices = requiredStudioServices,super._();
  

@override final  String title;
@override final  String description;
@override final  GigType gigType;
@override final  GigDateMode dateMode;
@override final  DateTime? gigDate;
@override final  GigLocationType locationType;
 final  Map<String, dynamic>? _location;
@override Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? geohash;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

 final  List<String> _requiredInstruments;
@override@JsonKey() List<String> get requiredInstruments {
  if (_requiredInstruments is EqualUnmodifiableListView) return _requiredInstruments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredInstruments);
}

 final  List<String> _requiredCrewRoles;
@override@JsonKey() List<String> get requiredCrewRoles {
  if (_requiredCrewRoles is EqualUnmodifiableListView) return _requiredCrewRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredCrewRoles);
}

 final  List<String> _requiredStudioServices;
@override@JsonKey() List<String> get requiredStudioServices {
  if (_requiredStudioServices is EqualUnmodifiableListView) return _requiredStudioServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredStudioServices);
}

@override final  int slotsTotal;
@override final  CompensationType compensationType;
@override final  int? compensationValue;

/// Create a copy of GigDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GigDraftCopyWith<_GigDraft> get copyWith => __$GigDraftCopyWithImpl<_GigDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GigDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.gigType, gigType) || other.gigType == gigType)&&(identical(other.dateMode, dateMode) || other.dateMode == dateMode)&&(identical(other.gigDate, gigDate) || other.gigDate == gigDate)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&const DeepCollectionEquality().equals(other._location, _location)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._requiredInstruments, _requiredInstruments)&&const DeepCollectionEquality().equals(other._requiredCrewRoles, _requiredCrewRoles)&&const DeepCollectionEquality().equals(other._requiredStudioServices, _requiredStudioServices)&&(identical(other.slotsTotal, slotsTotal) || other.slotsTotal == slotsTotal)&&(identical(other.compensationType, compensationType) || other.compensationType == compensationType)&&(identical(other.compensationValue, compensationValue) || other.compensationValue == compensationValue));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,gigType,dateMode,gigDate,locationType,const DeepCollectionEquality().hash(_location),geohash,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_requiredInstruments),const DeepCollectionEquality().hash(_requiredCrewRoles),const DeepCollectionEquality().hash(_requiredStudioServices),slotsTotal,compensationType,compensationValue);

@override
String toString() {
  return 'GigDraft(title: $title, description: $description, gigType: $gigType, dateMode: $dateMode, gigDate: $gigDate, locationType: $locationType, location: $location, geohash: $geohash, genres: $genres, requiredInstruments: $requiredInstruments, requiredCrewRoles: $requiredCrewRoles, requiredStudioServices: $requiredStudioServices, slotsTotal: $slotsTotal, compensationType: $compensationType, compensationValue: $compensationValue)';
}


}

/// @nodoc
abstract mixin class _$GigDraftCopyWith<$Res> implements $GigDraftCopyWith<$Res> {
  factory _$GigDraftCopyWith(_GigDraft value, $Res Function(_GigDraft) _then) = __$GigDraftCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, GigType gigType, GigDateMode dateMode, DateTime? gigDate, GigLocationType locationType, Map<String, dynamic>? location, String? geohash, List<String> genres, List<String> requiredInstruments, List<String> requiredCrewRoles, List<String> requiredStudioServices, int slotsTotal, CompensationType compensationType, int? compensationValue
});




}
/// @nodoc
class __$GigDraftCopyWithImpl<$Res>
    implements _$GigDraftCopyWith<$Res> {
  __$GigDraftCopyWithImpl(this._self, this._then);

  final _GigDraft _self;
  final $Res Function(_GigDraft) _then;

/// Create a copy of GigDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? gigType = null,Object? dateMode = null,Object? gigDate = freezed,Object? locationType = null,Object? location = freezed,Object? geohash = freezed,Object? genres = null,Object? requiredInstruments = null,Object? requiredCrewRoles = null,Object? requiredStudioServices = null,Object? slotsTotal = null,Object? compensationType = null,Object? compensationValue = freezed,}) {
  return _then(_GigDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gigType: null == gigType ? _self.gigType : gigType // ignore: cast_nullable_to_non_nullable
as GigType,dateMode: null == dateMode ? _self.dateMode : dateMode // ignore: cast_nullable_to_non_nullable
as GigDateMode,gigDate: freezed == gigDate ? _self.gigDate : gigDate // ignore: cast_nullable_to_non_nullable
as DateTime?,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as GigLocationType,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,geohash: freezed == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,requiredInstruments: null == requiredInstruments ? _self._requiredInstruments : requiredInstruments // ignore: cast_nullable_to_non_nullable
as List<String>,requiredCrewRoles: null == requiredCrewRoles ? _self._requiredCrewRoles : requiredCrewRoles // ignore: cast_nullable_to_non_nullable
as List<String>,requiredStudioServices: null == requiredStudioServices ? _self._requiredStudioServices : requiredStudioServices // ignore: cast_nullable_to_non_nullable
as List<String>,slotsTotal: null == slotsTotal ? _self.slotsTotal : slotsTotal // ignore: cast_nullable_to_non_nullable
as int,compensationType: null == compensationType ? _self.compensationType : compensationType // ignore: cast_nullable_to_non_nullable
as CompensationType,compensationValue: freezed == compensationValue ? _self.compensationValue : compensationValue // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$GigUpdate {

 String? get title; String? get description; GigType? get gigType; GigDateMode? get dateMode; DateTime? get gigDate; bool get clearGigDate; GigLocationType? get locationType; Map<String, dynamic>? get location; String? get geohash; bool get clearLocation; List<String>? get genres; List<String>? get requiredInstruments; List<String>? get requiredCrewRoles; List<String>? get requiredStudioServices; int? get slotsTotal; CompensationType? get compensationType; int? get compensationValue; bool get clearCompensationValue;
/// Create a copy of GigUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GigUpdateCopyWith<GigUpdate> get copyWith => _$GigUpdateCopyWithImpl<GigUpdate>(this as GigUpdate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GigUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.gigType, gigType) || other.gigType == gigType)&&(identical(other.dateMode, dateMode) || other.dateMode == dateMode)&&(identical(other.gigDate, gigDate) || other.gigDate == gigDate)&&(identical(other.clearGigDate, clearGigDate) || other.clearGigDate == clearGigDate)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&const DeepCollectionEquality().equals(other.location, location)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&(identical(other.clearLocation, clearLocation) || other.clearLocation == clearLocation)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.requiredInstruments, requiredInstruments)&&const DeepCollectionEquality().equals(other.requiredCrewRoles, requiredCrewRoles)&&const DeepCollectionEquality().equals(other.requiredStudioServices, requiredStudioServices)&&(identical(other.slotsTotal, slotsTotal) || other.slotsTotal == slotsTotal)&&(identical(other.compensationType, compensationType) || other.compensationType == compensationType)&&(identical(other.compensationValue, compensationValue) || other.compensationValue == compensationValue)&&(identical(other.clearCompensationValue, clearCompensationValue) || other.clearCompensationValue == clearCompensationValue));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,gigType,dateMode,gigDate,clearGigDate,locationType,const DeepCollectionEquality().hash(location),geohash,clearLocation,const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(requiredInstruments),const DeepCollectionEquality().hash(requiredCrewRoles),const DeepCollectionEquality().hash(requiredStudioServices),slotsTotal,compensationType,compensationValue,clearCompensationValue);

@override
String toString() {
  return 'GigUpdate(title: $title, description: $description, gigType: $gigType, dateMode: $dateMode, gigDate: $gigDate, clearGigDate: $clearGigDate, locationType: $locationType, location: $location, geohash: $geohash, clearLocation: $clearLocation, genres: $genres, requiredInstruments: $requiredInstruments, requiredCrewRoles: $requiredCrewRoles, requiredStudioServices: $requiredStudioServices, slotsTotal: $slotsTotal, compensationType: $compensationType, compensationValue: $compensationValue, clearCompensationValue: $clearCompensationValue)';
}


}

/// @nodoc
abstract mixin class $GigUpdateCopyWith<$Res>  {
  factory $GigUpdateCopyWith(GigUpdate value, $Res Function(GigUpdate) _then) = _$GigUpdateCopyWithImpl;
@useResult
$Res call({
 String? title, String? description, GigType? gigType, GigDateMode? dateMode, DateTime? gigDate, bool clearGigDate, GigLocationType? locationType, Map<String, dynamic>? location, String? geohash, bool clearLocation, List<String>? genres, List<String>? requiredInstruments, List<String>? requiredCrewRoles, List<String>? requiredStudioServices, int? slotsTotal, CompensationType? compensationType, int? compensationValue, bool clearCompensationValue
});




}
/// @nodoc
class _$GigUpdateCopyWithImpl<$Res>
    implements $GigUpdateCopyWith<$Res> {
  _$GigUpdateCopyWithImpl(this._self, this._then);

  final GigUpdate _self;
  final $Res Function(GigUpdate) _then;

/// Create a copy of GigUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? gigType = freezed,Object? dateMode = freezed,Object? gigDate = freezed,Object? clearGigDate = null,Object? locationType = freezed,Object? location = freezed,Object? geohash = freezed,Object? clearLocation = null,Object? genres = freezed,Object? requiredInstruments = freezed,Object? requiredCrewRoles = freezed,Object? requiredStudioServices = freezed,Object? slotsTotal = freezed,Object? compensationType = freezed,Object? compensationValue = freezed,Object? clearCompensationValue = null,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,gigType: freezed == gigType ? _self.gigType : gigType // ignore: cast_nullable_to_non_nullable
as GigType?,dateMode: freezed == dateMode ? _self.dateMode : dateMode // ignore: cast_nullable_to_non_nullable
as GigDateMode?,gigDate: freezed == gigDate ? _self.gigDate : gigDate // ignore: cast_nullable_to_non_nullable
as DateTime?,clearGigDate: null == clearGigDate ? _self.clearGigDate : clearGigDate // ignore: cast_nullable_to_non_nullable
as bool,locationType: freezed == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as GigLocationType?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,geohash: freezed == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String?,clearLocation: null == clearLocation ? _self.clearLocation : clearLocation // ignore: cast_nullable_to_non_nullable
as bool,genres: freezed == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>?,requiredInstruments: freezed == requiredInstruments ? _self.requiredInstruments : requiredInstruments // ignore: cast_nullable_to_non_nullable
as List<String>?,requiredCrewRoles: freezed == requiredCrewRoles ? _self.requiredCrewRoles : requiredCrewRoles // ignore: cast_nullable_to_non_nullable
as List<String>?,requiredStudioServices: freezed == requiredStudioServices ? _self.requiredStudioServices : requiredStudioServices // ignore: cast_nullable_to_non_nullable
as List<String>?,slotsTotal: freezed == slotsTotal ? _self.slotsTotal : slotsTotal // ignore: cast_nullable_to_non_nullable
as int?,compensationType: freezed == compensationType ? _self.compensationType : compensationType // ignore: cast_nullable_to_non_nullable
as CompensationType?,compensationValue: freezed == compensationValue ? _self.compensationValue : compensationValue // ignore: cast_nullable_to_non_nullable
as int?,clearCompensationValue: null == clearCompensationValue ? _self.clearCompensationValue : clearCompensationValue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GigUpdate].
extension GigUpdatePatterns on GigUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GigUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GigUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GigUpdate value)  $default,){
final _that = this;
switch (_that) {
case _GigUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GigUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _GigUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description,  GigType? gigType,  GigDateMode? dateMode,  DateTime? gigDate,  bool clearGigDate,  GigLocationType? locationType,  Map<String, dynamic>? location,  String? geohash,  bool clearLocation,  List<String>? genres,  List<String>? requiredInstruments,  List<String>? requiredCrewRoles,  List<String>? requiredStudioServices,  int? slotsTotal,  CompensationType? compensationType,  int? compensationValue,  bool clearCompensationValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GigUpdate() when $default != null:
return $default(_that.title,_that.description,_that.gigType,_that.dateMode,_that.gigDate,_that.clearGigDate,_that.locationType,_that.location,_that.geohash,_that.clearLocation,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.compensationType,_that.compensationValue,_that.clearCompensationValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description,  GigType? gigType,  GigDateMode? dateMode,  DateTime? gigDate,  bool clearGigDate,  GigLocationType? locationType,  Map<String, dynamic>? location,  String? geohash,  bool clearLocation,  List<String>? genres,  List<String>? requiredInstruments,  List<String>? requiredCrewRoles,  List<String>? requiredStudioServices,  int? slotsTotal,  CompensationType? compensationType,  int? compensationValue,  bool clearCompensationValue)  $default,) {final _that = this;
switch (_that) {
case _GigUpdate():
return $default(_that.title,_that.description,_that.gigType,_that.dateMode,_that.gigDate,_that.clearGigDate,_that.locationType,_that.location,_that.geohash,_that.clearLocation,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.compensationType,_that.compensationValue,_that.clearCompensationValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description,  GigType? gigType,  GigDateMode? dateMode,  DateTime? gigDate,  bool clearGigDate,  GigLocationType? locationType,  Map<String, dynamic>? location,  String? geohash,  bool clearLocation,  List<String>? genres,  List<String>? requiredInstruments,  List<String>? requiredCrewRoles,  List<String>? requiredStudioServices,  int? slotsTotal,  CompensationType? compensationType,  int? compensationValue,  bool clearCompensationValue)?  $default,) {final _that = this;
switch (_that) {
case _GigUpdate() when $default != null:
return $default(_that.title,_that.description,_that.gigType,_that.dateMode,_that.gigDate,_that.clearGigDate,_that.locationType,_that.location,_that.geohash,_that.clearLocation,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.compensationType,_that.compensationValue,_that.clearCompensationValue);case _:
  return null;

}
}

}

/// @nodoc


class _GigUpdate implements GigUpdate {
  const _GigUpdate({this.title, this.description, this.gigType, this.dateMode, this.gigDate, this.clearGigDate = false, this.locationType, final  Map<String, dynamic>? location, this.geohash, this.clearLocation = false, final  List<String>? genres, final  List<String>? requiredInstruments, final  List<String>? requiredCrewRoles, final  List<String>? requiredStudioServices, this.slotsTotal, this.compensationType, this.compensationValue, this.clearCompensationValue = false}): _location = location,_genres = genres,_requiredInstruments = requiredInstruments,_requiredCrewRoles = requiredCrewRoles,_requiredStudioServices = requiredStudioServices;
  

@override final  String? title;
@override final  String? description;
@override final  GigType? gigType;
@override final  GigDateMode? dateMode;
@override final  DateTime? gigDate;
@override@JsonKey() final  bool clearGigDate;
@override final  GigLocationType? locationType;
 final  Map<String, dynamic>? _location;
@override Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? geohash;
@override@JsonKey() final  bool clearLocation;
 final  List<String>? _genres;
@override List<String>? get genres {
  final value = _genres;
  if (value == null) return null;
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _requiredInstruments;
@override List<String>? get requiredInstruments {
  final value = _requiredInstruments;
  if (value == null) return null;
  if (_requiredInstruments is EqualUnmodifiableListView) return _requiredInstruments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _requiredCrewRoles;
@override List<String>? get requiredCrewRoles {
  final value = _requiredCrewRoles;
  if (value == null) return null;
  if (_requiredCrewRoles is EqualUnmodifiableListView) return _requiredCrewRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _requiredStudioServices;
@override List<String>? get requiredStudioServices {
  final value = _requiredStudioServices;
  if (value == null) return null;
  if (_requiredStudioServices is EqualUnmodifiableListView) return _requiredStudioServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? slotsTotal;
@override final  CompensationType? compensationType;
@override final  int? compensationValue;
@override@JsonKey() final  bool clearCompensationValue;

/// Create a copy of GigUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GigUpdateCopyWith<_GigUpdate> get copyWith => __$GigUpdateCopyWithImpl<_GigUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GigUpdate&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.gigType, gigType) || other.gigType == gigType)&&(identical(other.dateMode, dateMode) || other.dateMode == dateMode)&&(identical(other.gigDate, gigDate) || other.gigDate == gigDate)&&(identical(other.clearGigDate, clearGigDate) || other.clearGigDate == clearGigDate)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&const DeepCollectionEquality().equals(other._location, _location)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&(identical(other.clearLocation, clearLocation) || other.clearLocation == clearLocation)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._requiredInstruments, _requiredInstruments)&&const DeepCollectionEquality().equals(other._requiredCrewRoles, _requiredCrewRoles)&&const DeepCollectionEquality().equals(other._requiredStudioServices, _requiredStudioServices)&&(identical(other.slotsTotal, slotsTotal) || other.slotsTotal == slotsTotal)&&(identical(other.compensationType, compensationType) || other.compensationType == compensationType)&&(identical(other.compensationValue, compensationValue) || other.compensationValue == compensationValue)&&(identical(other.clearCompensationValue, clearCompensationValue) || other.clearCompensationValue == clearCompensationValue));
}


@override
int get hashCode => Object.hash(runtimeType,title,description,gigType,dateMode,gigDate,clearGigDate,locationType,const DeepCollectionEquality().hash(_location),geohash,clearLocation,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_requiredInstruments),const DeepCollectionEquality().hash(_requiredCrewRoles),const DeepCollectionEquality().hash(_requiredStudioServices),slotsTotal,compensationType,compensationValue,clearCompensationValue);

@override
String toString() {
  return 'GigUpdate(title: $title, description: $description, gigType: $gigType, dateMode: $dateMode, gigDate: $gigDate, clearGigDate: $clearGigDate, locationType: $locationType, location: $location, geohash: $geohash, clearLocation: $clearLocation, genres: $genres, requiredInstruments: $requiredInstruments, requiredCrewRoles: $requiredCrewRoles, requiredStudioServices: $requiredStudioServices, slotsTotal: $slotsTotal, compensationType: $compensationType, compensationValue: $compensationValue, clearCompensationValue: $clearCompensationValue)';
}


}

/// @nodoc
abstract mixin class _$GigUpdateCopyWith<$Res> implements $GigUpdateCopyWith<$Res> {
  factory _$GigUpdateCopyWith(_GigUpdate value, $Res Function(_GigUpdate) _then) = __$GigUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description, GigType? gigType, GigDateMode? dateMode, DateTime? gigDate, bool clearGigDate, GigLocationType? locationType, Map<String, dynamic>? location, String? geohash, bool clearLocation, List<String>? genres, List<String>? requiredInstruments, List<String>? requiredCrewRoles, List<String>? requiredStudioServices, int? slotsTotal, CompensationType? compensationType, int? compensationValue, bool clearCompensationValue
});




}
/// @nodoc
class __$GigUpdateCopyWithImpl<$Res>
    implements _$GigUpdateCopyWith<$Res> {
  __$GigUpdateCopyWithImpl(this._self, this._then);

  final _GigUpdate _self;
  final $Res Function(_GigUpdate) _then;

/// Create a copy of GigUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? gigType = freezed,Object? dateMode = freezed,Object? gigDate = freezed,Object? clearGigDate = null,Object? locationType = freezed,Object? location = freezed,Object? geohash = freezed,Object? clearLocation = null,Object? genres = freezed,Object? requiredInstruments = freezed,Object? requiredCrewRoles = freezed,Object? requiredStudioServices = freezed,Object? slotsTotal = freezed,Object? compensationType = freezed,Object? compensationValue = freezed,Object? clearCompensationValue = null,}) {
  return _then(_GigUpdate(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,gigType: freezed == gigType ? _self.gigType : gigType // ignore: cast_nullable_to_non_nullable
as GigType?,dateMode: freezed == dateMode ? _self.dateMode : dateMode // ignore: cast_nullable_to_non_nullable
as GigDateMode?,gigDate: freezed == gigDate ? _self.gigDate : gigDate // ignore: cast_nullable_to_non_nullable
as DateTime?,clearGigDate: null == clearGigDate ? _self.clearGigDate : clearGigDate // ignore: cast_nullable_to_non_nullable
as bool,locationType: freezed == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as GigLocationType?,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,geohash: freezed == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String?,clearLocation: null == clearLocation ? _self.clearLocation : clearLocation // ignore: cast_nullable_to_non_nullable
as bool,genres: freezed == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>?,requiredInstruments: freezed == requiredInstruments ? _self._requiredInstruments : requiredInstruments // ignore: cast_nullable_to_non_nullable
as List<String>?,requiredCrewRoles: freezed == requiredCrewRoles ? _self._requiredCrewRoles : requiredCrewRoles // ignore: cast_nullable_to_non_nullable
as List<String>?,requiredStudioServices: freezed == requiredStudioServices ? _self._requiredStudioServices : requiredStudioServices // ignore: cast_nullable_to_non_nullable
as List<String>?,slotsTotal: freezed == slotsTotal ? _self.slotsTotal : slotsTotal // ignore: cast_nullable_to_non_nullable
as int?,compensationType: freezed == compensationType ? _self.compensationType : compensationType // ignore: cast_nullable_to_non_nullable
as CompensationType?,compensationValue: freezed == compensationValue ? _self.compensationValue : compensationValue // ignore: cast_nullable_to_non_nullable
as int?,clearCompensationValue: null == clearCompensationValue ? _self.clearCompensationValue : clearCompensationValue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$GigReviewDraft {

 String get gigId; String get reviewedUserId; int get rating; String? get comment;
/// Create a copy of GigReviewDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GigReviewDraftCopyWith<GigReviewDraft> get copyWith => _$GigReviewDraftCopyWithImpl<GigReviewDraft>(this as GigReviewDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GigReviewDraft&&(identical(other.gigId, gigId) || other.gigId == gigId)&&(identical(other.reviewedUserId, reviewedUserId) || other.reviewedUserId == reviewedUserId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment));
}


@override
int get hashCode => Object.hash(runtimeType,gigId,reviewedUserId,rating,comment);

@override
String toString() {
  return 'GigReviewDraft(gigId: $gigId, reviewedUserId: $reviewedUserId, rating: $rating, comment: $comment)';
}


}

/// @nodoc
abstract mixin class $GigReviewDraftCopyWith<$Res>  {
  factory $GigReviewDraftCopyWith(GigReviewDraft value, $Res Function(GigReviewDraft) _then) = _$GigReviewDraftCopyWithImpl;
@useResult
$Res call({
 String gigId, String reviewedUserId, int rating, String? comment
});




}
/// @nodoc
class _$GigReviewDraftCopyWithImpl<$Res>
    implements $GigReviewDraftCopyWith<$Res> {
  _$GigReviewDraftCopyWithImpl(this._self, this._then);

  final GigReviewDraft _self;
  final $Res Function(GigReviewDraft) _then;

/// Create a copy of GigReviewDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gigId = null,Object? reviewedUserId = null,Object? rating = null,Object? comment = freezed,}) {
  return _then(_self.copyWith(
gigId: null == gigId ? _self.gigId : gigId // ignore: cast_nullable_to_non_nullable
as String,reviewedUserId: null == reviewedUserId ? _self.reviewedUserId : reviewedUserId // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GigReviewDraft].
extension GigReviewDraftPatterns on GigReviewDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GigReviewDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GigReviewDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GigReviewDraft value)  $default,){
final _that = this;
switch (_that) {
case _GigReviewDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GigReviewDraft value)?  $default,){
final _that = this;
switch (_that) {
case _GigReviewDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gigId,  String reviewedUserId,  int rating,  String? comment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GigReviewDraft() when $default != null:
return $default(_that.gigId,_that.reviewedUserId,_that.rating,_that.comment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gigId,  String reviewedUserId,  int rating,  String? comment)  $default,) {final _that = this;
switch (_that) {
case _GigReviewDraft():
return $default(_that.gigId,_that.reviewedUserId,_that.rating,_that.comment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gigId,  String reviewedUserId,  int rating,  String? comment)?  $default,) {final _that = this;
switch (_that) {
case _GigReviewDraft() when $default != null:
return $default(_that.gigId,_that.reviewedUserId,_that.rating,_that.comment);case _:
  return null;

}
}

}

/// @nodoc


class _GigReviewDraft implements GigReviewDraft {
  const _GigReviewDraft({required this.gigId, required this.reviewedUserId, required this.rating, this.comment});
  

@override final  String gigId;
@override final  String reviewedUserId;
@override final  int rating;
@override final  String? comment;

/// Create a copy of GigReviewDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GigReviewDraftCopyWith<_GigReviewDraft> get copyWith => __$GigReviewDraftCopyWithImpl<_GigReviewDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GigReviewDraft&&(identical(other.gigId, gigId) || other.gigId == gigId)&&(identical(other.reviewedUserId, reviewedUserId) || other.reviewedUserId == reviewedUserId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment));
}


@override
int get hashCode => Object.hash(runtimeType,gigId,reviewedUserId,rating,comment);

@override
String toString() {
  return 'GigReviewDraft(gigId: $gigId, reviewedUserId: $reviewedUserId, rating: $rating, comment: $comment)';
}


}

/// @nodoc
abstract mixin class _$GigReviewDraftCopyWith<$Res> implements $GigReviewDraftCopyWith<$Res> {
  factory _$GigReviewDraftCopyWith(_GigReviewDraft value, $Res Function(_GigReviewDraft) _then) = __$GigReviewDraftCopyWithImpl;
@override @useResult
$Res call({
 String gigId, String reviewedUserId, int rating, String? comment
});




}
/// @nodoc
class __$GigReviewDraftCopyWithImpl<$Res>
    implements _$GigReviewDraftCopyWith<$Res> {
  __$GigReviewDraftCopyWithImpl(this._self, this._then);

  final _GigReviewDraft _self;
  final $Res Function(_GigReviewDraft) _then;

/// Create a copy of GigReviewDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gigId = null,Object? reviewedUserId = null,Object? rating = null,Object? comment = freezed,}) {
  return _then(_GigReviewDraft(
gigId: null == gigId ? _self.gigId : gigId // ignore: cast_nullable_to_non_nullable
as String,reviewedUserId: null == reviewedUserId ? _self.reviewedUserId : reviewedUserId // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
