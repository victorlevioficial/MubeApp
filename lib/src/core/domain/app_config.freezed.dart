// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConfigItem {

 String get id; String get label; int get order; String? get icon; List<String> get aliases;
/// Create a copy of ConfigItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfigItemCopyWith<ConfigItem> get copyWith => _$ConfigItemCopyWithImpl<ConfigItem>(this as ConfigItem, _$identity);

  /// Serializes this ConfigItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConfigItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.order, order) || other.order == order)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other.aliases, aliases));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,order,icon,const DeepCollectionEquality().hash(aliases));

@override
String toString() {
  return 'ConfigItem(id: $id, label: $label, order: $order, icon: $icon, aliases: $aliases)';
}


}

/// @nodoc
abstract mixin class $ConfigItemCopyWith<$Res>  {
  factory $ConfigItemCopyWith(ConfigItem value, $Res Function(ConfigItem) _then) = _$ConfigItemCopyWithImpl;
@useResult
$Res call({
 String id, String label, int order, String? icon, List<String> aliases
});




}
/// @nodoc
class _$ConfigItemCopyWithImpl<$Res>
    implements $ConfigItemCopyWith<$Res> {
  _$ConfigItemCopyWithImpl(this._self, this._then);

  final ConfigItem _self;
  final $Res Function(ConfigItem) _then;

/// Create a copy of ConfigItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? order = null,Object? icon = freezed,Object? aliases = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ConfigItem].
extension ConfigItemPatterns on ConfigItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConfigItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConfigItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConfigItem value)  $default,){
final _that = this;
switch (_that) {
case _ConfigItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConfigItem value)?  $default,){
final _that = this;
switch (_that) {
case _ConfigItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  int order,  String? icon,  List<String> aliases)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConfigItem() when $default != null:
return $default(_that.id,_that.label,_that.order,_that.icon,_that.aliases);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  int order,  String? icon,  List<String> aliases)  $default,) {final _that = this;
switch (_that) {
case _ConfigItem():
return $default(_that.id,_that.label,_that.order,_that.icon,_that.aliases);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  int order,  String? icon,  List<String> aliases)?  $default,) {final _that = this;
switch (_that) {
case _ConfigItem() when $default != null:
return $default(_that.id,_that.label,_that.order,_that.icon,_that.aliases);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConfigItem implements ConfigItem {
  const _ConfigItem({required this.id, required this.label, this.order = 0, this.icon, final  List<String> aliases = const []}): _aliases = aliases;
  factory _ConfigItem.fromJson(Map<String, dynamic> json) => _$ConfigItemFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey() final  int order;
@override final  String? icon;
 final  List<String> _aliases;
@override@JsonKey() List<String> get aliases {
  if (_aliases is EqualUnmodifiableListView) return _aliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aliases);
}


/// Create a copy of ConfigItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfigItemCopyWith<_ConfigItem> get copyWith => __$ConfigItemCopyWithImpl<_ConfigItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConfigItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfigItem&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.order, order) || other.order == order)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other._aliases, _aliases));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,order,icon,const DeepCollectionEquality().hash(_aliases));

@override
String toString() {
  return 'ConfigItem(id: $id, label: $label, order: $order, icon: $icon, aliases: $aliases)';
}


}

/// @nodoc
abstract mixin class _$ConfigItemCopyWith<$Res> implements $ConfigItemCopyWith<$Res> {
  factory _$ConfigItemCopyWith(_ConfigItem value, $Res Function(_ConfigItem) _then) = __$ConfigItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, int order, String? icon, List<String> aliases
});




}
/// @nodoc
class __$ConfigItemCopyWithImpl<$Res>
    implements _$ConfigItemCopyWith<$Res> {
  __$ConfigItemCopyWithImpl(this._self, this._then);

  final _ConfigItem _self;
  final $Res Function(_ConfigItem) _then;

/// Create a copy of ConfigItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? order = null,Object? icon = freezed,Object? aliases = null,}) {
  return _then(_ConfigItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$AppConfig {

 int get version; List<ConfigItem> get genres; List<ConfigItem> get instruments; List<ConfigItem> get crewRoles; List<ConfigItem> get studioServices; List<ConfigItem> get professionalCategories;
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCopyWith<AppConfig> get copyWith => _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);

  /// Serializes this AppConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfig&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.instruments, instruments)&&const DeepCollectionEquality().equals(other.crewRoles, crewRoles)&&const DeepCollectionEquality().equals(other.studioServices, studioServices)&&const DeepCollectionEquality().equals(other.professionalCategories, professionalCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(instruments),const DeepCollectionEquality().hash(crewRoles),const DeepCollectionEquality().hash(studioServices),const DeepCollectionEquality().hash(professionalCategories));

@override
String toString() {
  return 'AppConfig(version: $version, genres: $genres, instruments: $instruments, crewRoles: $crewRoles, studioServices: $studioServices, professionalCategories: $professionalCategories)';
}


}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res>  {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) = _$AppConfigCopyWithImpl;
@useResult
$Res call({
 int version, List<ConfigItem> genres, List<ConfigItem> instruments, List<ConfigItem> crewRoles, List<ConfigItem> studioServices, List<ConfigItem> professionalCategories
});




}
/// @nodoc
class _$AppConfigCopyWithImpl<$Res>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? genres = null,Object? instruments = null,Object? crewRoles = null,Object? studioServices = null,Object? professionalCategories = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,instruments: null == instruments ? _self.instruments : instruments // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,crewRoles: null == crewRoles ? _self.crewRoles : crewRoles // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,studioServices: null == studioServices ? _self.studioServices : studioServices // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,professionalCategories: null == professionalCategories ? _self.professionalCategories : professionalCategories // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfig].
extension AppConfigPatterns on AppConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppConfig value)  $default,){
final _that = this;
switch (_that) {
case _AppConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  List<ConfigItem> genres,  List<ConfigItem> instruments,  List<ConfigItem> crewRoles,  List<ConfigItem> studioServices,  List<ConfigItem> professionalCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.version,_that.genres,_that.instruments,_that.crewRoles,_that.studioServices,_that.professionalCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  List<ConfigItem> genres,  List<ConfigItem> instruments,  List<ConfigItem> crewRoles,  List<ConfigItem> studioServices,  List<ConfigItem> professionalCategories)  $default,) {final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that.version,_that.genres,_that.instruments,_that.crewRoles,_that.studioServices,_that.professionalCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  List<ConfigItem> genres,  List<ConfigItem> instruments,  List<ConfigItem> crewRoles,  List<ConfigItem> studioServices,  List<ConfigItem> professionalCategories)?  $default,) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.version,_that.genres,_that.instruments,_that.crewRoles,_that.studioServices,_that.professionalCategories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppConfig implements AppConfig {
  const _AppConfig({this.version = 0, final  List<ConfigItem> genres = const [], final  List<ConfigItem> instruments = const [], final  List<ConfigItem> crewRoles = const [], final  List<ConfigItem> studioServices = const [], final  List<ConfigItem> professionalCategories = const []}): _genres = genres,_instruments = instruments,_crewRoles = crewRoles,_studioServices = studioServices,_professionalCategories = professionalCategories;
  factory _AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);

