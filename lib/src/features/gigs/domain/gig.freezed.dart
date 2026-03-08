// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gig.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Gig {

 String get id; String get title; String get description;@JsonKey(name: 'gig_type') GigType get gigType;@JsonKey(name: 'status') GigStatus get status;@JsonKey(name: 'date_mode') GigDateMode get dateMode;@JsonKey(name: 'gig_date') DateTime? get gigDate;@JsonKey(name: 'location_type') GigLocationType get locationType; Map<String, dynamic>? get location; String? get geohash; List<String> get genres;@JsonKey(name: 'required_instruments') List<String> get requiredInstruments;@JsonKey(name: 'required_crew_roles') List<String> get requiredCrewRoles;@JsonKey(name: 'required_studio_services') List<String> get requiredStudioServices;@JsonKey(name: 'slots_total') int get slotsTotal;@JsonKey(name: 'slots_filled') int get slotsFilled;@JsonKey(name: 'compensation_type') CompensationType get compensationType;@JsonKey(name: 'compensation_value') int? get compensationValue;@JsonKey(name: 'creator_id') String get creatorId;@JsonKey(name: 'applicant_count') int get applicantCount;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'expires_at') DateTime? get expiresAt;
/// Create a copy of Gig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GigCopyWith<Gig> get copyWith => _$GigCopyWithImpl<Gig>(this as Gig, _$identity);

  /// Serializes this Gig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gig&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.gigType, gigType) || other.gigType == gigType)&&(identical(other.status, status) || other.status == status)&&(identical(other.dateMode, dateMode) || other.dateMode == dateMode)&&(identical(other.gigDate, gigDate) || other.gigDate == gigDate)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&const DeepCollectionEquality().equals(other.location, location)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.requiredInstruments, requiredInstruments)&&const DeepCollectionEquality().equals(other.requiredCrewRoles, requiredCrewRoles)&&const DeepCollectionEquality().equals(other.requiredStudioServices, requiredStudioServices)&&(identical(other.slotsTotal, slotsTotal) || other.slotsTotal == slotsTotal)&&(identical(other.slotsFilled, slotsFilled) || other.slotsFilled == slotsFilled)&&(identical(other.compensationType, compensationType) || other.compensationType == compensationType)&&(identical(other.compensationValue, compensationValue) || other.compensationValue == compensationValue)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.applicantCount, applicantCount) || other.applicantCount == applicantCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,gigType,status,dateMode,gigDate,locationType,const DeepCollectionEquality().hash(location),geohash,const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(requiredInstruments),const DeepCollectionEquality().hash(requiredCrewRoles),const DeepCollectionEquality().hash(requiredStudioServices),slotsTotal,slotsFilled,compensationType,compensationValue,creatorId,applicantCount,createdAt,updatedAt,expiresAt]);

