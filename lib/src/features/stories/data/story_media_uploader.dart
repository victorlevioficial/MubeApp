import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../features/storage/domain/image_compressor.dart';
import '../../../utils/app_check_refresh_coordinator.dart';
import '../../../utils/app_logger.dart';
import '../domain/story_item.dart';
import '../domain/story_repository_exception.dart';
import '../domain/story_upload_media.dart';

typedef StoryPublishProgressCallback =
    void Function(StoryPublishProgress progress);

/// Refreshes auth/App Check context before retrying a failed upload.
typedef StorySecurityContextRefresher =
    Future<void> Function({
      required String operationLabel,
      bool forceAuthRefresh,
    });

class StoryPublishProgress {
  const StoryPublishProgress({required this.value, required this.label});

  final double value;
  final String label;
}

void emitStoryPublishProgress(
  StoryPublishProgressCallback? onProgress,
  double value,
  String label,
) {
  onProgress?.call(
    StoryPublishProgress(value: clampDouble(value, 0, 1), label: label),
  );
}

/// Uploads story media (image or video) to Firebase Storage, handling
/// compression, progress reporting, retry after security-context refresh,
/// timeouts and temp-file cleanup.
final class StoryMediaUploader {
  StoryMediaUploader(
    this._storage, {
    required StorySecurityContextRefresher ensureSecurityContext,
  }) : _ensureSecurityContext = ensureSecurityContext;

  static const Duration _uploadNoProgressTimeout = Duration(minutes: 2);
  static const Duration _imageUploadCompletionTimeout = Duration(minutes: 4);
  static const Duration _videoUploadCompletionTimeout = Duration(minutes: 10);

  final FirebaseStorage _storage;
  final StorySecurityContextRefresher _ensureSecurityContext;

  Future<StoryMediaUploadResult> uploadStoryMedia({
    required String userId,
    required String storyId,
    required StoryUploadMedia media,
    StoryPublishProgressCallback? onProgress,
  }) async {
    if (media.mediaType == StoryMediaType.image) {
      return _uploadImageStory(
        userId: userId,
        storyId: storyId,
        media: media,
        onProgress: onProgress,
      );
    }

    return _uploadVideoStory(
      userId: userId,
      storyId: storyId,
      media: media,
      onProgress: onProgress,
    );
  }

  Future<StoryMediaUploadResult> _uploadImageStory({
    required String userId,
    required String storyId,
    required StoryUploadMedia media,
    StoryPublishProgressCallback? onProgress,
  }) async {
    File fullFile;
    File thumbFile;
    var compressionSucceeded = true;
    try {
      emitStoryPublishProgress(onProgress, 0.12, 'Otimizando foto');
      fullFile = await ImageCompressor.compressGalleryPhoto(
        media.file,
        format: ImageFormat.webp,
      );
      thumbFile = await ImageCompressor.compressThumbnail(media.file);
      compressionSucceeded =
          fullFile.path != media.file.path && thumbFile.path != media.file.path;
    } catch (e, stack) {
      AppLogger.error('Falha ao comprimir imagem do story', e, stack);
      fullFile = media.file;
      thumbFile = media.file;
      compressionSucceeded = false;
    }
    final fullUploadTarget = compressionSucceeded
        ? resolveImageUploadTarget(
            file: fullFile,
            basePathWithoutExtension: 'stories_images/$userId/$storyId/full',
          )
        : resolveOriginalImageUploadTarget(
            file: fullFile,
            basePathWithoutExtension: 'stories_images/$userId/$storyId/full',
          );
    final thumbUploadTarget = compressionSucceeded
        ? resolveImageUploadTarget(
            file: thumbFile,
            basePathWithoutExtension: 'stories_images/$userId/$storyId/thumb',
          )
        : resolveOriginalImageUploadTarget(
            file: thumbFile,
            basePathWithoutExtension: 'stories_images/$userId/$storyId/thumb',
          );

    final fullUrl = await _uploadFile(
      file: fullFile,
      path: fullUploadTarget.path,
      contentType: fullUploadTarget.contentType,
      onProgress: (progress) {
        emitStoryPublishProgress(
          onProgress,
          _progressBetween(progress, start: 0.18, end: 0.78),
          'Enviando foto',
        );
      },
    );
    final thumbUrl = await _uploadFile(
      file: thumbFile,
      path: thumbUploadTarget.path,
      contentType: thumbUploadTarget.contentType,
      onProgress: (progress) {
        emitStoryPublishProgress(
          onProgress,
          _progressBetween(progress, start: 0.78, end: 0.9),
          'Enviando preview',
        );
      },
    );

    // Clean up the compressed temp files we created (never the user's original).
    await _deleteTempFileIfNeeded(fullFile, keep: media.file);
    await _deleteTempFileIfNeeded(thumbFile, keep: media.file);

    return StoryMediaUploadResult(mediaUrl: fullUrl, thumbnailUrl: thumbUrl);
  }

