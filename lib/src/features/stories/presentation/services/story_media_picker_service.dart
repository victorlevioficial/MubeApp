import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../utils/app_logger.dart';
import '../../../profile/presentation/services/media_picker_service.dart';
import '../../../storage/domain/image_compressor.dart';
import '../../../storage/domain/upload_validator.dart';
import '../../domain/story_constants.dart';
import '../../domain/story_item.dart';
import '../../domain/story_upload_media.dart';

class StoryMediaSelection {
  final File file;
  final StoryMediaType mediaType;
  final File? thumbnail;
  final double? durationSeconds;
  final double? aspectRatio;

  const StoryMediaSelection({
    required this.file,
    required this.mediaType,
    required this.thumbnail,
    required this.durationSeconds,
    required this.aspectRatio,
  });
}

class StoryMediaPickerService {
  static const int maxStoryVideoSeconds = 15;
  static const int _preferredStoryVideoSizeBytes = 18 * 1024 * 1024;
  final ImagePicker _picker = ImagePicker();

  Future<StoryUploadMedia?> pickImage(BuildContext context) async {
    final source = await chooseSource(
      context,
      title: 'Escolha a origem da foto',
    );
    if (source == null) return null;
    if (!context.mounted) return null;

    final selection = await pickPhoto(context, source: source);
    if (selection == null) return null;

    return StoryUploadMedia(
      file: selection.file,
      mediaType: selection.mediaType,
      aspectRatio: selection.aspectRatio ?? StoryConstants.targetAspectRatio,
      fromCamera: source == ImageSource.camera,
      durationSeconds: null,
    );
  }

  Future<StoryUploadMedia?> pickVideo(BuildContext context) async {
    final source = await chooseSource(
      context,
      title: 'Escolha a origem do vídeo',
    );
    if (source == null) return null;
    if (!context.mounted) return null;

    final selection = await pickVideoFromSource(context, source: source);
    if (selection == null) return null;

    return StoryUploadMedia(
      file: selection.file,
      mediaType: selection.mediaType,
      aspectRatio: selection.aspectRatio ?? StoryConstants.targetAspectRatio,
      fromCamera: source == ImageSource.camera,
      thumbnailFile: selection.thumbnail,
      durationSeconds: selection.durationSeconds?.round(),
    );
  }