@override
String toString() {
  return 'Gig(id: $id, title: $title, description: $description, gigType: $gigType, status: $status, dateMode: $dateMode, gigDate: $gigDate, locationType: $locationType, location: $location, geohash: $geohash, genres: $genres, requiredInstruments: $requiredInstruments, requiredCrewRoles: $requiredCrewRoles, requiredStudioServices: $requiredStudioServices, slotsTotal: $slotsTotal, slotsFilled: $slotsFilled, compensationType: $compensationType, compensationValue: $compensationValue, creatorId: $creatorId, applicantCount: $applicantCount, createdAt: $createdAt, updatedAt: $updatedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $GigCopyWith<$Res>  {
  factory $GigCopyWith(Gig value, $Res Function(Gig) _then) = _$GigCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description,@JsonKey(name: 'gig_type') GigType gigType,@JsonKey(name: 'status') GigStatus status,@JsonKey(name: 'date_mode') GigDateMode dateMode,@JsonKey(name: 'gig_date') DateTime? gigDate,@JsonKey(name: 'location_type') GigLocationType locationType, Map<String, dynamic>? location, String? geohash, List<String> genres,@JsonKey(name: 'required_instruments') List<String> requiredInstruments,@JsonKey(name: 'required_crew_roles') List<String> requiredCrewRoles,@JsonKey(name: 'required_studio_services') List<String> requiredStudioServices,@JsonKey(name: 'slots_total') int slotsTotal,@JsonKey(name: 'slots_filled') int slotsFilled,@JsonKey(name: 'compensation_type') CompensationType compensationType,@JsonKey(name: 'compensation_value') int? compensationValue,@JsonKey(name: 'creator_id') String creatorId,@JsonKey(name: 'applicant_count') int applicantCount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'expires_at') DateTime? expiresAt
});




}
/// @nodoc
class _$GigCopyWithImpl<$Res>
    implements $GigCopyWith<$Res> {
  _$GigCopyWithImpl(this._self, this._then);

  final Gig _self;
  final $Res Function(Gig) _then;

/// Create a copy of Gig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? gigType = null,Object? status = null,Object? dateMode = null,Object? gigDate = freezed,Object? locationType = null,Object? location = freezed,Object? geohash = freezed,Object? genres = null,Object? requiredInstruments = null,Object? requiredCrewRoles = null,Object? requiredStudioServices = null,Object? slotsTotal = null,Object? slotsFilled = null,Object? compensationType = null,Object? compensationValue = freezed,Object? creatorId = null,Object? applicantCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gigType: null == gigType ? _self.gigType : gigType // ignore: cast_nullable_to_non_nullable
as GigType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GigStatus,dateMode: null == dateMode ? _self.dateMode : dateMode // ignore: cast_nullable_to_non_nullable
as GigDateMode,gigDate: freezed == gigDate ? _self.gigDate : gigDate // ignore: cast_nullable_to_non_nullable
as DateTime?,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as GigLocationType,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,geohash: freezed == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,requiredInstruments: null == requiredInstruments ? _self.requiredInstruments : requiredInstruments // ignore: cast_nullable_to_non_nullable
as List<String>,requiredCrewRoles: null == requiredCrewRoles ? _self.requiredCrewRoles : requiredCrewRoles // ignore: cast_nullable_to_non_nullable
as List<String>,requiredStudioServices: null == requiredStudioServices ? _self.requiredStudioServices : requiredStudioServices // ignore: cast_nullable_to_non_nullable
as List<String>,slotsTotal: null == slotsTotal ? _self.slotsTotal : slotsTotal // ignore: cast_nullable_to_non_nullable
as int,slotsFilled: null == slotsFilled ? _self.slotsFilled : slotsFilled // ignore: cast_nullable_to_non_nullable
as int,compensationType: null == compensationType ? _self.compensationType : compensationType // ignore: cast_nullable_to_non_nullable
as CompensationType,compensationValue: freezed == compensationValue ? _self.compensationValue : compensationValue // ignore: cast_nullable_to_non_nullable
as int?,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,applicantCount: null == applicantCount ? _self.applicantCount : applicantCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Gig].
extension GigPatterns on Gig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Gig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Gig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Gig value)  $default,){
final _that = this;
switch (_that) {
case _Gig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Gig value)?  $default,){
final _that = this;
switch (_that) {
case _Gig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description, @JsonKey(name: 'gig_type')  GigType gigType, @JsonKey(name: 'status')  GigStatus status, @JsonKey(name: 'date_mode')  GigDateMode dateMode, @JsonKey(name: 'gig_date')  DateTime? gigDate, @JsonKey(name: 'location_type')  GigLocationType locationType,  Map<String, dynamic>? location,  String? geohash,  List<String> genres, @JsonKey(name: 'required_instruments')  List<String> requiredInstruments, @JsonKey(name: 'required_crew_roles')  List<String> requiredCrewRoles, @JsonKey(name: 'required_studio_services')  List<String> requiredStudioServices, @JsonKey(name: 'slots_total')  int slotsTotal, @JsonKey(name: 'slots_filled')  int slotsFilled, @JsonKey(name: 'compensation_type')  CompensationType compensationType, @JsonKey(name: 'compensation_value')  int? compensationValue, @JsonKey(name: 'creator_id')  String creatorId, @JsonKey(name: 'applicant_count')  int applicantCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'expires_at')  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Gig() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.gigType,_that.status,_that.dateMode,_that.gigDate,_that.locationType,_that.location,_that.geohash,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.slotsFilled,_that.compensationType,_that.compensationValue,_that.creatorId,_that.applicantCount,_that.createdAt,_that.updatedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description, @JsonKey(name: 'gig_type')  GigType gigType, @JsonKey(name: 'status')  GigStatus status, @JsonKey(name: 'date_mode')  GigDateMode dateMode, @JsonKey(name: 'gig_date')  DateTime? gigDate, @JsonKey(name: 'location_type')  GigLocationType locationType,  Map<String, dynamic>? location,  String? geohash,  List<String> genres, @JsonKey(name: 'required_instruments')  List<String> requiredInstruments, @JsonKey(name: 'required_crew_roles')  List<String> requiredCrewRoles, @JsonKey(name: 'required_studio_services')  List<String> requiredStudioServices, @JsonKey(name: 'slots_total')  int slotsTotal, @JsonKey(name: 'slots_filled')  int slotsFilled, @JsonKey(name: 'compensation_type')  CompensationType compensationType, @JsonKey(name: 'compensation_value')  int? compensationValue, @JsonKey(name: 'creator_id')  String creatorId, @JsonKey(name: 'applicant_count')  int applicantCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'expires_at')  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _Gig():
return $default(_that.id,_that.title,_that.description,_that.gigType,_that.status,_that.dateMode,_that.gigDate,_that.locationType,_that.location,_that.geohash,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.slotsFilled,_that.compensationType,_that.compensationValue,_that.creatorId,_that.applicantCount,_that.createdAt,_that.updatedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description, @JsonKey(name: 'gig_type')  GigType gigType, @JsonKey(name: 'status')  GigStatus status, @JsonKey(name: 'date_mode')  GigDateMode dateMode, @JsonKey(name: 'gig_date')  DateTime? gigDate, @JsonKey(name: 'location_type')  GigLocationType locationType,  Map<String, dynamic>? location,  String? geohash,  List<String> genres, @JsonKey(name: 'required_instruments')  List<String> requiredInstruments, @JsonKey(name: 'required_crew_roles')  List<String> requiredCrewRoles, @JsonKey(name: 'required_studio_services')  List<String> requiredStudioServices, @JsonKey(name: 'slots_total')  int slotsTotal, @JsonKey(name: 'slots_filled')  int slotsFilled, @JsonKey(name: 'compensation_type')  CompensationType compensationType, @JsonKey(name: 'compensation_value')  int? compensationValue, @JsonKey(name: 'creator_id')  String creatorId, @JsonKey(name: 'applicant_count')  int applicantCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'expires_at')  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _Gig() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.gigType,_that.status,_that.dateMode,_that.gigDate,_that.locationType,_that.location,_that.geohash,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.slotsTotal,_that.slotsFilled,_that.compensationType,_that.compensationValue,_that.creatorId,_that.applicantCount,_that.createdAt,_that.updatedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Gig extends Gig {
  const _Gig({required this.id, required this.title, required this.description, @JsonKey(name: 'gig_type') required this.gigType, @JsonKey(name: 'status') required this.status, @JsonKey(name: 'date_mode') required this.dateMode, @JsonKey(name: 'gig_date') this.gigDate, @JsonKey(name: 'location_type') required this.locationType, final  Map<String, dynamic>? location, this.geohash, final  List<String> genres = const [], @JsonKey(name: 'required_instruments') final  List<String> requiredInstruments = const [], @JsonKey(name: 'required_crew_roles') final  List<String> requiredCrewRoles = const [], @JsonKey(name: 'required_studio_services') final  List<String> requiredStudioServices = const [], @JsonKey(name: 'slots_total') required this.slotsTotal, @JsonKey(name: 'slots_filled') this.slotsFilled = 0, @JsonKey(name: 'compensation_type') required this.compensationType, @JsonKey(name: 'compensation_value') this.compensationValue, @JsonKey(name: 'creator_id') required this.creatorId, @JsonKey(name: 'applicant_count') this.applicantCount = 0, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'expires_at') this.expiresAt}): _location = location,_genres = genres,_requiredInstruments = requiredInstruments,_requiredCrewRoles = requiredCrewRoles,_requiredStudioServices = requiredStudioServices,super._();
  factory _Gig.fromJson(Map<String, dynamic> json) => _$GigFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override@JsonKey(name: 'gig_type') final  GigType gigType;
