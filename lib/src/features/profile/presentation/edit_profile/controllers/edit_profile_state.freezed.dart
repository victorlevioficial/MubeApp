// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_profile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditProfileState {

 bool get isSaving; bool get hasChanges;// Tracks if user modified anything
// Gallery State
 List<MediaItem> get galleryItems; bool get isUploadingMedia; double get uploadProgress; String get uploadStatus;// Professional Fields
 List<String> get selectedCategories; List<String> get selectedGenres; List<String> get selectedInstruments; List<String> get selectedRoles; String get backingVocalMode; bool get instrumentalistBackingVocal;// Studio Fields
 String? get studioType; List<String> get selectedServices;// Band Fields
 List<String> get bandGenres;
/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditProfileStateCopyWith<EditProfileState> get copyWith => _$EditProfileStateCopyWithImpl<EditProfileState>(this as EditProfileState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProfileState&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.hasChanges, hasChanges) || other.hasChanges == hasChanges)&&const DeepCollectionEquality().equals(other.galleryItems, galleryItems)&&(identical(other.isUploadingMedia, isUploadingMedia) || other.isUploadingMedia == isUploadingMedia)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.uploadStatus, uploadStatus) || other.uploadStatus == uploadStatus)&&const DeepCollectionEquality().equals(other.selectedCategories, selectedCategories)&&const DeepCollectionEquality().equals(other.selectedGenres, selectedGenres)&&const DeepCollectionEquality().equals(other.selectedInstruments, selectedInstruments)&&const DeepCollectionEquality().equals(other.selectedRoles, selectedRoles)&&(identical(other.backingVocalMode, backingVocalMode) || other.backingVocalMode == backingVocalMode)&&(identical(other.instrumentalistBackingVocal, instrumentalistBackingVocal) || other.instrumentalistBackingVocal == instrumentalistBackingVocal)&&(identical(other.studioType, studioType) || other.studioType == studioType)&&const DeepCollectionEquality().equals(other.selectedServices, selectedServices)&&const DeepCollectionEquality().equals(other.bandGenres, bandGenres));
}


@override
int get hashCode => Object.hash(runtimeType,isSaving,hasChanges,const DeepCollectionEquality().hash(galleryItems),isUploadingMedia,uploadProgress,uploadStatus,const DeepCollectionEquality().hash(selectedCategories),const DeepCollectionEquality().hash(selectedGenres),const DeepCollectionEquality().hash(selectedInstruments),const DeepCollectionEquality().hash(selectedRoles),backingVocalMode,instrumentalistBackingVocal,studioType,const DeepCollectionEquality().hash(selectedServices),const DeepCollectionEquality().hash(bandGenres));

@override
String toString() {
  return 'EditProfileState(isSaving: $isSaving, hasChanges: $hasChanges, galleryItems: $galleryItems, isUploadingMedia: $isUploadingMedia, uploadProgress: $uploadProgress, uploadStatus: $uploadStatus, selectedCategories: $selectedCategories, selectedGenres: $selectedGenres, selectedInstruments: $selectedInstruments, selectedRoles: $selectedRoles, backingVocalMode: $backingVocalMode, instrumentalistBackingVocal: $instrumentalistBackingVocal, studioType: $studioType, selectedServices: $selectedServices, bandGenres: $bandGenres)';
}


}

