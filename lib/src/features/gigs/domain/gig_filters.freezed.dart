// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gig_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GigFilters {

 String get term; List<GigStatus> get statuses; List<GigType> get gigTypes; List<GigLocationType> get locationTypes; List<CompensationType> get compensationTypes; List<String> get genres; List<String> get requiredInstruments; List<String> get requiredCrewRoles; List<String> get requiredStudioServices; bool get onlyOpenSlots; bool get onlyMine;
/// Create a copy of GigFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GigFiltersCopyWith<GigFilters> get copyWith => _$GigFiltersCopyWithImpl<GigFilters>(this as GigFilters, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GigFilters&&(identical(other.term, term) || other.term == term)&&const DeepCollectionEquality().equals(other.statuses, statuses)&&const DeepCollectionEquality().equals(other.gigTypes, gigTypes)&&const DeepCollectionEquality().equals(other.locationTypes, locationTypes)&&const DeepCollectionEquality().equals(other.compensationTypes, compensationTypes)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.requiredInstruments, requiredInstruments)&&const DeepCollectionEquality().equals(other.requiredCrewRoles, requiredCrewRoles)&&const DeepCollectionEquality().equals(other.requiredStudioServices, requiredStudioServices)&&(identical(other.onlyOpenSlots, onlyOpenSlots) || other.onlyOpenSlots == onlyOpenSlots)&&(identical(other.onlyMine, onlyMine) || other.onlyMine == onlyMine));
}


@override
int get hashCode => Object.hash(runtimeType,term,const DeepCollectionEquality().hash(statuses),const DeepCollectionEquality().hash(gigTypes),const DeepCollectionEquality().hash(locationTypes),const DeepCollectionEquality().hash(compensationTypes),const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(requiredInstruments),const DeepCollectionEquality().hash(requiredCrewRoles),const DeepCollectionEquality().hash(requiredStudioServices),onlyOpenSlots,onlyMine);

@override
String toString() {
  return 'GigFilters(term: $term, statuses: $statuses, gigTypes: $gigTypes, locationTypes: $locationTypes, compensationTypes: $compensationTypes, genres: $genres, requiredInstruments: $requiredInstruments, requiredCrewRoles: $requiredCrewRoles, requiredStudioServices: $requiredStudioServices, onlyOpenSlots: $onlyOpenSlots, onlyMine: $onlyMine)';
}


}