@override@JsonKey(name: 'status') final  GigStatus status;
@override@JsonKey(name: 'date_mode') final  GigDateMode dateMode;
@override@JsonKey(name: 'gig_date') final  DateTime? gigDate;
@override@JsonKey(name: 'location_type') final  GigLocationType locationType;
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
@override@JsonKey(name: 'required_instruments') List<String> get requiredInstruments {
  if (_requiredInstruments is EqualUnmodifiableListView) return _requiredInstruments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredInstruments);
}

 final  List<String> _requiredCrewRoles;
@override@JsonKey(name: 'required_crew_roles') List<String> get requiredCrewRoles {
  if (_requiredCrewRoles is EqualUnmodifiableListView) return _requiredCrewRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredCrewRoles);
}

 final  List<String> _requiredStudioServices;
@override@JsonKey(name: 'required_studio_services') List<String> get requiredStudioServices {
  if (_requiredStudioServices is EqualUnmodifiableListView) return _requiredStudioServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredStudioServices);
}

@override@JsonKey(name: 'slots_total') final  int slotsTotal;
@override@JsonKey(name: 'slots_filled') final  int slotsFilled;
@override@JsonKey(name: 'compensation_type') final  CompensationType compensationType;
@override@JsonKey(name: 'compensation_value') final  int? compensationValue;
@override@JsonKey(name: 'creator_id') final  String creatorId;
@override@JsonKey(name: 'applicant_count') final  int applicantCount;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'expires_at') final  DateTime? expiresAt;

