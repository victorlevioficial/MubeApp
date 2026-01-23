// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchFilters {

/// Text search term (normalized)
 String get term;/// Main category filter
 SearchCategory get category;/// Professional subcategory (singer, instrumentalist, crew, dj)
 ProfessionalSubcategory? get professionalSubcategory;/// Selected genres filter
 List<String> get genres;/// Selected instruments filter (for instrumentalists)
 List<String> get instruments;/// Selected crew roles filter (for crew)
 List<String> get roles;/// Selected studio services filter (for studios)
 List<String> get services;/// Filter for backing vocal capability
/// null = don't filter, true = must do backing, false = solo only
 bool? get canDoBackingVocal;/// Studio type filter (home_studio, commercial)
 String? get studioType;
/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchFiltersCopyWith<SearchFilters> get copyWith => _$SearchFiltersCopyWithImpl<SearchFilters>(this as SearchFilters, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchFilters&&(identical(other.term, term) || other.term == term)&&(identical(other.category, category) || other.category == category)&&(identical(other.professionalSubcategory, professionalSubcategory) || other.professionalSubcategory == professionalSubcategory)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.instruments, instruments)&&const DeepCollectionEquality().equals(other.roles, roles)&&const DeepCollectionEquality().equals(other.services, services)&&(identical(other.canDoBackingVocal, canDoBackingVocal) || other.canDoBackingVocal == canDoBackingVocal)&&(identical(other.studioType, studioType) || other.studioType == studioType));
}


@override
int get hashCode => Object.hash(runtimeType,term,category,professionalSubcategory,const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(instruments),const DeepCollectionEquality().hash(roles),const DeepCollectionEquality().hash(services),canDoBackingVocal,studioType);

@override
String toString() {
  return 'SearchFilters(term: $term, category: $category, professionalSubcategory: $professionalSubcategory, genres: $genres, instruments: $instruments, roles: $roles, services: $services, canDoBackingVocal: $canDoBackingVocal, studioType: $studioType)';
}


}

/// @nodoc
abstract mixin class $SearchFiltersCopyWith<$Res>  {
  factory $SearchFiltersCopyWith(SearchFilters value, $Res Function(SearchFilters) _then) = _$SearchFiltersCopyWithImpl;
@useResult
$Res call({
 String term, SearchCategory category, ProfessionalSubcategory? professionalSubcategory, List<String> genres, List<String> instruments, List<String> roles, List<String> services, bool? canDoBackingVocal, String? studioType
});




}
/// @nodoc
class _$SearchFiltersCopyWithImpl<$Res>
    implements $SearchFiltersCopyWith<$Res> {
  _$SearchFiltersCopyWithImpl(this._self, this._then);

  final SearchFilters _self;
  final $Res Function(SearchFilters) _then;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? term = null,Object? category = null,Object? professionalSubcategory = freezed,Object? genres = null,Object? instruments = null,Object? roles = null,Object? services = null,Object? canDoBackingVocal = freezed,Object? studioType = freezed,}) {
  return _then(_self.copyWith(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as SearchCategory,professionalSubcategory: freezed == professionalSubcategory ? _self.professionalSubcategory : professionalSubcategory // ignore: cast_nullable_to_non_nullable
as ProfessionalSubcategory?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,instruments: null == instruments ? _self.instruments : instruments // ignore: cast_nullable_to_non_nullable
as List<String>,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<String>,canDoBackingVocal: freezed == canDoBackingVocal ? _self.canDoBackingVocal : canDoBackingVocal // ignore: cast_nullable_to_non_nullable
as bool?,studioType: freezed == studioType ? _self.studioType : studioType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchFilters].
extension SearchFiltersPatterns on SearchFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchFilters value)  $default,){
final _that = this;
switch (_that) {
case _SearchFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchFilters value)?  $default,){
final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String term,  SearchCategory category,  ProfessionalSubcategory? professionalSubcategory,  List<String> genres,  List<String> instruments,  List<String> roles,  List<String> services,  bool? canDoBackingVocal,  String? studioType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
return $default(_that.term,_that.category,_that.professionalSubcategory,_that.genres,_that.instruments,_that.roles,_that.services,_that.canDoBackingVocal,_that.studioType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String term,  SearchCategory category,  ProfessionalSubcategory? professionalSubcategory,  List<String> genres,  List<String> instruments,  List<String> roles,  List<String> services,  bool? canDoBackingVocal,  String? studioType)  $default,) {final _that = this;
switch (_that) {
case _SearchFilters():
return $default(_that.term,_that.category,_that.professionalSubcategory,_that.genres,_that.instruments,_that.roles,_that.services,_that.canDoBackingVocal,_that.studioType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String term,  SearchCategory category,  ProfessionalSubcategory? professionalSubcategory,  List<String> genres,  List<String> instruments,  List<String> roles,  List<String> services,  bool? canDoBackingVocal,  String? studioType)?  $default,) {final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
return $default(_that.term,_that.category,_that.professionalSubcategory,_that.genres,_that.instruments,_that.roles,_that.services,_that.canDoBackingVocal,_that.studioType);case _:
  return null;

}
}

}

