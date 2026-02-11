import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/media_item.dart';

part 'edit_profile_state.freezed.dart';

@freezed
abstract class EditProfileState with _$EditProfileState {
  const EditProfileState._();

  const factory EditProfileState({
    @Default(false) bool isSaving,
    @Default(false) bool hasChanges, // Tracks if user modified anything
    // Gallery State
    @Default([]) List<MediaItem> galleryItems,
    @Default(false) bool isUploadingMedia,
    @Default(0.0) double uploadProgress,
    @Default('') String uploadStatus,

    // Professional Fields
    @Default([]) List<String> selectedCategories,
    @Default([]) List<String> selectedGenres,
    @Default([]) List<String> selectedInstruments,
    @Default([]) List<String> selectedRoles,
    @Default('0') String backingVocalMode,
    @Default(false) bool instrumentalistBackingVocal,

    // Studio Fields
    String? studioType,
    @Default([]) List<String> selectedServices,

    // Band Fields
    @Default([]) List<String> bandGenres,
  }) = _EditProfileState;
}

extension EditProfileStateX on EditProfileState {
  int get photoCount =>
      galleryItems.where((i) => i.type == MediaType.photo).length;
  int get videoCount =>
      galleryItems.where((i) => i.type == MediaType.video).length;
}
