import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../utils/app_logger.dart';
import '../domain/image_compressor.dart';
import '../domain/upload_validator.dart';

part 'storage_repository.g.dart';

@Riverpod(keepAlive: true)
StorageRepository storageRepository(Ref ref) {
  return StorageRepository(FirebaseStorage.instance);
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

  StorageRepository(this._storage);

  /// Faz upload de uma imagem de perfil em múltiplas resoluções.
  /// Retorna um [ImageUrls] com as URLs de cada resolução.
  ///
  /// Throws [UploadValidationException] if file is invalid.
  Future<ImageUrls> uploadProfileImageWithSizes({
    required String userId,
    required File file,
    bool generateMultipleSizes = true,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception(
        'Voce precisa estar logado para atualizar a foto de perfil.',
      );
    }

    if (currentUser.uid != userId) {
      throw Exception(
        'Erro de autenticacao: usuario logado diferente do perfil alvo.',
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
    AppLogger.info(
      '🔐 DEBUG Storage Upload: Type=${isVideo ? "Video" : "Photo"}, User=$userId, Auth=${currentUser.email}',
    );

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

    // Listen to progress updates
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    AppLogger.info('✅ Upload de vídeo concluído: $downloadUrl');

    return downloadUrl;
  }

  /// Faz upload de uma única imagem
  Future<String> _uploadSingleImage({
    required File file,
    required String path,
    required String contentType,
  }) async {
    return _uploadSingleImageWithProgress(
      file: file,
      path: path,
      contentType: contentType,
    );
  }

  /// Faz upload de uma única imagem com progresso
  Future<String> _uploadSingleImageWithProgress({
    required File file,
    required String path,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putFile(file, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Erro ao fazer upload da imagem: ${e.message}');
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
    AppLogger.info(
      '🔐 DEBUG Storage Upload: Type=${isVideo ? "Video" : "Photo"}, User=$userId, Auth=${currentUser.email}',
    );

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
    );
  }

  /// Deleta uma imagem dada sua URL (útil para cleanup)
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore if not found or already deleted
    }
  }

  /// Deleta todos os arquivos de um item de galeria (todas as resoluções)
  Future<void> deleteGalleryItem({
    required String userId,
    required String mediaId,
    required bool isVideo,
  }) async {
    try {
      if (isVideo) {
        // Deletar vídeo
        final videoRef = _storage.ref().child(
          'gallery_videos/$userId/$mediaId.mp4',
        );
        await videoRef.delete();

        // Deletar thumbnail
        final thumbRef = _storage.ref().child(
          'gallery_thumbnails/$userId/$mediaId.webp',
        );
        await thumbRef.delete();
      } else {
        // Deletar todas as resoluções da imagem
        final resolutions = ['thumbnail', 'medium', 'large', 'full'];
        for (final resolution in resolutions) {
          try {
            final ref = _storage.ref().child(
              'gallery_photos/$userId/$mediaId/$resolution.webp',
            );
            await ref.delete();
          } catch (e) {
            // Ignora se não encontrar uma resolução específica
          }
        }
      }
    } catch (e) {
      // Ignore if not found
    }
  }

  /// Deleta todas as imagens de perfil de um usuário
  Future<void> deleteProfileImages(String userId) async {
    try {
      // Deletar thumbnail
      try {
        final thumbRef = _storage.ref().child(
          'profile_photos/$userId/thumbnail.webp',
        );
        await thumbRef.delete();
      } catch (e) {
        // Ignora se não existir
      }

      // Deletar large
      try {
        final largeRef = _storage.ref().child(
          'profile_photos/$userId/large.webp',
        );
        await largeRef.delete();
      } catch (e) {
        // Ignora se não existir
      }

      // Deletar versão antiga (compatibilidade)
      try {
        final oldRef = _storage.ref().child('profile_photos/$userId.webp');
        await oldRef.delete();
      } catch (e) {
        // Ignora se não existir
      }

      // Deletar versão muito antiga (jpg)
      try {
        final veryOldRef = _storage.ref().child('profile_photos/$userId.jpg');
        await veryOldRef.delete();
      } catch (e) {
        // Ignora se não existir
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Faz upload de um anexo de suporte
  Future<String> uploadSupportAttachment({
    required String ticketId,
    required File file,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Voce precisa estar logado para enviar anexos.');
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