/// Create a copy of Gig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GigCopyWith<_Gig> get copyWith => __$GigCopyWithImpl<_Gig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Gig&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.gigType, gigType) || other.gigType == gigType)&&(identical(other.status, status) || other.status == status)&&(identical(other.dateMode, dateMode) || other.dateMode == dateMode)&&(identical(other.gigDate, gigDate) || other.gigDate == gigDate)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&const DeepCollectionEquality().equals(other._location, _location)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._requiredInstruments, _requiredInstruments)&&const DeepCollectionEquality().equals(other._requiredCrewRoles, _requiredCrewRoles)&&const DeepCollectionEquality().equals(other._requiredStudioServices, _requiredStudioServices)&&(identical(other.slotsTotal, slotsTotal) || other.slotsTotal == slotsTotal)&&(identical(other.slotsFilled, slotsFilled) || other.slotsFilled == slotsFilled)&&(identical(other.compensationType, compensationType) || other.compensationType == compensationType)&&(identical(other.compensationValue, compensationValue) || other.compensationValue == compensationValue)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId)&&(identical(other.applicantCount, applicantCount) || other.applicantCount == applicantCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,gigType,status,dateMode,gigDate,locationType,const DeepCollectionEquality().hash(_location),geohash,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_requiredInstruments),const DeepCollectionEquality().hash(_requiredCrewRoles),const DeepCollectionEquality().hash(_requiredStudioServices),slotsTotal,slotsFilled,compensationType,compensationValue,creatorId,applicantCount,createdAt,updatedAt,expiresAt]);