/// @nodoc
abstract mixin class $EditProfileStateCopyWith<$Res>  {
  factory $EditProfileStateCopyWith(EditProfileState value, $Res Function(EditProfileState) _then) = _$EditProfileStateCopyWithImpl;
@useResult
$Res call({
 bool isSaving, bool hasChanges, List<MediaItem> galleryItems, bool isUploadingMedia, double uploadProgress, String uploadStatus, List<String> selectedCategories, List<String> selectedGenres, List<String> selectedInstruments, List<String> selectedRoles, String backingVocalMode, bool instrumentalistBackingVocal, String? studioType, List<String> selectedServices, List<String> bandGenres
});




}
/// @nodoc
class _$EditProfileStateCopyWithImpl<$Res>
    implements $EditProfileStateCopyWith<$Res> {
  _$EditProfileStateCopyWithImpl(this._self, this._then);

  final EditProfileState _self;
  final $Res Function(EditProfileState) _then;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSaving = null,Object? hasChanges = null,Object? galleryItems = null,Object? isUploadingMedia = null,Object? uploadProgress = null,Object? uploadStatus = null,Object? selectedCategories = null,Object? selectedGenres = null,Object? selectedInstruments = null,Object? selectedRoles = null,Object? backingVocalMode = null,Object? instrumentalistBackingVocal = null,Object? studioType = freezed,Object? selectedServices = null,Object? bandGenres = null,}) {
  return _then(_self.copyWith(
isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,hasChanges: null == hasChanges ? _self.hasChanges : hasChanges // ignore: cast_nullable_to_non_nullable
as bool,galleryItems: null == galleryItems ? _self.galleryItems : galleryItems // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,isUploadingMedia: null == isUploadingMedia ? _self.isUploadingMedia : isUploadingMedia // ignore: cast_nullable_to_non_nullable
as bool,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,uploadStatus: null == uploadStatus ? _self.uploadStatus : uploadStatus // ignore: cast_nullable_to_non_nullable
as String,selectedCategories: null == selectedCategories ? _self.selectedCategories : selectedCategories // ignore: cast_nullable_to_non_nullable
as List<String>,selectedGenres: null == selectedGenres ? _self.selectedGenres : selectedGenres // ignore: cast_nullable_to_non_nullable
as List<String>,selectedInstruments: null == selectedInstruments ? _self.selectedInstruments : selectedInstruments // ignore: cast_nullable_to_non_nullable
as List<String>,selectedRoles: null == selectedRoles ? _self.selectedRoles : selectedRoles // ignore: cast_nullable_to_non_nullable
as List<String>,backingVocalMode: null == backingVocalMode ? _self.backingVocalMode : backingVocalMode // ignore: cast_nullable_to_non_nullable
as String,instrumentalistBackingVocal: null == instrumentalistBackingVocal ? _self.instrumentalistBackingVocal : instrumentalistBackingVocal // ignore: cast_nullable_to_non_nullable
as bool,studioType: freezed == studioType ? _self.studioType : studioType // ignore: cast_nullable_to_non_nullable
as String?,selectedServices: null == selectedServices ? _self.selectedServices : selectedServices // ignore: cast_nullable_to_non_nullable
as List<String>,bandGenres: null == bandGenres ? _self.bandGenres : bandGenres // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [EditProfileState].
extension EditProfileStatePatterns on EditProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditProfileState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditProfileState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditProfileState value)  $default,){
final _that = this;
switch (_that) {
case _EditProfileState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditProfileState value)?  $default,){
final _that = this;
switch (_that) {
case _EditProfileState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSaving,  bool hasChanges,  List<MediaItem> galleryItems,  bool isUploadingMedia,  double uploadProgress,  String uploadStatus,  List<String> selectedCategories,  List<String> selectedGenres,  List<String> selectedInstruments,  List<String> selectedRoles,  String backingVocalMode,  bool instrumentalistBackingVocal,  String? studioType,  List<String> selectedServices,  List<String> bandGenres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditProfileState() when $default != null:
return $default(_that.isSaving,_that.hasChanges,_that.galleryItems,_that.isUploadingMedia,_that.uploadProgress,_that.uploadStatus,_that.selectedCategories,_that.selectedGenres,_that.selectedInstruments,_that.selectedRoles,_that.backingVocalMode,_that.instrumentalistBackingVocal,_that.studioType,_that.selectedServices,_that.bandGenres);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSaving,  bool hasChanges,  List<MediaItem> galleryItems,  bool isUploadingMedia,  double uploadProgress,  String uploadStatus,  List<String> selectedCategories,  List<String> selectedGenres,  List<String> selectedInstruments,  List<String> selectedRoles,  String backingVocalMode,  bool instrumentalistBackingVocal,  String? studioType,  List<String> selectedServices,  List<String> bandGenres)  $default,) {final _that = this;
switch (_that) {
case _EditProfileState():
return $default(_that.isSaving,_that.hasChanges,_that.galleryItems,_that.isUploadingMedia,_that.uploadProgress,_that.uploadStatus,_that.selectedCategories,_that.selectedGenres,_that.selectedInstruments,_that.selectedRoles,_that.backingVocalMode,_that.instrumentalistBackingVocal,_that.studioType,_that.selectedServices,_that.bandGenres);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSaving,  bool hasChanges,  List<MediaItem> galleryItems,  bool isUploadingMedia,  double uploadProgress,  String uploadStatus,  List<String> selectedCategories,  List<String> selectedGenres,  List<String> selectedInstruments,  List<String> selectedRoles,  String backingVocalMode,  bool instrumentalistBackingVocal,  String? studioType,  List<String> selectedServices,  List<String> bandGenres)?  $default,) {final _that = this;
switch (_that) {
case _EditProfileState() when $default != null:
return $default(_that.isSaving,_that.hasChanges,_that.galleryItems,_that.isUploadingMedia,_that.uploadProgress,_that.uploadStatus,_that.selectedCategories,_that.selectedGenres,_that.selectedInstruments,_that.selectedRoles,_that.backingVocalMode,_that.instrumentalistBackingVocal,_that.studioType,_that.selectedServices,_that.bandGenres);case _:
  return null;

}
}

}

