import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../auth/data/auth_repository.dart';
import '../../../../auth/domain/app_user.dart';
import '../../../../auth/domain/user_type.dart';
import '../../../../storage/data/storage_repository.dart';
import '../../../domain/media_item.dart';
import '../../profile_controller.dart';
import '../../public_profile_controller.dart';
import 'edit_profile_state.dart';

part 'edit_profile_controller.g.dart';

@riverpod
class EditProfileController extends _$EditProfileController {
  static const int _maxPhotos = 6;
  static const int _maxVideos = 3;
  static const int _maxTotal = 9;

  @override
  EditProfileState build(String userId) {
    final userAsync = ref.read(currentUserProfileProvider);
    final user = userAsync.whenOrNull(data: (u) => u);
    if (user == null || user.uid != userId) return const EditProfileState();
    return _initializeFromUser(user);
  }

  EditProfileState _initializeFromUser(AppUser user) {
    // Initialize type-specific data
    List<String> categories = [];
    List<String> genres = [];
    List<String> instruments = [];
    List<String> roles = [];
    String backingVocal = '0';
    bool instBacking = false;
    String? studioType;
    List<String> services = [];
    List<String> bandGenres = [];
    List<MediaItem> gallery = [];

    switch (user.tipoPerfil) {
      case AppUserType.professional:
        final data = user.dadosProfissional ?? {};
        categories = List<String>.from(data['categorias'] ?? []);
        genres = List<String>.from(data['generosMusicais'] ?? []);
        instruments = List<String>.from(data['instrumentos'] ?? []);
        roles = List<String>.from(data['funcoes'] ?? []);
        backingVocal = (data['backingVocalMode'] ?? '0').toString();
        instBacking =
            data['instrumentalistBackingVocal'] ??
            data['fazBackingVocal'] ??
            false;
        gallery = _parseGallery(data['gallery']);
        break;

      case AppUserType.studio:
        final data = user.dadosEstudio ?? {};
        studioType = data['studioType'];
        services = List<String>.from(
          data['servicosOferecidos'] ?? data['services'] ?? [],
        );
        gallery = _parseGallery(data['gallery']);
        break;

      case AppUserType.band:
        final data = user.dadosBanda ?? {};
        bandGenres = List<String>.from(data['generosMusicais'] ?? []);
        gallery = _parseGallery(data['gallery']);
        break;

      default:
        break;
    }

    return EditProfileState(
      selectedCategories: categories,
      selectedGenres: genres,
      selectedInstruments: instruments,
      selectedRoles: roles,
      backingVocalMode: backingVocal,
      instrumentalistBackingVocal: instBacking,
      studioType: studioType,
      selectedServices: services,
      bandGenres: bandGenres,
      galleryItems: gallery,
    );
  }

  List<MediaItem> _parseGallery(dynamic galleryData) {
    if (galleryData == null) return [];
    final List<dynamic> items = galleryData as List<dynamic>;
    final parsed = items.map((item) {
      final map = item as Map<String, dynamic>;

      // Handle type conversion explicitly to match MediaType enum
      final typeStr = map['type'] as String?;
      final type = typeStr == 'video' ? MediaType.video : MediaType.photo;

      return MediaItem(
        id: map['id'] ?? const Uuid().v4(),
        url: map['url'] ?? '',
        type: type,
        thumbnailUrl: map['thumbnailUrl'],
        order: map['order'] ?? 0,
      );
    }).toList();
    parsed.sort((a, b) => a.order.compareTo(b.order));
    return parsed;
  }

  void markChanged() {
    if (!state.hasChanges && !state.isSaving) {
      state = state.copyWith(hasChanges: true);
    }
  }

  // --- Type Specific Toggles ---

  void toggleCategory(String category) {
    final list = List<String>.from(state.selectedCategories);
    if (list.contains(category)) {
      list.remove(category);
    } else {
      list.add(category);
    }
    state = state.copyWith(selectedCategories: list, hasChanges: true);
  }