  Future<StoryMediaSelection?> pickPhoto(
    BuildContext context, {
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1440,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    final originalFile = File(picked.path);
    final croppedFile = await _cropPhotoToStoryRatio(originalFile);
    if (croppedFile == null) return null;

    try {
      final file = await _normalizePhotoForStoryUpload(croppedFile);
      await UploadValidator.validateImage(file);
      final aspectRatio = await _readImageAspectRatio(file);
      if (!StoryMediaPickerService.isSupportedStoryImageAspectRatio(
        aspectRatio,
      )) {
        if (context.mounted) {
          AppSnackBar.error(
            context,
            'A foto precisa ser vertical no formato stories.',
          );
        }
        return null;
      }

      return StoryMediaSelection(
        file: file,
        mediaType: StoryMediaType.image,
        thumbnail: null,
        durationSeconds: null,
        aspectRatio: aspectRatio,
      );
    } on UploadValidationException catch (error) {
      if (context.mounted) {
        AppSnackBar.error(context, error.message);
      }
      return null;
    }
  }

  Future<File> _normalizePhotoForStoryUpload(File file) async {
    final extension = path.extension(file.path).toLowerCase();
    if (UploadLimits.allowedImageExtensions.contains(extension)) {
      return file;
    }

    final jpegBytes = await ImageCompressor.compressToBytes(
      file,
      maxWidth: 1440,
      quality: 90,
      format: ImageFormat.jpeg,
    );
    if (jpegBytes == null || jpegBytes.isEmpty) {
      throw const UploadValidationException(
        'Nao foi possivel preparar essa foto. Tente outra imagem.',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final outputPath = path.join(
      tempDir.path,
      'story_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(jpegBytes);
    return outputFile;
  }

  Future<StoryMediaSelection?> pickVideoFromSource(
    BuildContext context, {
    required ImageSource source,
  }) async {
    final picked = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: maxStoryVideoSeconds),
    );
    if (picked == null) return null;

    try {
      var file = File(picked.path);
      if (!await file.exists()) {
        throw const UploadValidationException(
          'Arquivo não encontrado. Por favor, selecione outro arquivo.',
        );
      }

      file = await _normalizeVideoIfNeeded(file);
      await UploadValidator.validateVideo(file);

      final metadata = await _readVideoMetadata(file);
      if (metadata.durationSeconds > maxStoryVideoSeconds + 0.5) {
        if (context.mounted) {
          AppSnackBar.error(
            context,
            'O video precisa ter no maximo 15 segundos.',
          );
        }
        return null;
      }

      if (!StoryMediaPickerService.isSupportedStoryVideoAspectRatio(
        metadata.aspectRatio,
      )) {
        if (context.mounted) {
          AppSnackBar.error(
            context,
            'O video precisa ser vertical no formato stories.',
          );
        }
        return null;
      }

      final thumbnail = await VideoCompress.getFileThumbnail(
        file.path,
        quality: 75,
        position: 0,
      );

      return StoryMediaSelection(
        file: file,
        mediaType: StoryMediaType.video,
        thumbnail: thumbnail,
        durationSeconds: metadata.durationSeconds,
        aspectRatio: metadata.aspectRatio,
      );
    } on UploadValidationException catch (error) {
      if (context.mounted) {
        AppSnackBar.error(context, error.message);
      }
      return null;
    } catch (error, stackTrace) {
      AppLogger.error('Falha ao preparar video de story', error, stackTrace);
      if (context.mounted) {
        AppSnackBar.error(context, 'Nao foi possivel preparar o video.');
      }
      return null;
    }
  }

  Future<double?> _readImageAspectRatio(File file) async {
    final bytes = await file.readAsBytes();
    final image = await decodeImageFromList(bytes);
    if (image.height == 0) return null;
    return image.width / image.height;
  }

  Future<File?> _cropPhotoToStoryRatio(File file) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar story',
          toolbarColor: AppColors.background,
          toolbarWidgetColor: AppColors.textPrimary,
          backgroundColor: AppColors.background,
          activeControlsWidgetColor: AppColors.primary,
          dimmedLayerColor: AppColors.background.withValues(alpha: 0.92),
          cropFrameColor: AppColors.primary.withValues(alpha: 0.7),
          cropGridColor: AppColors.textPrimary.withValues(alpha: 0.12),
          statusBarLight: false,
          navBarLight: false,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Ajustar story',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return null;
    return File(croppedFile.path);
  }

  Future<File> mirrorImageHorizontally(File sourceFile) async {
    final sourceBytes = await sourceFile.readAsBytes();
    final sourceImage = await decodeImageFromList(sourceBytes);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.translate(sourceImage.width.toDouble(), 0);
    canvas.scale(-1, 1);
    canvas.drawImage(sourceImage, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final mirroredImage = await picture.toImage(
      sourceImage.width,
      sourceImage.height,
    );
    final byteData = await mirroredImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception('Nao foi possivel espelhar a foto selecionada.');
    }

    final tempDir = await getTemporaryDirectory();
    final outputPath = path.join(
      tempDir.path,
      'story_mirror_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(byteData.buffer.asUint8List());
    return outputFile;
  }

  Future<ImageSource?> chooseSource(
    BuildContext context, {
    required String title,
  }) {
    return MediaPickerService.showMediaSourcePicker(
      context,
      title: title,
      cameraIcon: Icons.photo_camera_outlined,
      cameraLabel: 'Câmera',
      galleryIcon: Icons.photo_library_outlined,
      galleryLabel: 'Galeria',
    );
  }

  Future<File> _normalizeVideoIfNeeded(File sourceFile) async {
    final fileSizeBytes = await sourceFile.length();
    final shouldNormalize = StoryMediaPickerService.requiresVideoNormalization(
      videoPath: sourceFile.path,
      fileSizeBytes: fileSizeBytes,
    );
    if (!shouldNormalize) return sourceFile;

    final compressed = await VideoCompress.compressVideo(
      sourceFile.path,
      quality: VideoQuality.Res960x540Quality,
      deleteOrigin: false,
      includeAudio: true,
    );
    return compressed?.file ?? sourceFile;
  }

  @visibleForTesting
  static bool requiresVideoNormalization({
    required String videoPath,
    required int fileSizeBytes,
  }) {
    return path.extension(videoPath).toLowerCase() != '.mp4' ||
        fileSizeBytes > _preferredStoryVideoSizeBytes;
  }

  @visibleForTesting
  static bool isSupportedStoryImageAspectRatio(double? aspectRatio) {
    return aspectRatio != null &&
        StoryConstants.isExactStoryPhotoAspectRatio(aspectRatio);
  }

  @visibleForTesting
  static bool isSupportedStoryVideoAspectRatio(double? aspectRatio) {
    return aspectRatio != null &&
        StoryConstants.isSupportedStoryAspectRatio(aspectRatio);
  }

  Future<_VideoMetadata> _readVideoMetadata(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      // `controller.value.aspectRatio` is normalized for the video's display
      // rotation. Reading `size.width / size.height` would treat a portrait
      // clip with rotation metadata as landscape and falsely reject it.
      final reportedAspectRatio = controller.value.aspectRatio;
      final aspectRatio = reportedAspectRatio > 0 ? reportedAspectRatio : null;
      return _VideoMetadata(
        durationSeconds: controller.value.duration.inMilliseconds / 1000,
        aspectRatio: aspectRatio,
      );
    } finally {
      await controller.dispose();
    }
  }

  void dispose() {
    VideoCompress.dispose();
  }
}

class _VideoMetadata {
  final double durationSeconds;
  final double? aspectRatio;

  const _VideoMetadata({
    required this.durationSeconds,
    required this.aspectRatio,
  });
}