/// @nodoc


class _EditProfileState extends EditProfileState {
  const _EditProfileState({this.isSaving = false, this.hasChanges = false, final  List<MediaItem> galleryItems = const [], this.isUploadingMedia = false, this.uploadProgress = 0.0, this.uploadStatus = '', final  List<String> selectedCategories = const [], final  List<String> selectedGenres = const [], final  List<String> selectedInstruments = const [], final  List<String> selectedRoles = const [], this.backingVocalMode = '0', this.instrumentalistBackingVocal = false, this.studioType, final  List<String> selectedServices = const [], final  List<String> bandGenres = const []}): _galleryItems = galleryItems,_selectedCategories = selectedCategories,_selectedGenres = selectedGenres,_selectedInstruments = selectedInstruments,_selectedRoles = selectedRoles,_selectedServices = selectedServices,_bandGenres = bandGenres,super._();
  

@override@JsonKey() final  bool isSaving;
@override@JsonKey() final  bool hasChanges;
// Tracks if user modified anything
// Gallery State
 final  List<MediaItem> _galleryItems;
// Tracks if user modified anything
// Gallery State
@override@JsonKey() List<MediaItem> get galleryItems {
  if (_galleryItems is EqualUnmodifiableListView) return _galleryItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_galleryItems);
}

@override@JsonKey() final  bool isUploadingMedia;
@override@JsonKey() final  double uploadProgress;
@override@JsonKey() final  String uploadStatus;
// Professional Fields
 final  List<String> _selectedCategories;
// Professional Fields
@override@JsonKey() List<String> get selectedCategories {
  if (_selectedCategories is EqualUnmodifiableListView) return _selectedCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedCategories);
}

 final  List<String> _selectedGenres;
@override@JsonKey() List<String> get selectedGenres {
  if (_selectedGenres is EqualUnmodifiableListView) return _selectedGenres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedGenres);
}

 final  List<String> _selectedInstruments;
@override@JsonKey() List<String> get selectedInstruments {
  if (_selectedInstruments is EqualUnmodifiableListView) return _selectedInstruments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedInstruments);
}

 final  List<String> _selectedRoles;
@override@JsonKey() List<String> get selectedRoles {
  if (_selectedRoles is EqualUnmodifiableListView) return _selectedRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedRoles);
}

@override@JsonKey() final  String backingVocalMode;
@override@JsonKey() final  bool instrumentalistBackingVocal;
// Studio Fields
@override final  String? studioType;
 final  List<String> _selectedServices;
@override@JsonKey() List<String> get selectedServices {
  if (_selectedServices is EqualUnmodifiableListView) return _selectedServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedServices);
}

// Band Fields
 final  List<String> _bandGenres;
// Band Fields
@override@JsonKey() List<String> get bandGenres {
  if (_bandGenres is EqualUnmodifiableListView) return _bandGenres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bandGenres);
}


/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditProfileStateCopyWith<_EditProfileState> get copyWith => __$EditProfileStateCopyWithImpl<_EditProfileState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditProfileState&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.hasChanges, hasChanges) || other.hasChanges == hasChanges)&&const DeepCollectionEquality().equals(other._galleryItems, _galleryItems)&&(identical(other.isUploadingMedia, isUploadingMedia) || other.isUploadingMedia == isUploadingMedia)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.uploadStatus, uploadStatus) || other.uploadStatus == uploadStatus)&&const DeepCollectionEquality().equals(other._selectedCategories, _selectedCategories)&&const DeepCollectionEquality().equals(other._selectedGenres, _selectedGenres)&&const DeepCollectionEquality().equals(other._selectedInstruments, _selectedInstruments)&&const DeepCollectionEquality().equals(other._selectedRoles, _selectedRoles)&&(identical(other.backingVocalMode, backingVocalMode) || other.backingVocalMode == backingVocalMode)&&(identical(other.instrumentalistBackingVocal, instrumentalistBackingVocal) || other.instrumentalistBackingVocal == instrumentalistBackingVocal)&&(identical(other.studioType, studioType) || other.studioType == studioType)&&const DeepCollectionEquality().equals(other._selectedServices, _selectedServices)&&const DeepCollectionEquality().equals(other._bandGenres, _bandGenres));
}