  Future<StoryMediaUploadResult> _uploadVideoStory({
    required String userId,
    required String storyId,
    required StoryUploadMedia media,
    StoryPublishProgressCallback? onProgress,
  }) async {
    File? thumbFile;
    if (media.thumbnailFile != null) {
      try {
        emitStoryPublishProgress(onProgress, 0.12, 'Preparando thumb do video');
        thumbFile = await ImageCompressor.compressThumbnail(
          media.thumbnailFile!,
        );
      } catch (e, stack) {
        AppLogger.error('Falha ao comprimir thumbnail do video', e, stack);
        thumbFile = media.thumbnailFile;
      }
    }

    if (!await media.file.exists()) {
      throw StoryRepositoryException.uploadFileMissing();
    }

    String? thumbUrl;
    if (thumbFile != null) {
      try {
        final webpThumb = await _ensureWebpThumbnail(thumbFile);
        // Upload the thumbnail before the source video. The Storage trigger
        // starts as soon as source.mp4 is finalized, so this keeps the preview
        // available when the transcode worker activates the story.
        thumbUrl = await _uploadFile(
          file: webpThumb,
          path: 'stories_videos_thumbs/$userId/$storyId/thumb.webp',
          contentType: 'image/webp',
          onProgress: (progress) {
            emitStoryPublishProgress(
              onProgress,
              _progressBetween(progress, start: 0.18, end: 0.28),
              'Enviando preview',
            );
          },
        );
        await _deleteTempFileIfNeeded(webpThumb, keep: media.thumbnailFile);
      } catch (e, stack) {
        AppLogger.warning(
          'Falha ao upload thumbnail, continuando sem',
          e,
          stack,
        );
      }
    }

    final videoUrl = await _uploadFile(
      file: media.file,
      path: 'stories_videos_source/$userId/$storyId/source.mp4',
      contentType: 'video/mp4',
      onProgress: (progress) {
        emitStoryPublishProgress(
          onProgress,
          _progressBetween(
            progress,
            start: thumbUrl == null ? 0.18 : 0.28,
            end: 0.92,
          ),
          'Enviando video',
        );
      },
    );

    return StoryMediaUploadResult(mediaUrl: videoUrl, thumbnailUrl: thumbUrl);
  }

  Future<File> _ensureWebpThumbnail(File source) async {
    if (path.extension(source.path).toLowerCase() == '.webp') {
      return source;
    }

    final bytes = await ImageCompressor.compressToBytes(
      source,
      maxWidth: ImageCompressor.thumbnailMaxWidth,
      quality: ImageCompressor.thumbnailQuality,
      format: ImageFormat.webp,
    );
    if (bytes == null || bytes.isEmpty) {
      return source;
    }

    final tempDir = await getTemporaryDirectory();
    final outputPath = path.join(
      tempDir.path,
      'story_video_thumb_${DateTime.now().millisecondsSinceEpoch}.webp',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(bytes);
    return outputFile;
  }

  Future<String> _uploadFile({
    required File file,
    required String path,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      return await _uploadFileOnce(
        file: file,
        path: path,
        contentType: contentType,
        onProgress: onProgress,
      );
    } on FirebaseException catch (error, stackTrace) {
      if (!_isRecoverableStorageError(error)) {
        AppLogger.error('Firebase upload error: $path', error, stackTrace);
        throw _mapUploadFirebaseException(error, contentType);
      }

      AppLogger.warning(
        'Upload de story retornou ${error.code}. Atualizando contexto e tentando novamente.',
        error,
        stackTrace,
      );
      await _ensureSecurityContext(
        operationLabel: 'retry de upload de story',
        forceAuthRefresh: true,
      );
      try {
        return await _uploadFileOnce(
          file: file,
          path: path,
          contentType: contentType,
          onProgress: onProgress,
        );
      } on FirebaseException catch (retryError, retryStackTrace) {
        AppLogger.error(
          'Firebase upload retry error: $path',
          retryError,
          retryStackTrace,
        );
        throw _mapUploadFirebaseException(retryError, contentType);
      }
    } on TimeoutException catch (error, stackTrace) {
      AppLogger.error('Upload timeout: $path', error, stackTrace);
      throw StoryRepositoryException.uploadFailed(
        _isVideoContentType(contentType)
            ? 'O envio do video demorou demais. Tente novamente em uma rede melhor ou com um video menor.'
            : 'O envio da foto demorou demais. Tente novamente em uma rede melhor.',
      );
    } on AppCheckRefreshException catch (error, stackTrace) {
      AppLogger.error('App Check upload error: $path', error, stackTrace);
      throw StoryRepositoryException.uploadFailed(error.message);
    } on StoryRepositoryException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Upload error: $path', e, stack);
      throw StoryRepositoryException.uploadFailed();
    }
  }

