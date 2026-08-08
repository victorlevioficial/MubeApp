import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../utils/app_logger.dart';
import '../domain/image_compressor.dart';
import '../domain/upload_validator.dart';

part 'storage_repository.g.dart';

@Riverpod(keepAlive: true)
StorageRepository storageRepository(Ref ref) {
  return StorageRepository(
    ref.watch(firebaseStorageProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
}

/// Modelo para URLs de imagem em múltiplas resoluções
class ImageUrls {
  final String? thumbnail;
  final String? medium;
  final String? large;
  final String? full;

  const ImageUrls({this.thumbnail, this.medium, this.large, this.full});

  /// Retorna a URL mais apropriada para o tamanho solicitado
  String? getUrlForSize(ImageSize size) {
    switch (size) {
      case ImageSize.thumbnail:
        return thumbnail ?? medium ?? large ?? full;
      case ImageSize.medium:
        return medium ?? large ?? full ?? thumbnail;
      case ImageSize.large:
        return large ?? full ?? medium ?? thumbnail;
      case ImageSize.full:
        return full ?? large ?? medium ?? thumbnail;
    }
  }

  /// Retorna a primeira URL disponível
  String? get firstAvailable => thumbnail ?? medium ?? large ?? full;

  Map<String, dynamic> toJson() => {
    'thumbnail': thumbnail,
    'medium': medium,
    'large': large,
    'full': full,
  };

  factory ImageUrls.fromJson(Map<String, dynamic> json) {
    return ImageUrls(
      thumbnail: json['thumbnail'] as String?,
      medium: json['medium'] as String?,
      large: json['large'] as String?,
      full: json['full'] as String?,
    );
  }
}

class StorageRepository {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  StorageRepository(this._storage, {required FirebaseAuth auth}) : _auth = auth;

  /// Faz upload de uma imagem de perfil em múltiplas resoluções.
  /// Retorna um [ImageUrls] com as URLs de cada resolução.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  Future<ImageUrls> uploadProfileImageWithSizes({
    required String userId,
    required File file,
    bool generateMultipleSizes = true,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception(
        'Você precisa estar logado para atualizar a foto de perfil.',
      );
    }

    if (currentUser.uid != userId) {
      throw Exception(
        'Erro de autenticação: usuário logado diferente do perfil alvo.',
      );
    }

    AppLogger.info(
      'Profile image upload started: user=$userId, generateMultipleSizes=$generateMultipleSizes',
    );

    // Validar arquivo antes do upload
    await UploadValidator.validateImage(file);

    if (generateMultipleSizes) {
      // Gerar múltiplas versões da imagem
      final compressedFiles = await ImageCompressor.generateProfilePhotoSizes(
        file,
      );

      final thumbnailFuture = compressedFiles.containsKey(ImageSize.thumbnail)
          ? _uploadSingleImage(
              file: compressedFiles[ImageSize.thumbnail]!,
              path: 'profile_photos/$userId/thumbnail.webp',
              contentType: 'image/webp',
            )
          : Future<String?>.value(null);

      final largeFuture = compressedFiles.containsKey(ImageSize.large)
          ? _uploadSingleImage(
              file: compressedFiles[ImageSize.large]!,
              path: 'profile_photos/$userId/large.webp',
              contentType: 'image/webp',
            )
          : Future<String?>.value(null);

      final results = await Future.wait<String?>([
        thumbnailFuture,
        largeFuture,
      ]);
      final thumbnailUrl = results[0];
      final largeUrl = results[1];

      final urls = ImageUrls(
        thumbnail: thumbnailUrl,
        large: largeUrl,
        full: largeUrl, // Usar large como full para perfil
      );

      AppLogger.info(
        'Profile image upload finished: user=$userId, thumb=${urls.thumbnail != null}, large=${urls.large != null}',
      );

      return urls;
    } else {
      // Upload simples (compatibilidade)
      final compressedFile = await ImageCompressor.compressProfilePhoto(
        file,
        format: ImageFormat.webp,
      );

      final url = await _uploadSingleImage(
        file: compressedFile,
        path: 'profile_photos/$userId.webp',
        contentType: 'image/webp',
      );

      AppLogger.info(
        'Profile image upload finished (legacy mode): user=$userId',
      );
      return ImageUrls(full: url, large: url);
    }
  }

  /// Método legado - faz upload de uma imagem de perfil simples.
  /// Retorna a download URL.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  @Deprecated('Use uploadProfileImageWithSizes para melhor performance')
  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    // Validar arquivo antes do upload
    await UploadValidator.validateImage(file);

    // Comprimir imagem antes do upload (agora em WebP)
    final compressedFile = await ImageCompressor.compressProfilePhoto(
      file,
      format: ImageFormat.webp,
    );

    return _uploadSingleImage(
      file: compressedFile,
      path: 'profile_photos/$userId.webp',
      contentType: 'image/webp',
    );
  }

  /// Faz upload de uma mídia de galeria com múltiplas resoluções.
  ///
  /// Para imagens: gera thumbnail, medium, large e full.
  /// Para vídeos: faz upload do arquivo original + thumbnail.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  Future<GalleryMediaUrls> uploadGalleryMediaWithSizes({
    required String userId,
    required File file,
    required String mediaId,
    required bool isVideo,
    void Function(double progress)? onProgress,
  }) async {
    // NOVO: Verificar autenticação antes de iniciar upload
    final currentUser = _auth.currentUser;
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

    // Validar arquivo antes do upload
    await UploadValidator.validateMedia(file, isVideo: isVideo);

    if (isVideo) {
      // Upload de vídeo (sem compressão adicional aqui)
      final videoUrl = await _uploadVideo(
        userId: userId,
        mediaId: mediaId,
        file: file,
        onProgress: onProgress,
      );

      return GalleryMediaUrls(full: videoUrl, isVideo: true);
    } else {
      // Upload de imagem com múltiplas resoluções
      return _uploadGalleryImageWithSizes(
        userId: userId,
        mediaId: mediaId,
        file: file,
        onProgress: onProgress,
      );
    }
  }

  /// Faz upload de uma imagem de galeria com múltiplas resoluções
  Future<GalleryMediaUrls> _uploadGalleryImageWithSizes({
    required String userId,
    required String mediaId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    // Gerar múltiplas versões da imagem
    final compressedFiles = await ImageCompressor.generateGalleryPhotoSizes(
      file,
    );

    final thumbnailFuture = compressedFiles.containsKey(ImageSize.thumbnail)
        ? _uploadSingleImage(
            file: compressedFiles[ImageSize.thumbnail]!,
            path: 'gallery_photos/$userId/$mediaId/thumbnail.webp',
            contentType: 'image/webp',
          )
        : Future<String?>.value(null);

    final mediumFuture = compressedFiles.containsKey(ImageSize.medium)
        ? _uploadSingleImage(
            file: compressedFiles[ImageSize.medium]!,
            path: 'gallery_photos/$userId/$mediaId/medium.webp',
            contentType: 'image/webp',
          )
        : Future<String?>.value(null);

    final largeFuture = compressedFiles.containsKey(ImageSize.large)
        ? _uploadSingleImage(
            file: compressedFiles[ImageSize.large]!,
            path: 'gallery_photos/$userId/$mediaId/large.webp',
            contentType: 'image/webp',
          )
        : Future<String?>.value(null);

    final fullFuture = compressedFiles.containsKey(ImageSize.full)
        ? _uploadSingleImageWithProgress(
            file: compressedFiles[ImageSize.full]!,
            path: 'gallery_photos/$userId/$mediaId/full.webp',
            contentType: 'image/webp',
            onProgress: onProgress,
          )
        : Future<String?>.value(null);

    final results = await Future.wait<String?>([
      thumbnailFuture,
      mediumFuture,
      largeFuture,
      fullFuture,
    ]);

    final thumbnailUrl = results[0];
    final mediumUrl = results[1];
    final largeUrl = results[2];
    final fullUrl = results[3];

    return GalleryMediaUrls(
      thumbnail: thumbnailUrl,
      medium: mediumUrl,
      large: largeUrl,
      full: fullUrl ?? largeUrl ?? mediumUrl ?? thumbnailUrl,
      isVideo: false,
    );
  }

  /// Faz upload de um vídeo
  Future<String> _uploadVideo({
    required String userId,
    required String mediaId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child('gallery_videos/$userId/$mediaId.mp4');
    final metadata = SettableMetadata(contentType: 'video/mp4');

    AppLogger.info(
      '📤 Iniciando upload de vídeo: gallery_videos/$userId/$mediaId.mp4',
    );

    final uploadTask = ref.putFile(file, metadata);
    StreamSubscription<TaskSnapshot>? progressSubscription;

    // Listen to progress updates
    if (onProgress != null) {
      progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        final totalBytes = snapshot.totalBytes;
        final progress = totalBytes <= 0
            ? 0.0
            : snapshot.bytesTransferred / totalBytes;
        onProgress(progress);
      });
    }

    try {
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('✅ Upload de vídeo concluído: $downloadUrl');

      return downloadUrl;
    } finally {
      await progressSubscription?.cancel();
    }
  }

  /// Faz upload de uma única imagem
  Future<String> _uploadSingleImage({
    required File file,
    required String path,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    return _uploadSingleImageWithProgress(
      file: file,
      path: path,
      contentType: contentType,
      onProgress: onProgress,
    );
  }

  /// Faz upload de uma única imagem com progresso
  Future<String> _uploadSingleImageWithProgress({
    required File file,
    required String path,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    StreamSubscription<TaskSnapshot>? progressSubscription;
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putFile(file, metadata);

      if (onProgress != null) {
        progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
          final totalBytes = snapshot.totalBytes;
          final progress = totalBytes <= 0
              ? 0.0
              : snapshot.bytesTransferred / totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Erro ao fazer upload da imagem: ${e.message}');
    } finally {
      await progressSubscription?.cancel();
    }
  }

  /// Método legado - faz upload de uma mídia de galeria simples.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  @Deprecated('Use uploadGalleryMediaWithSizes para melhor performance')
  Future<String> uploadGalleryMedia({
    required String userId,
    required File file,
    required String mediaId,
    required bool isVideo,
    void Function(double progress)? onProgress,
  }) async {
    // NOVO: Verificar autenticação antes de iniciar upload
    final currentUser = _auth.currentUser;
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

    // Validar arquivo antes do upload
    await UploadValidator.validateMedia(file, isVideo: isVideo);

    // Comprimir imagem antes do upload (vídeos não são comprimidos aqui)
    final fileToUpload = isVideo
        ? file
        : await ImageCompressor.compressGalleryPhoto(
            file,
            format: ImageFormat.webp,
          );

    try {
      final folder = isVideo ? 'gallery_videos' : 'gallery_photos';
      final ext = isVideo ? 'mp4' : 'webp';
      final contentType = isVideo ? 'video/mp4' : 'image/webp';
      final ref = _storage.ref().child('$folder/$userId/$mediaId.$ext');
      final metadata = SettableMetadata(contentType: contentType);

      AppLogger.info('📤 Iniciando upload: $folder/$userId/$mediaId.$ext');

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

      AppLogger.info('✅ Upload concluído: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      AppLogger.error('❌ Erro Firebase: ${e.code}', e);

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

  /// Faz upload de um thumbnail de vídeo.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  Future<String> uploadVideoThumbnail({
    required String userId,
    required String mediaId,
    required File thumbnail,
    void Function(double progress)? onProgress,
  }) async {
    // Validar thumbnail antes do upload
    await UploadValidator.validateImage(thumbnail);

    // Comprimir thumbnail antes do upload (WebP)
    final compressedThumbnail = await ImageCompressor.compressThumbnail(
      thumbnail,
    );

    return _uploadSingleImage(
      file: compressedThumbnail,
      path: 'gallery_thumbnails/$userId/$mediaId.webp',
      contentType: 'image/webp',
      onProgress: onProgress,
    );
  }

  Future<String?> getTranscodedVideoUrl({
    required String userId,
    required String mediaId,
  }) async {
    final ref = _storage.ref().child(
      'gallery_videos_transcoded/$userId/$mediaId/master.mp4',
    );

    try {
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found' || error.code == 'not-found') {
        return null;
      }

      AppLogger.warning(
        'Falha ao consultar vídeo transcodificado em Storage '
        'user=$userId media=$mediaId',
        error,
        error.stackTrace,
        false,
      );
      return null;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha inesperada ao consultar vídeo transcodificado em Storage '
        'user=$userId media=$mediaId',
        error,
        stackTrace,
        false,
      );
      return null;
    }
  }

  /// Deleta uma imagem dada sua URL (útil para cleanup)
  Future<void> deleteImage(String imageUrl) async {
    final ref = _storage.refFromURL(imageUrl);
    await _deleteIfExists(ref);
  }

  /// Deleta todos os arquivos de um item de galeria (todas as resoluções)
  Future<void> deleteGalleryItem({
    required String userId,
    required String mediaId,
    required bool isVideo,
  }) async {
    if (isVideo) {
      await _deleteAll([
        _storage.ref().child('gallery_videos/$userId/$mediaId.mp4'),
        _storage.ref().child(
          'gallery_videos_transcoded/$userId/$mediaId/master.mp4',
        ),
        _storage.ref().child('gallery_thumbnails/$userId/$mediaId.webp'),
      ]);
      return;
    }

    const resolutions = ['thumbnail', 'medium', 'large', 'full'];
    await _deleteAll(
      resolutions.map(
        (resolution) => _storage.ref().child(
          'gallery_photos/$userId/$mediaId/$resolution.webp',
        ),
      ),
    );
  }

  /// Deleta todas as imagens de perfil de um usuário
  Future<void> deleteProfileImages(String userId) async {
    await _deleteAll([
      _storage.ref().child('profile_photos/$userId/thumbnail.webp'),
      _storage.ref().child('profile_photos/$userId/large.webp'),
      _storage.ref().child('profile_photos/$userId'),
      _storage.ref().child('profile_photos/$userId.webp'),
      _storage.ref().child('profile_photos/$userId.jpg'),
      _storage.ref().child('profile_photos/$userId.jpeg'),
      _storage.ref().child('profile_photos/$userId.png'),
    ]);
  }

  Future<void> _deleteAll(Iterable<Reference> references) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    for (final reference in references) {
      try {
        await _deleteIfExists(reference);
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
        AppLogger.warning(
          'Falha ao excluir arquivo do Storage: ${reference.fullPath}',
          error,
          stackTrace,
          false,
        );
      }
    }

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  Future<void> _deleteIfExists(Reference reference) async {
    try {
      await reference.delete();
    } on FirebaseException catch (error) {
      if (_isMissingStorageObject(error)) return;
      rethrow;
    }
  }

  bool _isMissingStorageObject(FirebaseException error) =>
      error.code == 'object-not-found' || error.code == 'not-found';

  /// Faz upload de um anexo de suporte
  Future<String> uploadSupportAttachment({
    required String ticketId,
    required File file,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Você precisa estar logado para enviar anexos.');
    }

    // Validar arquivo
    await UploadValidator.validateImage(file);

    final compressedFile = await ImageCompressor.compressGalleryPhoto(
      file,
      format: ImageFormat.webp,
    );

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.webp';
    return _uploadSingleImage(
      file: compressedFile,
      path: 'support_tickets/${currentUser.uid}/$ticketId/$fileName',
      contentType: 'image/webp',
    );
  }

  /// Removes every attachment uploaded for a ticket that was not created.
  Future<void> deleteSupportAttachments({required String ticketId}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Você precisa estar logado para excluir anexos.');
    }

    final folder = _storage.ref().child(
      'support_tickets/${currentUser.uid}/$ticketId',
    );
    final result = await folder.listAll();
    await _deleteAll(result.items);
  }
}