  void toggleGenre(String genre) {
    final list = List<String>.from(state.selectedGenres);
    if (list.contains(genre)) {
      list.remove(genre);
    } else {
      list.add(genre);
    }
    state = state.copyWith(selectedGenres: list, hasChanges: true);
  }

  void toggleInstrument(String instrument) {
    final list = List<String>.from(state.selectedInstruments);
    if (list.contains(instrument)) {
      list.remove(instrument);
    } else {
      list.add(instrument);
    }
    state = state.copyWith(selectedInstruments: list, hasChanges: true);
  }

  void toggleRole(String role) {
    final list = List<String>.from(state.selectedRoles);
    if (list.contains(role)) {
      list.remove(role);
    } else {
      list.add(role);
    }
    state = state.copyWith(selectedRoles: list, hasChanges: true);
  }

  void setBackingVocalMode(String mode) {
    state = state.copyWith(backingVocalMode: mode, hasChanges: true);
  }

  void setInstrumentalistBackingVocal(bool value) {
    state = state.copyWith(
      instrumentalistBackingVocal: value,
      hasChanges: true,
    );
  }

  void setStudioType(String? type) {
    state = state.copyWith(studioType: type, hasChanges: true);
  }

  void toggleService(String service) {
    final list = List<String>.from(state.selectedServices);
    if (list.contains(service)) {
      list.remove(service);
    } else {
      list.add(service);
    }
    state = state.copyWith(selectedServices: list, hasChanges: true);
  }

  void toggleBandGenre(String genre) {
    final list = List<String>.from(state.bandGenres);
    if (list.contains(genre)) {
      list.remove(genre);
    } else {
      list.add(genre);
    }
    state = state.copyWith(bandGenres: list, hasChanges: true);
  }

  void updateCategories(List<String> categories) {
    state = state.copyWith(selectedCategories: categories, hasChanges: true);
  }

  void updateGenres(List<String> genres) {
    state = state.copyWith(selectedGenres: genres, hasChanges: true);
  }

  void updateInstruments(List<String> instruments) {
    state = state.copyWith(selectedInstruments: instruments, hasChanges: true);
  }

  void updateRoles(List<String> roles) {
    state = state.copyWith(selectedRoles: roles, hasChanges: true);
  }

  void updateServices(List<String> services) {
    state = state.copyWith(selectedServices: services, hasChanges: true);
  }

  void updateBandGenres(List<String> genres) {
    state = state.copyWith(bandGenres: genres, hasChanges: true);
  }

  // --- Gallery Logic ---

  /// Helper: update upload progress on a specific gallery item.
  void _updateItemProgress(String mediaId, double progress) {
    final newGallery = state.galleryItems.map((item) {
      if (item.id == mediaId) {
        return item.copyWith(uploadProgress: progress);
      }
      return item;
    }).toList();
    state = state.copyWith(galleryItems: newGallery);
  }

