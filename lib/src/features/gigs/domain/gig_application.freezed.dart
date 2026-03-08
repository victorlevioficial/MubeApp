// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gig_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GigApplication {

 String get id; String get gigId;@JsonKey(name: 'applicant_id') String get applicantId; String get message; ApplicationStatus get status;@JsonKey(name: 'applied_at') DateTime? get appliedAt;@JsonKey(name: 'responded_at') DateTime? get respondedAt; String? get gigTitle; GigType? get gigType; GigStatus? get gigStatus; String? get creatorId;
/// Create a copy of GigApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GigApplicationCopyWith<GigApplication> get copyWith => _$GigApplicationCopyWithImpl<GigApplication>(this as GigApplication, _$identity);

  /// Serializes this GigApplication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GigApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.gigId, gigId) || other.gigId == gigId)&&(identical(other.applicantId, applicantId) || other.applicantId == applicantId)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.gigTitle, gigTitle) || other.gigTitle == gigTitle)&&(identical(other.gigType, gigType) || other.gigType == gigType)&&(identical(other.gigStatus, gigStatus) || other.gigStatus == gigStatus)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gigId,applicantId,message,status,appliedAt,respondedAt,gigTitle,gigType,gigStatus,creatorId);

@override
String toString() {
  return 'GigApplication(id: $id, gigId: $gigId, applicantId: $applicantId, message: $message, status: $status, appliedAt: $appliedAt, respondedAt: $respondedAt, gigTitle: $gigTitle, gigType: $gigType, gigStatus: $gigStatus, creatorId: $creatorId)';
}


}

