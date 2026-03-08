// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gig_review.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GigReview {

 String get id;@JsonKey(name: 'gig_id') String get gigId;@JsonKey(name: 'reviewer_id') String get reviewerId;@JsonKey(name: 'reviewed_user_id') String get reviewedUserId; int get rating; String? get comment;@JsonKey(name: 'review_type') ReviewType get reviewType;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of GigReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GigReviewCopyWith<GigReview> get copyWith => _$GigReviewCopyWithImpl<GigReview>(this as GigReview, _$identity);

  /// Serializes this GigReview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GigReview&&(identical(other.id, id) || other.id == id)&&(identical(other.gigId, gigId) || other.gigId == gigId)&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewedUserId, reviewedUserId) || other.reviewedUserId == reviewedUserId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.reviewType, reviewType) || other.reviewType == reviewType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gigId,reviewerId,reviewedUserId,rating,comment,reviewType,createdAt);

@override
String toString() {
  return 'GigReview(id: $id, gigId: $gigId, reviewerId: $reviewerId, reviewedUserId: $reviewedUserId, rating: $rating, comment: $comment, reviewType: $reviewType, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $GigReviewCopyWith<$Res>  {
  factory $GigReviewCopyWith(GigReview value, $Res Function(GigReview) _then) = _$GigReviewCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'gig_id') String gigId,@JsonKey(name: 'reviewer_id') String reviewerId,@JsonKey(name: 'reviewed_user_id') String reviewedUserId, int rating, String? comment,@JsonKey(name: 'review_type') ReviewType reviewType,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$GigReviewCopyWithImpl<$Res>
    implements $GigReviewCopyWith<$Res> {
  _$GigReviewCopyWithImpl(this._self, this._then);

  final GigReview _self;
  final $Res Function(GigReview) _then;

/// Create a copy of GigReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? gigId = null,Object? reviewerId = null,Object? reviewedUserId = null,Object? rating = null,Object? comment = freezed,Object? reviewType = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gigId: null == gigId ? _self.gigId : gigId // ignore: cast_nullable_to_non_nullable
as String,reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as String,reviewedUserId: null == reviewedUserId ? _self.reviewedUserId : reviewedUserId // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,reviewType: null == reviewType ? _self.reviewType : reviewType // ignore: cast_nullable_to_non_nullable
as ReviewType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GigReview].
extension GigReviewPatterns on GigReview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GigReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GigReview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GigReview value)  $default,){
final _that = this;
switch (_that) {
case _GigReview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GigReview value)?  $default,){
final _that = this;
switch (_that) {
case _GigReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'gig_id')  String gigId, @JsonKey(name: 'reviewer_id')  String reviewerId, @JsonKey(name: 'reviewed_user_id')  String reviewedUserId,  int rating,  String? comment, @JsonKey(name: 'review_type')  ReviewType reviewType, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GigReview() when $default != null:
return $default(_that.id,_that.gigId,_that.reviewerId,_that.reviewedUserId,_that.rating,_that.comment,_that.reviewType,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'gig_id')  String gigId, @JsonKey(name: 'reviewer_id')  String reviewerId, @JsonKey(name: 'reviewed_user_id')  String reviewedUserId,  int rating,  String? comment, @JsonKey(name: 'review_type')  ReviewType reviewType, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _GigReview():
return $default(_that.id,_that.gigId,_that.reviewerId,_that.reviewedUserId,_that.rating,_that.comment,_that.reviewType,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'gig_id')  String gigId, @JsonKey(name: 'reviewer_id')  String reviewerId, @JsonKey(name: 'reviewed_user_id')  String reviewedUserId,  int rating,  String? comment, @JsonKey(name: 'review_type')  ReviewType reviewType, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _GigReview() when $default != null:
return $default(_that.id,_that.gigId,_that.reviewerId,_that.reviewedUserId,_that.rating,_that.comment,_that.reviewType,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GigReview extends GigReview {
  const _GigReview({required this.id, @JsonKey(name: 'gig_id') required this.gigId, @JsonKey(name: 'reviewer_id') required this.reviewerId, @JsonKey(name: 'reviewed_user_id') required this.reviewedUserId, required this.rating, this.comment, @JsonKey(name: 'review_type') required this.reviewType, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _GigReview.fromJson(Map<String, dynamic> json) => _$GigReviewFromJson(json);

@override final  String id;
@override@JsonKey(name: 'gig_id') final  String gigId;
@override@JsonKey(name: 'reviewer_id') final  String reviewerId;
@override@JsonKey(name: 'reviewed_user_id') final  String reviewedUserId;
@override final  int rating;
@override final  String? comment;
@override@JsonKey(name: 'review_type') final  ReviewType reviewType;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of GigReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GigReviewCopyWith<_GigReview> get copyWith => __$GigReviewCopyWithImpl<_GigReview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GigReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GigReview&&(identical(other.id, id) || other.id == id)&&(identical(other.gigId, gigId) || other.gigId == gigId)&&(identical(other.reviewerId, reviewerId) || other.reviewerId == reviewerId)&&(identical(other.reviewedUserId, reviewedUserId) || other.reviewedUserId == reviewedUserId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.reviewType, reviewType) || other.reviewType == reviewType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gigId,reviewerId,reviewedUserId,rating,comment,reviewType,createdAt);

@override
String toString() {
  return 'GigReview(id: $id, gigId: $gigId, reviewerId: $reviewerId, reviewedUserId: $reviewedUserId, rating: $rating, comment: $comment, reviewType: $reviewType, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GigReviewCopyWith<$Res> implements $GigReviewCopyWith<$Res> {
  factory _$GigReviewCopyWith(_GigReview value, $Res Function(_GigReview) _then) = __$GigReviewCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'gig_id') String gigId,@JsonKey(name: 'reviewer_id') String reviewerId,@JsonKey(name: 'reviewed_user_id') String reviewedUserId, int rating, String? comment,@JsonKey(name: 'review_type') ReviewType reviewType,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$GigReviewCopyWithImpl<$Res>
    implements _$GigReviewCopyWith<$Res> {
  __$GigReviewCopyWithImpl(this._self, this._then);

  final _GigReview _self;
  final $Res Function(_GigReview) _then;

/// Create a copy of GigReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? gigId = null,Object? reviewerId = null,Object? reviewedUserId = null,Object? rating = null,Object? comment = freezed,Object? reviewType = null,Object? createdAt = freezed,}) {
  return _then(_GigReview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gigId: null == gigId ? _self.gigId : gigId // ignore: cast_nullable_to_non_nullable
as String,reviewerId: null == reviewerId ? _self.reviewerId : reviewerId // ignore: cast_nullable_to_non_nullable
as String,reviewedUserId: null == reviewedUserId ? _self.reviewedUserId : reviewedUserId // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,reviewType: null == reviewType ? _self.reviewType : reviewType // ignore: cast_nullable_to_non_nullable
as ReviewType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