@override@JsonKey() final  int version;
 final  List<ConfigItem> _genres;
@override@JsonKey() List<ConfigItem> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

 final  List<ConfigItem> _instruments;
@override@JsonKey() List<ConfigItem> get instruments {
  if (_instruments is EqualUnmodifiableListView) return _instruments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_instruments);
}

 final  List<ConfigItem> _crewRoles;
@override@JsonKey() List<ConfigItem> get crewRoles {
  if (_crewRoles is EqualUnmodifiableListView) return _crewRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_crewRoles);
}

 final  List<ConfigItem> _studioServices;
@override@JsonKey() List<ConfigItem> get studioServices {
  if (_studioServices is EqualUnmodifiableListView) return _studioServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_studioServices);
}

 final  List<ConfigItem> _professionalCategories;
@override@JsonKey() List<ConfigItem> get professionalCategories {
  if (_professionalCategories is EqualUnmodifiableListView) return _professionalCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_professionalCategories);
}


/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppConfigCopyWith<_AppConfig> get copyWith => __$AppConfigCopyWithImpl<_AppConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppConfig&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._instruments, _instruments)&&const DeepCollectionEquality().equals(other._crewRoles, _crewRoles)&&const DeepCollectionEquality().equals(other._studioServices, _studioServices)&&const DeepCollectionEquality().equals(other._professionalCategories, _professionalCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_instruments),const DeepCollectionEquality().hash(_crewRoles),const DeepCollectionEquality().hash(_studioServices),const DeepCollectionEquality().hash(_professionalCategories));

@override
String toString() {
  return 'AppConfig(version: $version, genres: $genres, instruments: $instruments, crewRoles: $crewRoles, studioServices: $studioServices, professionalCategories: $professionalCategories)';
}


}

/// @nodoc
abstract mixin class _$AppConfigCopyWith<$Res> implements $AppConfigCopyWith<$Res> {
  factory _$AppConfigCopyWith(_AppConfig value, $Res Function(_AppConfig) _then) = __$AppConfigCopyWithImpl;
@override @useResult
$Res call({
 int version, List<ConfigItem> genres, List<ConfigItem> instruments, List<ConfigItem> crewRoles, List<ConfigItem> studioServices, List<ConfigItem> professionalCategories
});




}
/// @nodoc
class __$AppConfigCopyWithImpl<$Res>
    implements _$AppConfigCopyWith<$Res> {
  __$AppConfigCopyWithImpl(this._self, this._then);

  final _AppConfig _self;
  final $Res Function(_AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? genres = null,Object? instruments = null,Object? crewRoles = null,Object? studioServices = null,Object? professionalCategories = null,}) {
  return _then(_AppConfig(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,instruments: null == instruments ? _self._instruments : instruments // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,crewRoles: null == crewRoles ? _self._crewRoles : crewRoles // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,studioServices: null == studioServices ? _self._studioServices : studioServices // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,professionalCategories: null == professionalCategories ? _self._professionalCategories : professionalCategories // ignore: cast_nullable_to_non_nullable
as List<ConfigItem>,
  ));
}


}

// dart format on