/// @nodoc
abstract mixin class $GigApplicationCopyWith<$Res>  {
  factory $GigApplicationCopyWith(GigApplication value, $Res Function(GigApplication) _then) = _$GigApplicationCopyWithImpl;
@useResult
$Res call({
 String id, String gigId,@JsonKey(name: 'applicant_id') String applicantId, String message, ApplicationStatus status,@JsonKey(name: 'applied_at') DateTime? appliedAt,@JsonKey(name: 'responded_at') DateTime? respondedAt, String? gigTitle, GigType? gigType, GigStatus? gigStatus, String? creatorId
});




}
/// @nodoc
class _$GigApplicationCopyWithImpl<$Res>
    implements $GigApplicationCopyWith<$Res> {
  _$GigApplicationCopyWithImpl(this._self, this._then);

  final GigApplication _self;
  final $Res Function(GigApplication) _then;

/// Create a copy of GigApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? gigId = null,Object? applicantId = null,Object? message = null,Object? status = null,Object? appliedAt = freezed,Object? respondedAt = freezed,Object? gigTitle = freezed,Object? gigType = freezed,Object? gigStatus = freezed,Object? creatorId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gigId: null == gigId ? _self.gigId : gigId // ignore: cast_nullable_to_non_nullable
as String,applicantId: null == applicantId ? _self.applicantId : applicantId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApplicationStatus,appliedAt: freezed == appliedAt ? _self.appliedAt : appliedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,gigTitle: freezed == gigTitle ? _self.gigTitle : gigTitle // ignore: cast_nullable_to_non_nullable
as String?,gigType: freezed == gigType ? _self.gigType : gigType // ignore: cast_nullable_to_non_nullable
as GigType?,gigStatus: freezed == gigStatus ? _self.gigStatus : gigStatus // ignore: cast_nullable_to_non_nullable
as GigStatus?,creatorId: freezed == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GigApplication].
extension GigApplicationPatterns on GigApplication {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GigApplication value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GigApplication() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GigApplication value)  $default,){
final _that = this;
switch (_that) {
case _GigApplication():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GigApplication value)?  $default,){
final _that = this;
switch (_that) {
case _GigApplication() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String gigId, @JsonKey(name: 'applicant_id')  String applicantId,  String message,  ApplicationStatus status, @JsonKey(name: 'applied_at')  DateTime? appliedAt, @JsonKey(name: 'responded_at')  DateTime? respondedAt,  String? gigTitle,  GigType? gigType,  GigStatus? gigStatus,  String? creatorId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GigApplication() when $default != null:
return $default(_that.id,_that.gigId,_that.applicantId,_that.message,_that.status,_that.appliedAt,_that.respondedAt,_that.gigTitle,_that.gigType,_that.gigStatus,_that.creatorId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String gigId, @JsonKey(name: 'applicant_id')  String applicantId,  String message,  ApplicationStatus status, @JsonKey(name: 'applied_at')  DateTime? appliedAt, @JsonKey(name: 'responded_at')  DateTime? respondedAt,  String? gigTitle,  GigType? gigType,  GigStatus? gigStatus,  String? creatorId)  $default,) {final _that = this;
switch (_that) {
case _GigApplication():
return $default(_that.id,_that.gigId,_that.applicantId,_that.message,_that.status,_that.appliedAt,_that.respondedAt,_that.gigTitle,_that.gigType,_that.gigStatus,_that.creatorId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String gigId, @JsonKey(name: 'applicant_id')  String applicantId,  String message,  ApplicationStatus status, @JsonKey(name: 'applied_at')  DateTime? appliedAt, @JsonKey(name: 'responded_at')  DateTime? respondedAt,  String? gigTitle,  GigType? gigType,  GigStatus? gigStatus,  String? creatorId)?  $default,) {final _that = this;
switch (_that) {
case _GigApplication() when $default != null:
return $default(_that.id,_that.gigId,_that.applicantId,_that.message,_that.status,_that.appliedAt,_that.respondedAt,_that.gigTitle,_that.gigType,_that.gigStatus,_that.creatorId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GigApplication extends GigApplication {
  const _GigApplication({required this.id, required this.gigId, @JsonKey(name: 'applicant_id') required this.applicantId, required this.message, required this.status, @JsonKey(name: 'applied_at') this.appliedAt, @JsonKey(name: 'responded_at') this.respondedAt, this.gigTitle, this.gigType, this.gigStatus, this.creatorId}): super._();
  factory _GigApplication.fromJson(Map<String, dynamic> json) => _$GigApplicationFromJson(json);

@override final  String id;
@override final  String gigId;
@override@JsonKey(name: 'applicant_id') final  String applicantId;
@override final  String message;
@override final  ApplicationStatus status;
@override@JsonKey(name: 'applied_at') final  DateTime? appliedAt;
@override@JsonKey(name: 'responded_at') final  DateTime? respondedAt;
@override final  String? gigTitle;
@override final  GigType? gigType;
@override final  GigStatus? gigStatus;
@override final  String? creatorId;

/// Create a copy of GigApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GigApplicationCopyWith<_GigApplication> get copyWith => __$GigApplicationCopyWithImpl<_GigApplication>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GigApplicationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GigApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.gigId, gigId) || other.gigId == gigId)&&(identical(other.applicantId, applicantId) || other.applicantId == applicantId)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.gigTitle, gigTitle) || other.gigTitle == gigTitle)&&(identical(other.gigType, gigType) || other.gigType == gigType)&&(identical(other.gigStatus, gigStatus) || other.gigStatus == gigStatus)&&(identical(other.creatorId, creatorId) || other.creatorId == creatorId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gigId,applicantId,message,status,appliedAt,respondedAt,gigTitle,gigType,gigStatus,creatorId);

@override
String toString() {
  return 'GigApplication(id: $id, gigId: $gigId, applicantId: $applicantId, message: $message, status: $status, appliedAt: $appliedAt, respondedAt: $respondedAt, gigTitle: $gigTitle, gigType: $gigType, gigStatus: $gigStatus, creatorId: $creatorId)';
}


}

/// @nodoc
abstract mixin class _$GigApplicationCopyWith<$Res> implements $GigApplicationCopyWith<$Res> {
  factory _$GigApplicationCopyWith(_GigApplication value, $Res Function(_GigApplication) _then) = __$GigApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String gigId,@JsonKey(name: 'applicant_id') String applicantId, String message, ApplicationStatus status,@JsonKey(name: 'applied_at') DateTime? appliedAt,@JsonKey(name: 'responded_at') DateTime? respondedAt, String? gigTitle, GigType? gigType, GigStatus? gigStatus, String? creatorId
});




}
/// @nodoc
class __$GigApplicationCopyWithImpl<$Res>
    implements _$GigApplicationCopyWith<$Res> {
  __$GigApplicationCopyWithImpl(this._self, this._then);

  final _GigApplication _self;
  final $Res Function(_GigApplication) _then;

/// Create a copy of GigApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? gigId = null,Object? applicantId = null,Object? message = null,Object? status = null,Object? appliedAt = freezed,Object? respondedAt = freezed,Object? gigTitle = freezed,Object? gigType = freezed,Object? gigStatus = freezed,Object? creatorId = freezed,}) {
  return _then(_GigApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gigId: null == gigId ? _self.gigId : gigId // ignore: cast_nullable_to_non_nullable
as String,applicantId: null == applicantId ? _self.applicantId : applicantId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ApplicationStatus,appliedAt: freezed == appliedAt ? _self.appliedAt : appliedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,gigTitle: freezed == gigTitle ? _self.gigTitle : gigTitle // ignore: cast_nullable_to_non_nullable
as String?,gigType: freezed == gigType ? _self.gigType : gigType // ignore: cast_nullable_to_non_nullable
as GigType?,gigStatus: freezed == gigStatus ? _self.gigStatus : gigStatus // ignore: cast_nullable_to_non_nullable
as GigStatus?,creatorId: freezed == creatorId ? _self.creatorId : creatorId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