@override
int get hashCode => Object.hash(runtimeType,isSaving,hasChanges,const DeepCollectionEquality().hash(_galleryItems),isUploadingMedia,uploadProgress,uploadStatus,const DeepCollectionEquality().hash(_selectedCategories),const DeepCollectionEquality().hash(_selectedGenres),const DeepCollectionEquality().hash(_selectedInstruments),const DeepCollectionEquality().hash(_selectedRoles),backingVocalMode,instrumentalistBackingVocal,studioType,const DeepCollectionEquality().hash(_selectedServices),const DeepCollectionEquality().hash(_bandGenres));

@override
String toString() {
  return 'EditProfileState(isSaving: $isSaving, hasChanges: $hasChanges, galleryItems: $galleryItems, isUploadingMedia: $isUploadingMedia, uploadProgress: $uploadProgress, uploadStatus: $uploadStatus, selectedCategories: $selectedCategories, selectedGenres: $selectedGenres, selectedInstruments: $selectedInstruments, selectedRoles: $selectedRoles, backingVocalMode: $backingVocalMode, instrumentalistBackingVocal: $instrumentalistBackingVocal, studioType: $studioType, selectedServices: $selectedServices, bandGenres: $bandGenres)';
}


}

/// @nodoc
abstract mixin class _$EditProfileStateCopyWith<$Res> implements $EditProfileStateCopyWith<$Res> {
  factory _$EditProfileStateCopyWith(_EditProfileState value, $Res Function(_EditProfileState) _then) = __$EditProfileStateCopyWithImpl;
@override @useResult
$Res call({
 bool isSaving, bool hasChanges, List<MediaItem> galleryItems, bool isUploadingMedia, double uploadProgress, String uploadStatus, List<String> selectedCategories, List<String> selectedGenres, List<String> selectedInstruments, List<String> selectedRoles, String backingVocalMode, bool instrumentalistBackingVocal, String? studioType, List<String> selectedServices, List<String> bandGenres
});




}
/// @nodoc
class __$EditProfileStateCopyWithImpl<$Res>
    implements _$EditProfileStateCopyWith<$Res> {
  __$EditProfileStateCopyWithImpl(this._self, this._then);

  final _EditProfileState _self;
  final $Res Function(_EditProfileState) _then;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSaving = null,Object? hasChanges = null,Object? galleryItems = null,Object? isUploadingMedia = null,Object? uploadProgress = null,Object? uploadStatus = null,Object? selectedCategories = null,Object? selectedGenres = null,Object? selectedInstruments = null,Object? selectedRoles = null,Object? backingVocalMode = null,Object? instrumentalistBackingVocal = null,Object? studioType = freezed,Object? selectedServices = null,Object? bandGenres = null,}) {
  return _then(_EditProfileState(
isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,hasChanges: null == hasChanges ? _self.hasChanges : hasChanges // ignore: cast_nullable_to_non_nullable
as bool,galleryItems: null == galleryItems ? _self._galleryItems : galleryItems // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,isUploadingMedia: null == isUploadingMedia ? _self.isUploadingMedia : isUploadingMedia // ignore: cast_nullable_to_non_nullable
as bool,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,uploadStatus: null == uploadStatus ? _self.uploadStatus : uploadStatus // ignore: cast_nullable_to_non_nullable
as String,selectedCategories: null == selectedCategories ? _self._selectedCategories : selectedCategories // ignore: cast_nullable_to_non_nullable
as List<String>,selectedGenres: null == selectedGenres ? _self._selectedGenres : selectedGenres // ignore: cast_nullable_to_non_nullable
as List<String>,selectedInstruments: null == selectedInstruments ? _self._selectedInstruments : selectedInstruments // ignore: cast_nullable_to_non_nullable
as List<String>,selectedRoles: null == selectedRoles ? _self._selectedRoles : selectedRoles // ignore: cast_nullable_to_non_nullable
as List<String>,backingVocalMode: null == backingVocalMode ? _self.backingVocalMode : backingVocalMode // ignore: cast_nullable_to_non_nullable
as String,instrumentalistBackingVocal: null == instrumentalistBackingVocal ? _self.instrumentalistBackingVocal : instrumentalistBackingVocal // ignore: cast_nullable_to_non_nullable
as bool,studioType: freezed == studioType ? _self.studioType : studioType // ignore: cast_nullable_to_non_nullable
as String?,selectedServices: null == selectedServices ? _self._selectedServices : selectedServices // ignore: cast_nullable_to_non_nullable
as List<String>,bandGenres: null == bandGenres ? _self._bandGenres : bandGenres // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