  Future<void> addPhoto({required File file, required String userId}) async {
    if (state.galleryItems.length >= _maxTotal ||
        state.photoCount >= _maxPhotos) {
      throw 'Limite de fotos atingido';
    }

    final mediaId = const Uuid().v4();

    // Optimistic: add placeholder immediately with local file preview
    final placeholder = MediaItem(
      id: mediaId,
      url: '',
      type: MediaType.photo,
      order: state.galleryItems.length,
      localPath: file.path,
      isUploading: true,
      uploadProgress: 0.0,
    );

    state = state.copyWith(
      galleryItems: [...state.galleryItems, placeholder],
      isUploadingMedia: true,
      uploadProgress: 0.0,
      uploadStatus: 'Enviando foto...',
      hasChanges: true,
    );

    try {
      final storage = ref.read(storageRepositoryProvider);

      final mediaUrls = await storage.uploadGalleryMediaWithSizes(
        userId: userId,
        file: file,
        mediaId: mediaId,
        isVideo: false,
        onProgress: (progress) {
          // Update progress on the specific placeholder item
          _updateItemProgress(mediaId, progress);
          state = state.copyWith(uploadProgress: progress);
        },
      );

      // Replace placeholder with final item (remote URL, no local state)
      final finalItem = MediaItem(
        id: mediaId,
        url: mediaUrls.full ?? '',
        type: MediaType.photo,
        order: placeholder.order,
      );

      final newGallery = state.galleryItems
          .map((item) => item.id == mediaId ? finalItem : item)
          .toList();

      state = state.copyWith(
        galleryItems: newGallery,
        isUploadingMedia: false,
        uploadProgress: 0.0,
      );

      ref.invalidate(publicProfileControllerProvider(userId));
    } catch (e) {
      // Remove placeholder on failure
      final newGallery = state.galleryItems
          .where((item) => item.id != mediaId)
          .toList();
      state = state.copyWith(
        galleryItems: newGallery,
        isUploadingMedia: false,
        uploadProgress: 0.0,
      );
      rethrow;
    }
  }

  Future<void> addVideo({
    required File videoFile,
    required File thumbnailFile,
    required String userId,
  }) async {
    if (state.galleryItems.length >= _maxTotal ||
        state.videoCount >= _maxVideos) {
      throw 'Limite de vídeos atingido';
    }

    final mediaId = const Uuid().v4();

    // Optimistic: add placeholder immediately with local thumbnail preview
    final placeholder = MediaItem(
      id: mediaId,
      url: '',
      type: MediaType.video,
      order: state.galleryItems.length,
      localPath: videoFile.path,
      localThumbnailPath: thumbnailFile.path,
      isUploading: true,
      uploadProgress: 0.0,
    );

    state = state.copyWith(
      galleryItems: [...state.galleryItems, placeholder],
      isUploadingMedia: true,
      uploadProgress: 0.0,
      uploadStatus: 'Enviando vídeo...',
      hasChanges: true,
    );

    try {
      final storage = ref.read(storageRepositoryProvider);

      // Upload video
      final mediaUrls = await storage.uploadGalleryMediaWithSizes(
        userId: userId,
        file: videoFile,
        mediaId: mediaId,
        isVideo: true,
        onProgress: (progress) {
          final totalProgress = progress * 0.9;
          _updateItemProgress(mediaId, totalProgress);
          state = state.copyWith(uploadProgress: totalProgress);
        },
      );

      state = state.copyWith(uploadStatus: 'Enviando thumbnail...');

      // Upload thumbnail
      final thumbUrl = await storage.uploadVideoThumbnail(
        userId: userId,
        mediaId: mediaId,
        thumbnail: thumbnailFile,
      );

      // Replace placeholder with final item
      final finalItem = MediaItem(
        id: mediaId,
        url: mediaUrls.full ?? '',
        type: MediaType.video,
        thumbnailUrl: thumbUrl,
        order: placeholder.order,
      );

      final newGallery = state.galleryItems
          .map((item) => item.id == mediaId ? finalItem : item)
          .toList();

      state = state.copyWith(
        galleryItems: newGallery,
        isUploadingMedia: false,
        uploadProgress: 0.0,
      );

      ref.invalidate(publicProfileControllerProvider(userId));
    } catch (e) {
      // Remove placeholder on failure
      final newGallery = state.galleryItems
          .where((item) => item.id != mediaId)
          .toList();
      state = state.copyWith(
        galleryItems: newGallery,
        isUploadingMedia: false,
        uploadProgress: 0.0,
      );
      rethrow;
    }
  }

  Future<void> removeMedia(int index, String userId) async {
    final item = state.galleryItems[index];

    try {
      await ref
          .read(storageRepositoryProvider)
          .deleteGalleryItem(
            userId: userId,
            mediaId: item.id,
            isVideo: item.type == MediaType.video,
          );
    } catch (_) {
      // Ignore deletion errors or log them
    }

    final newGallery = [...state.galleryItems]..removeAt(index);
    state = state.copyWith(galleryItems: newGallery, hasChanges: true);
  }