/// @nodoc
abstract mixin class $GigFiltersCopyWith<$Res>  {
  factory $GigFiltersCopyWith(GigFilters value, $Res Function(GigFilters) _then) = _$GigFiltersCopyWithImpl;
@useResult
$Res call({
 String term, List<GigStatus> statuses, List<GigType> gigTypes, List<GigLocationType> locationTypes, List<CompensationType> compensationTypes, List<String> genres, List<String> requiredInstruments, List<String> requiredCrewRoles, List<String> requiredStudioServices, bool onlyOpenSlots, bool onlyMine
});




}
/// @nodoc
class _$GigFiltersCopyWithImpl<$Res>
    implements $GigFiltersCopyWith<$Res> {
  _$GigFiltersCopyWithImpl(this._self, this._then);

  final GigFilters _self;
  final $Res Function(GigFilters) _then;

/// Create a copy of GigFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? term = null,Object? statuses = null,Object? gigTypes = null,Object? locationTypes = null,Object? compensationTypes = null,Object? genres = null,Object? requiredInstruments = null,Object? requiredCrewRoles = null,Object? requiredStudioServices = null,Object? onlyOpenSlots = null,Object? onlyMine = null,}) {
  return _then(_self.copyWith(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<GigStatus>,gigTypes: null == gigTypes ? _self.gigTypes : gigTypes // ignore: cast_nullable_to_non_nullable
as List<GigType>,locationTypes: null == locationTypes ? _self.locationTypes : locationTypes // ignore: cast_nullable_to_non_nullable
as List<GigLocationType>,compensationTypes: null == compensationTypes ? _self.compensationTypes : compensationTypes // ignore: cast_nullable_to_non_nullable
as List<CompensationType>,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,requiredInstruments: null == requiredInstruments ? _self.requiredInstruments : requiredInstruments // ignore: cast_nullable_to_non_nullable
as List<String>,requiredCrewRoles: null == requiredCrewRoles ? _self.requiredCrewRoles : requiredCrewRoles // ignore: cast_nullable_to_non_nullable
as List<String>,requiredStudioServices: null == requiredStudioServices ? _self.requiredStudioServices : requiredStudioServices // ignore: cast_nullable_to_non_nullable
as List<String>,onlyOpenSlots: null == onlyOpenSlots ? _self.onlyOpenSlots : onlyOpenSlots // ignore: cast_nullable_to_non_nullable
as bool,onlyMine: null == onlyMine ? _self.onlyMine : onlyMine // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GigFilters].
extension GigFiltersPatterns on GigFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GigFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GigFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GigFilters value)  $default,){
final _that = this;
switch (_that) {
case _GigFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GigFilters value)?  $default,){
final _that = this;
switch (_that) {
case _GigFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String term,  List<GigStatus> statuses,  List<GigType> gigTypes,  List<GigLocationType> locationTypes,  List<CompensationType> compensationTypes,  List<String> genres,  List<String> requiredInstruments,  List<String> requiredCrewRoles,  List<String> requiredStudioServices,  bool onlyOpenSlots,  bool onlyMine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GigFilters() when $default != null:
return $default(_that.term,_that.statuses,_that.gigTypes,_that.locationTypes,_that.compensationTypes,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.onlyOpenSlots,_that.onlyMine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String term,  List<GigStatus> statuses,  List<GigType> gigTypes,  List<GigLocationType> locationTypes,  List<CompensationType> compensationTypes,  List<String> genres,  List<String> requiredInstruments,  List<String> requiredCrewRoles,  List<String> requiredStudioServices,  bool onlyOpenSlots,  bool onlyMine)  $default,) {final _that = this;
switch (_that) {
case _GigFilters():
return $default(_that.term,_that.statuses,_that.gigTypes,_that.locationTypes,_that.compensationTypes,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.onlyOpenSlots,_that.onlyMine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String term,  List<GigStatus> statuses,  List<GigType> gigTypes,  List<GigLocationType> locationTypes,  List<CompensationType> compensationTypes,  List<String> genres,  List<String> requiredInstruments,  List<String> requiredCrewRoles,  List<String> requiredStudioServices,  bool onlyOpenSlots,  bool onlyMine)?  $default,) {final _that = this;
switch (_that) {
case _GigFilters() when $default != null:
return $default(_that.term,_that.statuses,_that.gigTypes,_that.locationTypes,_that.compensationTypes,_that.genres,_that.requiredInstruments,_that.requiredCrewRoles,_that.requiredStudioServices,_that.onlyOpenSlots,_that.onlyMine);case _:
  return null;

}
}

}

/// @nodoc


class _GigFilters extends GigFilters {
  const _GigFilters({this.term = '', final  List<GigStatus> statuses = const [GigStatus.open], final  List<GigType> gigTypes = const [], final  List<GigLocationType> locationTypes = const [], final  List<CompensationType> compensationTypes = const [], final  List<String> genres = const [], final  List<String> requiredInstruments = const [], final  List<String> requiredCrewRoles = const [], final  List<String> requiredStudioServices = const [], this.onlyOpenSlots = true, this.onlyMine = false}): _statuses = statuses,_gigTypes = gigTypes,_locationTypes = locationTypes,_compensationTypes = compensationTypes,_genres = genres,_requiredInstruments = requiredInstruments,_requiredCrewRoles = requiredCrewRoles,_requiredStudioServices = requiredStudioServices,super._();
  

@override@JsonKey() final  String term;
 final  List<GigStatus> _statuses;
@override@JsonKey() List<GigStatus> get statuses {
  if (_statuses is EqualUnmodifiableListView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statuses);
}

 final  List<GigType> _gigTypes;
@override@JsonKey() List<GigType> get gigTypes {
  if (_gigTypes is EqualUnmodifiableListView) return _gigTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gigTypes);
}

 final  List<GigLocationType> _locationTypes;
@override@JsonKey() List<GigLocationType> get locationTypes {
  if (_locationTypes is EqualUnmodifiableListView) return _locationTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_locationTypes);
}

 final  List<CompensationType> _compensationTypes;
@override@JsonKey() List<CompensationType> get compensationTypes {
  if (_compensationTypes is EqualUnmodifiableListView) return _compensationTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_compensationTypes);
}

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

@override@JsonKey() final  bool onlyOpenSlots;
@override@JsonKey() final  bool onlyMine;

