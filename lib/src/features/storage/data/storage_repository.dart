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
      // 1. Create a reference to the location you want to upload to
      final ref = _storage.ref().child('profile_photos/$userId');

      // 2. Upload the file
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      // 3. Get the download URL
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
}