  void reorderMedia(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final newGallery = [...state.galleryItems];
    final item = newGallery.removeAt(oldIndex);
    newGallery.insert(newIndex, item);

    state = state.copyWith(galleryItems: newGallery, hasChanges: true);
  }

  // --- Validation & Save ---

  bool validate(AppUserType type) {
    if (type == AppUserType.professional) {
      if (state.selectedCategories.isEmpty) return false;
      if (state.selectedCategories.contains('instrumentalist') &&
          state.selectedInstruments.isEmpty) {
        return false;
      }
      if (state.selectedCategories.contains('crew') &&
          state.selectedRoles.isEmpty) {
        return false;
      }
      if (state.selectedGenres.isEmpty) return false;
    } else if (type == AppUserType.band) {
      if (state.bandGenres.isEmpty) return false;
    } else if (type == AppUserType.studio) {
      if (state.selectedServices.isEmpty) return false;
    }
    return true;
  }

  List<Map<String, dynamic>> _galleryToJson() {
    final persistedItems = state.galleryItems
        .where((item) => !item.isUploading && item.url.isNotEmpty)
        .toList();

    return persistedItems.asMap().entries.map((entry) {
      final item = entry.value;
      return {
        'id': item.id,
        'url': item.url,
        'type': item.type == MediaType.video ? 'video' : 'photo',
        'thumbnailUrl': item.thumbnailUrl,
        'order': entry.key,
      };
    }).toList();
  }

  Future<void> saveProfile({
    required AppUser user,
    required String nome,
    required String bio,
    required String nomeArtistico,
    required String celular,
    required String dataNascimento,
    required String genero,
    required String instagram,
  }) async {
    if (state.isSaving) return;

    if (!validate(user.tipoPerfil!)) {
      throw 'Preencha todos os campos obrigatórios';
    }

    state = state.copyWith(isSaving: true);

    try {
      final Map<String, dynamic> updates = {'nome': nome, 'bio': bio};

      switch (user.tipoPerfil) {
        case AppUserType.professional:
          updates['dadosProfissional'] = {
            'nomeArtistico': nomeArtistico,
            'celular': celular,
            'dataNascimento': dataNascimento,
            'genero': genero,
            'instagram': instagram,
            'categorias': state.selectedCategories,
            'generosMusicais': state.selectedGenres,
            'instrumentos': state.selectedInstruments,
            'funcoes': state.selectedRoles,
            'backingVocalMode': state.backingVocalMode,
            'instrumentalistBackingVocal': state.instrumentalistBackingVocal,
            'fazBackingVocal': state.instrumentalistBackingVocal,
            'gallery': _galleryToJson(),
          };
          break;

        case AppUserType.studio:
          updates['dadosEstudio'] = {
            'nomeEstudio': nomeArtistico,
            'nomeArtistico': nomeArtistico,
            'nome': nomeArtistico,
            'celular': celular,
            'studioType': state.studioType,
            'servicosOferecidos': state.selectedServices,
            'services': state.selectedServices,
            'gallery': _galleryToJson(),
          };
          break;

        case AppUserType.band:
          updates['dadosBanda'] = {
            'nomeBanda': nomeArtistico,
            'nomeArtistico': nomeArtistico,
            'nome': nomeArtistico,
            'bio': bio,
            'generosMusicais': state.bandGenres,
            'gallery': _galleryToJson(),
          };
          break;

        case AppUserType.contractor:
          updates['dadosContratante'] = {
            'celular': celular,
            'dataNascimento': dataNascimento,
            'genero': genero,
            'instagram': instagram,
          };
          break;

        default:
          break;
      }

      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(currentUser: user, updates: updates);

      state = state.copyWith(isSaving: false, hasChanges: false);
    } catch (e) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}
