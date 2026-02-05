import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';

/// Service for picking, cropping and compressing media files.
class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  static const int maxVideoDurationSeconds = 30;
  static const int photoQuality = 80;
  static const int photoMaxWidth = 1080;
  static const int photoMaxHeight = 1080;

  /// Pick and crop a photo with 1:1 aspect ratio.
  /// Returns null if user cancels.
  Future<File?> pickAndCropPhoto(
    BuildContext context, {
    bool lockAspectRatio = true,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
    );

    if (picked == null) return null;

    // Crop to 1:1 square
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: lockAspectRatio
          ? const CropAspectRatio(ratioX: 1, ratioY: 1)
          : null,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar Foto',
          toolbarColor: AppColors.background,
          toolbarWidgetColor: AppColors.textPrimary,
          backgroundColor: AppColors.background,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: lockAspectRatio,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: lockAspectRatio
              ? [CropAspectRatioPreset.square]
              : [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
        ),
        IOSUiSettings(
          title: 'Ajustar Foto',
          aspectRatioLockEnabled: lockAspectRatio,
          resetAspectRatioEnabled: !lockAspectRatio,
          aspectRatioPresets: lockAspectRatio
              ? [CropAspectRatioPreset.square]
              : [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9,
                ],
        ),
      ],
    );

    if (croppedFile == null) return null;

    // Compress the cropped image
    final compressedFile = await _compressImage(File(croppedFile.path));
    return compressedFile;
  }

  /// Pick a video, validate duration <= 60s, compress and generate thumbnail.
  /// Returns (videoFile, thumbnailFile) or null if cancelled/invalid.
  Future<(File video, File thumbnail)?> pickAndProcessVideo(
    BuildContext context,
  ) async {
    final XFile? picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(
        seconds: maxVideoDurationSeconds + 5,
      ), // buffer
    );

    if (picked == null) return null;

    // Get video info to check duration
    final mediaInfo = await VideoCompress.getMediaInfo(picked.path);
    final durationSeconds = (mediaInfo.duration ?? 0) / 1000;

    if (durationSeconds > maxVideoDurationSeconds) {
      // Duration exceeds limit - show error
      if (context.mounted) {
        AppSnackBar.error(
          context,
          'Vídeo muito longo! Máximo de $maxVideoDurationSeconds segundos.',
        );
      }
      return null;
    }

    // Compress video to 480p for smaller file size
    final compressedVideo = await VideoCompress.compressVideo(
      picked.path,
      quality: VideoQuality.Res640x480Quality,
      deleteOrigin: false,
      includeAudio: true,
    );

    if (compressedVideo?.file == null) return null;

    // Generate thumbnail
    final thumbnail = await VideoCompress.getFileThumbnail(
      picked.path,
      quality: 75,
      position: 0,
    );

    return (compressedVideo!.file!, thumbnail);
  }

  /// Compress an image file.
  Future<File?> _compressImage(File file) async {
    final String targetPath = file.path.replaceAll(
      RegExp(r'\.[^.]+$'),
      '_compressed.jpg',
    );

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: photoQuality,
      minWidth: photoMaxWidth,
      minHeight: photoMaxHeight,
      format: CompressFormat.jpeg,
    );

    return result != null ? File(result.path) : null;
  }

  /// Dispose video compress resources.
  void dispose() {
    VideoCompress.dispose();
  }
}