/// @nodoc


class _SearchFilters extends SearchFilters {
  const _SearchFilters({this.term = '', this.category = SearchCategory.all, this.professionalSubcategory, final  List<String> genres = const [], final  List<String> instruments = const [], final  List<String> roles = const [], final  List<String> services = const [], this.canDoBackingVocal, this.studioType}): _genres = genres,_instruments = instruments,_roles = roles,_services = services,super._();
  

/// Text search term (normalized)
@override@JsonKey() final  String term;
/// Main category filter
@override@JsonKey() final  SearchCategory category;
/// Professional subcategory (singer, instrumentalist, crew, dj)
@override final  ProfessionalSubcategory? professionalSubcategory;
/// Selected genres filter
 final  List<String> _genres;
/// Selected genres filter
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

/// Selected instruments filter (for instrumentalists)
 final  List<String> _instruments;
/// Selected instruments filter (for instrumentalists)
@override@JsonKey() List<String> get instruments {
  if (_instruments is EqualUnmodifiableListView) return _instruments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instruments);
}

/// Selected crew roles filter (for crew)
 final  List<String> _roles;
/// Selected crew roles filter (for crew)
@override@JsonKey() List<String> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

/// Selected studio services filter (for studios)
 final  List<String> _services;
/// Selected studio services filter (for studios)
@override@JsonKey() List<String> get services {
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_services);
}

/// Filter for backing vocal capability
/// null = don't filter, true = must do backing, false = solo only
@override final  bool? canDoBackingVocal;
/// Studio type filter (home_studio, commercial)
@override final  String? studioType;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchFiltersCopyWith<_SearchFilters> get copyWith => __$SearchFiltersCopyWithImpl<_SearchFilters>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchFilters&&(identical(other.term, term) || other.term == term)&&(identical(other.category, category) || other.category == category)&&(identical(other.professionalSubcategory, professionalSubcategory) || other.professionalSubcategory == professionalSubcategory)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._instruments, _instruments)&&const DeepCollectionEquality().equals(other._roles, _roles)&&const DeepCollectionEquality().equals(other._services, _services)&&(identical(other.canDoBackingVocal, canDoBackingVocal) || other.canDoBackingVocal == canDoBackingVocal)&&(identical(other.studioType, studioType) || other.studioType == studioType));
}


@override
int get hashCode => Object.hash(runtimeType,term,category,professionalSubcategory,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_instruments),const DeepCollectionEquality().hash(_roles),const DeepCollectionEquality().hash(_services),canDoBackingVocal,studioType);

@override
String toString() {
  return 'SearchFilters(term: $term, category: $category, professionalSubcategory: $professionalSubcategory, genres: $genres, instruments: $instruments, roles: $roles, services: $services, canDoBackingVocal: $canDoBackingVocal, studioType: $studioType)';
}


}

/// @nodoc
abstract mixin class _$SearchFiltersCopyWith<$Res> implements $SearchFiltersCopyWith<$Res> {
  factory _$SearchFiltersCopyWith(_SearchFilters value, $Res Function(_SearchFilters) _then) = __$SearchFiltersCopyWithImpl;
@override @useResult
$Res call({
 String term, SearchCategory category, ProfessionalSubcategory? professionalSubcategory, List<String> genres, List<String> instruments, List<String> roles, List<String> services, bool? canDoBackingVocal, String? studioType
});




}
/// @nodoc
class __$SearchFiltersCopyWithImpl<$Res>
    implements _$SearchFiltersCopyWith<$Res> {
  __$SearchFiltersCopyWithImpl(this._self, this._then);

  final _SearchFilters _self;
  final $Res Function(_SearchFilters) _then;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? term = null,Object? category = null,Object? professionalSubcategory = freezed,Object? genres = null,Object? instruments = null,Object? roles = null,Object? services = null,Object? canDoBackingVocal = freezed,Object? studioType = freezed,}) {
  return _then(_SearchFilters(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as SearchCategory,professionalSubcategory: freezed == professionalSubcategory ? _self.professionalSubcategory : professionalSubcategory // ignore: cast_nullable_to_non_nullable
as ProfessionalSubcategory?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,instruments: null == instruments ? _self._instruments : instruments // ignore: cast_nullable_to_non_nullable
as List<String>,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<String>,canDoBackingVocal: freezed == canDoBackingVocal ? _self.canDoBackingVocal : canDoBackingVocal // ignore: cast_nullable_to_non_nullable
as bool?,studioType: freezed == studioType ? _self.studioType : studioType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