  Future<String> _uploadFileOnce({
    required File file,
    required String path,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    StreamSubscription<TaskSnapshot>? progressSubscription;
    try {
      if (!await file.exists()) {
        throw StoryRepositoryException.uploadFileMissing();
      }
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putFile(file, metadata);
      onProgress?.call(0);
      progressSubscription = uploadTask.snapshotEvents
          .timeout(
            _uploadNoProgressTimeout,
            onTimeout: (sink) {
              AppLogger.warning(
                'Upload de story sem evento de progresso recente: $path',
              );
              sink.close();
            },
          )
          .listen((snapshot) {
            final totalBytes = snapshot.totalBytes;
            final rawProgress = totalBytes > 0
                ? snapshot.bytesTransferred / totalBytes
                : (snapshot.state == TaskState.success ? 1.0 : 0.0);
            onProgress?.call(clampDouble(rawProgress, 0, 1));
          });
      final timeout = _uploadCompletionTimeout(contentType);
      final snapshot = await uploadTask.timeout(
        timeout,
        onTimeout: () {
          unawaited(uploadTask.cancel());
          throw TimeoutException('Story upload timed out.', timeout);
        },
      );
      onProgress?.call(1);
      return await snapshot.ref.getDownloadURL();
    } finally {
      await progressSubscription?.cancel();
    }
  }

  Duration _uploadCompletionTimeout(String contentType) {
    return _isVideoContentType(contentType)
        ? _videoUploadCompletionTimeout
        : _imageUploadCompletionTimeout;
  }

  bool _isVideoContentType(String contentType) {
    return contentType.toLowerCase().startsWith('video/');
  }

  bool _isRecoverableStorageError(FirebaseException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code == 'unauthenticated' || code == 'unauthorized') return true;

    final mentionsAppCheck = message.contains('app check');
    return mentionsAppCheck &&
        (code == 'failed-precondition' || code == 'permission-denied');
  }

  StoryRepositoryException _mapUploadFirebaseException(
    FirebaseException error,
    String contentType,
  ) {
    final code = error.code.toLowerCase();
    if (code == 'canceled') {
      return StoryRepositoryException.uploadFailed(
        _isVideoContentType(contentType)
            ? 'O envio do video foi interrompido. Tente novamente em uma rede melhor ou com um video menor.'
            : 'O envio da foto foi interrompido. Tente novamente.',
      );
    }

    if (code == 'permission-denied' ||
        code == 'unauthorized' ||
        code == 'unauthenticated') {
      return StoryRepositoryException.uploadFailed(
        'Nao foi possivel validar sua sessao para enviar o story. Feche e abra o app, ou faca login novamente.',
      );
    }

    return StoryRepositoryException.uploadFailed(
      'Erro ao enviar arquivo: ${error.message ?? 'tente novamente'}',
    );
  }

  double _progressBetween(
    double progress, {
    required double start,
    required double end,
  }) {
    final normalizedProgress = clampDouble(progress, 0, 1);
    return start + ((end - start) * normalizedProgress);
  }

  // Best-effort cleanup of the temporary files we generate during upload
  // (compressed image/thumbnail, transcoded webp thumb). Never deletes the
  // user's original [keep] file.
  Future<void> _deleteTempFileIfNeeded(File file, {File? keep}) async {
    try {
      if (keep != null && file.path == keep.path) return;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao limpar arquivo temporario do story',
        error,
        stackTrace,
      );
    }
  }

  @visibleForTesting
  static StoryImageUploadTarget resolveImageUploadTarget({
    required File file,
    required String basePathWithoutExtension,
  }) {
    final extension = path.extension(file.path).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.jpg',
        contentType: 'image/jpeg',
      ),
      '.png' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.png',
        contentType: 'image/png',
      ),
      '.gif' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.gif',
        contentType: 'image/gif',
      ),
      _ => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.webp',
        contentType: 'image/webp',
      ),
    };
  }

  // When compression fails, the original file extension may be HEIC, HEIF, or
  // some other format whose default resolution would tag it as webp — leading
  // to a content-type/path mismatch on Storage. Fall back to JPEG, which the
  // image picker normalizes the input to on most platforms.
  @visibleForTesting
  static StoryImageUploadTarget resolveOriginalImageUploadTarget({
    required File file,
    required String basePathWithoutExtension,
  }) {
    final extension = path.extension(file.path).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.jpg',
        contentType: 'image/jpeg',
      ),
      '.png' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.png',
        contentType: 'image/png',
      ),
      '.webp' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.webp',
        contentType: 'image/webp',
      ),
      _ => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.jpg',
        contentType: 'image/jpeg',
      ),
    };
  }
}

class StoryMediaUploadResult {
  const StoryMediaUploadResult({
    required this.mediaUrl,
    required this.thumbnailUrl,
  });

  final String mediaUrl;
  final String? thumbnailUrl;
}

class StoryImageUploadTarget {
  const StoryImageUploadTarget({required this.path, required this.contentType});

  final String path;
  final String contentType;
}