@override
String toString() {
  return 'Gig(id: $id, title: $title, description: $description, gigType: $gigType, status: $status, dateMode: $dateMode, gigDate: $gigDate, locationType: $locationType, location: $location, geohash: $geohash, genres: $genres, requiredInstruments: $requiredInstruments, requiredCrewRoles: $requiredCrewRoles, requiredStudioServices: $requiredStudioServices, slotsTotal: $slotsTotal, slotsFilled: $slotsFilled, compensationType: $compensationType, compensationValue: $compensationValue, creatorId: $creatorId, applicantCount: $applicantCount, createdAt: $createdAt, updatedAt: $updatedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$GigCopyWith<$Res> implements $GigCopyWith<$Res> {
  factory _$GigCopyWith(_Gig value, $Res Function(_Gig) _then) = __$GigCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description,@JsonKey(name: 'gig_type') GigType gigType,@JsonKey(name: 'status') GigStatus status,@JsonKey(name: 'date_mode') GigDateMode dateMode,@JsonKey(name: 'gig_date') DateTime? gigDate,@JsonKey(name: 'location_type') GigLocationType locationType, Map<String, dynamic>? location, String? geohash, List<String> genres,@JsonKey(name: 'required_instruments') List<String> requiredInstruments,@JsonKey(name: 'required_crew_roles') List<String> requiredCrewRoles,@JsonKey(name: 'required_studio_services') List<String> requiredStudioServices,@JsonKey(name: 'slots_total') int slotsTotal,@JsonKey(name: 'slots_filled') int slotsFilled,@JsonKey(name: 'compensation_type') CompensationType compensationType,@JsonKey(name: 'compensation_value') int? compensationValue,@JsonKey(name: 'creator_id') String creatorId,@JsonKey(name: 'applicant_count') int applicantCount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'expires_at') DateTime? expiresAt
});




}
/// @nodoc
class __$GigCopyWithImpl<$Res>
    implements _$GigCopyWith<$Res> {
  __$GigCopyWithImpl(this._self, this._then);

  final _Gig _self;
  final $Res Function(_Gig) _then;

/// Create a copy of Gig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? gigType = null,Object? status = null,Object? dateMode = null,Object? gigDate = freezed,Object? locationType = null,Object? location = freezed,Object? geohash = freezed,Object? genres = null,Object? requiredInstruments = null,Object? requiredCrewRoles = null,Object? requiredStudioServices = null,Object? slotsTotal = null,Object? slotsFilled = null,Object? compensationType = null,Object? compensationValue = freezed,Object? creatorId = null,Object? applicantCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? expiresAt = freezed,}) {
  return _then(_Gig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,gigType: null == gigType ? _self.gigType : gigType // ignore: cast_nullable_to_non_nullable
as GigType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GigStatus,dateMode: null == dateMode ? _self.dateMode : dateMode // ignore: cast_nullable_to_non_nullable
as GigDateMode,gigDate: freezed == gigDate ? _self.gigDate : gigDate // ignore: cast_nullable_to_non_nullable
as DateTime?,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as GigLocationType,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,geohash: freezed == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,requiredInstruments: null == requiredInstruments ? _self._requiredInstruments : requiredInstruments // ignore: cast_nullable_to_non_nullable
as List<String>,requiredCrewRoles: null == requiredCrewRoles ? _self._requiredCrewRoles : requiredCrewRoles // ignore: cast_nullable_to_non_nullable
as List<String>,requiredStudioServices: null == requiredStudioServices ? _self._requiredStudioServices : requiredStudioServices // ignore: cast_nullable_to_non_nullable
as List<String>,slotsTotal: null == slotsTotal ? _self.slotsTotal : slotsTotal // ignore: cast_nullable_to_non_nullable
as int,slotsFilled: null == slotsFilled ? _self.slotsFilled : slotsFilled // ignore: cast_nullable_to_non_nullable
as int,compensationType: null == compensationType ? _self.compensationType : compensationType // ignore: cast_nullable_to_non_nullable
as CompensationType,compensationValue: freezed == compensationValue ? _self.compensationValue : compensationValue // ignore: cast_nullable_to_non_nullable
as int?,creatorId: null == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String,applicantCount: null == applicantCount ? _self.applicantCount : applicantCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