/// Modelo para URLs de mídia de galeria
class GalleryMediaUrls {
  final String? thumbnail;
  final String? medium;
  final String? large;
  final String? full;
  final bool isVideo;

  const GalleryMediaUrls({
    this.thumbnail,
    this.medium,
    this.large,
    this.full,
    required this.isVideo,
  });

  /// Retorna a URL mais apropriada para o tamanho solicitado
  String? getUrlForSize(ImageSize size) {
    if (isVideo) return full;

    switch (size) {
      case ImageSize.thumbnail:
        return thumbnail ?? medium ?? large ?? full;
      case ImageSize.medium:
        return medium ?? large ?? full ?? thumbnail;
      case ImageSize.large:
        return large ?? full ?? medium ?? thumbnail;
      case ImageSize.full:
        return full ?? large ?? medium ?? thumbnail;
    }
  }

  /// Retorna a primeira URL disponível
  String? get firstAvailable => thumbnail ?? medium ?? large ?? full;

  Map<String, dynamic> toJson() => {
    'thumbnail': thumbnail,
    'medium': medium,
    'large': large,
    'full': full,
    'isVideo': isVideo,
  };

  factory GalleryMediaUrls.fromJson(Map<String, dynamic> json) {
    return GalleryMediaUrls(
      thumbnail: json['thumbnail'] as String?,
      medium: json['medium'] as String?,
      large: json['large'] as String?,
      full: json['full'] as String?,
      isVideo: json['isVideo'] as bool? ?? false,
    );
  }
}
