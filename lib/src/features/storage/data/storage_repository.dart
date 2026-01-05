import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Erro ao fazer upload da imagem: $e');
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
  Future<String> uploadGalleryMedia({
    required String userId,
    required File file,
    required String mediaId,
    required bool isVideo,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final folder = isVideo ? 'gallery_videos' : 'gallery_photos';
      final ext = isVideo ? 'mp4' : 'jpg';
      final contentType = isVideo ? 'video/mp4' : 'image/jpeg';
      final ref = _storage.ref().child('$folder/$userId/$mediaId.$ext');
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putFile(file, metadata);

      // Listen to progress updates
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao fazer upload da mídia: $e');
    }
  }

  /// Uploads a video thumbnail.
  Future<String> uploadVideoThumbnail({
    required String userId,
    required String mediaId,
    required File thumbnail,
  }) async {
    try {
      final ref = _storage.ref().child(
        'gallery_thumbnails/$userId/$mediaId.jpg',
      );
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(thumbnail, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erro ao fazer upload do thumbnail: $e');
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
