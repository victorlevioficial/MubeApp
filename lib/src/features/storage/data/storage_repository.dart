import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/image_compressor.dart';
import '../domain/upload_validator.dart';

part 'storage_repository.g.dart';

@Riverpod(keepAlive: true)
StorageRepository storageRepository(Ref ref) {
  return StorageRepository(FirebaseStorage.instance);
}

class StorageRepository {
  final FirebaseStorage _storage;

  StorageRepository(this._storage);

  /// Uploads a profile image for the given user ID.
  /// Returns the download URL.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    // Validar arquivo antes do upload
    await UploadValidator.validateImage(file);

    // Comprimir imagem antes do upload
    final compressedFile = await ImageCompressor.compressProfilePhoto(file);

    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(compressedFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Erro ao fazer upload da imagem: ${e.message}');
    }
  }

  /// Deletes an image given its URL (useful for cleanup if we want to replace)
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore if not found or already deleted
    }
  }

  /// Uploads a gallery media file (photo or video).
  /// Returns the download URL.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  Future<String> uploadGalleryMedia({
    required String userId,
    required File file,
    required String mediaId,
    required bool isVideo,
    void Function(double progress)? onProgress,
  }) async {
    // NOVO: Verificar autenticação antes de iniciar upload
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception(
        'Você precisa estar logado para fazer upload. '
        'Tente fazer logout e login novamente.',
      );
    }

    if (currentUser.uid != userId) {
      throw Exception(
        'Erro de autenticação: O usuário atual não corresponde '
        'ao perfil. Tente fazer logout e login novamente.',
      );
    }

    // DEBUG: Log informações de autenticação
    print('🔐 DEBUG Storage Upload:');
    print('   Tipo: ${isVideo ? "Vídeo" : "Foto"}');
    print('   User ID: $userId');
    print('   Current User: ${currentUser.uid}');
    print('   Email: ${currentUser.email}');
    print('   Auth: Autenticado ✅');

    // Validar arquivo antes do upload
    await UploadValidator.validateMedia(file, isVideo: isVideo);

    // Comprimir imagem antes do upload (vídeos não são comprimidos aqui)
    final fileToUpload = isVideo
        ? file
        : await ImageCompressor.compressGalleryPhoto(file);

    try {
      final folder = isVideo ? 'gallery_videos' : 'gallery_photos';
      final ext = isVideo ? 'mp4' : 'jpg';
      final contentType = isVideo ? 'video/mp4' : 'image/jpeg';
      final ref = _storage.ref().child('$folder/$userId/$mediaId.$ext');
      final metadata = SettableMetadata(contentType: contentType);

      print('📤 Iniciando upload: $folder/$userId/$mediaId.$ext');

      final uploadTask = ref.putFile(fileToUpload, metadata);

      // Listen to progress updates
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload concluído: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Erro Firebase: ${e.code} - ${e.message}');

      if (e.code == 'permission-denied' || e.code == 'unauthorized') {
        throw Exception(
          'Erro de permissão: Você não tem autorização para fazer upload. '
          'Tente fazer logout e login novamente. '
          'Detalhes técnicos: ${e.code}',
        );
      }

      throw Exception('Erro ao fazer upload da mídia: ${e.message}');
    }
  }

  /// Uploads a video thumbnail.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  Future<String> uploadVideoThumbnail({
    required String userId,
    required String mediaId,
    required File thumbnail,
  }) async {
    // Validar thumbnail antes do upload
    await UploadValidator.validateImage(thumbnail);

    // Comprimir thumbnail antes do upload
    final compressedThumbnail = await ImageCompressor.compressThumbnail(
      thumbnail,
    );

    try {
      final ref = _storage.ref().child(
        'gallery_thumbnails/$userId/$mediaId.jpg',
      );
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(compressedThumbnail, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Erro ao fazer upload do thumbnail: ${e.message}');
    }
  }

  /// Deletes all files for a gallery item.
  Future<void> deleteGalleryItem({
    required String userId,
    required String mediaId,
    required bool isVideo,
  }) async {
    try {
      final folder = isVideo ? 'gallery_videos' : 'gallery_photos';
      final ext = isVideo ? 'mp4' : 'jpg';
      final ref = _storage.ref().child('$folder/$userId/$mediaId.$ext');
      await ref.delete();

      if (isVideo) {
        final thumbRef = _storage.ref().child(
          'gallery_thumbnails/$userId/$mediaId.jpg',
        );
        await thumbRef.delete();
      }
    } catch (e) {
      // Ignore if not found
    }
  }
}