/// Create a copy of GigFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GigFiltersCopyWith<_GigFilters> get copyWith => __$GigFiltersCopyWithImpl<_GigFilters>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GigFilters&&(identical(other.term, term) || other.term == term)&&const DeepCollectionEquality().equals(other._statuses, _statuses)&&const DeepCollectionEquality().equals(other._gigTypes, _gigTypes)&&const DeepCollectionEquality().equals(other._locationTypes, _locationTypes)&&const DeepCollectionEquality().equals(other._compensationTypes, _compensationTypes)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._requiredInstruments, _requiredInstruments)&&const DeepCollectionEquality().equals(other._requiredCrewRoles, _requiredCrewRoles)&&const DeepCollectionEquality().equals(other._requiredStudioServices, _requiredStudioServices)&&(identical(other.onlyOpenSlots, onlyOpenSlots) || other.onlyOpenSlots == onlyOpenSlots)&&(identical(other.onlyMine, onlyMine) || other.onlyMine == onlyMine));
}


@override
int get hashCode => Object.hash(runtimeType,term,const DeepCollectionEquality().hash(_statuses),const DeepCollectionEquality().hash(_gigTypes),const DeepCollectionEquality().hash(_locationTypes),const DeepCollectionEquality().hash(_compensationTypes),const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_requiredInstruments),const DeepCollectionEquality().hash(_requiredCrewRoles),const DeepCollectionEquality().hash(_requiredStudioServices),onlyOpenSlots,onlyMine);

@override
String toString() {
  return 'GigFilters(term: $term, statuses: $statuses, gigTypes: $gigTypes, locationTypes: $locationTypes, compensationTypes: $compensationTypes, genres: $genres, requiredInstruments: $requiredInstruments, requiredCrewRoles: $requiredCrewRoles, requiredStudioServices: $requiredStudioServices, onlyOpenSlots: $onlyOpenSlots, onlyMine: $onlyMine)';
}


}

/// @nodoc
abstract mixin class _$GigFiltersCopyWith<$Res> implements $GigFiltersCopyWith<$Res> {
  factory _$GigFiltersCopyWith(_GigFilters value, $Res Function(_GigFilters) _then) = __$GigFiltersCopyWithImpl;
@override @useResult
$Res call({
 String term, List<GigStatus> statuses, List<GigType> gigTypes, List<GigLocationType> locationTypes, List<CompensationType> compensationTypes, List<String> genres, List<String> requiredInstruments, List<String> requiredCrewRoles, List<String> requiredStudioServices, bool onlyOpenSlots, bool onlyMine
});




}
/// @nodoc
class __$GigFiltersCopyWithImpl<$Res>
    implements _$GigFiltersCopyWith<$Res> {
  __$GigFiltersCopyWithImpl(this._self, this._then);

  final _GigFilters _self;
  final $Res Function(_GigFilters) _then;

/// Create a copy of GigFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? term = null,Object? statuses = null,Object? gigTypes = null,Object? locationTypes = null,Object? compensationTypes = null,Object? genres = null,Object? requiredInstruments = null,Object? requiredCrewRoles = null,Object? requiredStudioServices = null,Object? onlyOpenSlots = null,Object? onlyMine = null,}) {
  return _then(_GigFilters(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<GigStatus>,gigTypes: null == gigTypes ? _self._gigTypes : gigTypes // ignore: cast_nullable_to_non_nullable
as List<GigType>,locationTypes: null == locationTypes ? _self._locationTypes : locationTypes // ignore: cast_nullable_to_non_nullable
as List<GigLocationType>,compensationTypes: null == compensationTypes ? _self._compensationTypes : compensationTypes // ignore: cast_nullable_to_non_nullable
as List<CompensationType>,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,requiredInstruments: null == requiredInstruments ? _self._requiredInstruments : requiredInstruments // ignore: cast_nullable_to_non_nullable
as List<String>,requiredCrewRoles: null == requiredCrewRoles ? _self._requiredCrewRoles : requiredCrewRoles // ignore: cast_nullable_to_non_nullable
as List<String>,requiredStudioServices: null == requiredStudioServices ? _self._requiredStudioServices : requiredStudioServices // ignore: cast_nullable_to_non_nullable
as List<String>,onlyOpenSlots: null == onlyOpenSlots ? _self.onlyOpenSlots : onlyOpenSlots // ignore: cast_nullable_to_non_nullable
as bool,onlyMine: null == onlyMine ? _self.onlyMine : onlyMine // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
