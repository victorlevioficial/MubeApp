import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';
import '../../../storage/domain/upload_validator.dart';
import '../widgets/video_trim_screen.dart';

/// Service for picking, cropping and compressing media files.
class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  static const int maxVideoDurationSeconds = 60;
  static const int _maxVideoDurationMs = maxVideoDurationSeconds * 1000;
  static const int _processedDurationToleranceMs = 500;

  /// Show a bottom sheet letting the user choose between Camera and Gallery.
  /// Returns the chosen [ImageSource] or null if cancelled.
  static Future<ImageSource?> showMediaSourcePicker(
    BuildContext context, {
    required String title,
    required IconData cameraIcon,
    required String cameraLabel,
    required IconData galleryIcon,
    required String galleryLabel,
  }) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: AppRadius.pill,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(title, style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.s24),
              _SourceOption(
                icon: cameraIcon,
                label: cameraLabel,
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: AppSpacing.s12),
              _SourceOption(
                icon: galleryIcon,
                label: galleryLabel,
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick and crop a photo with configurable aspect ratio.
  /// Returns null if user cancels.
  Future<File?> pickAndCropPhoto(
    BuildContext context, {
    bool lockAspectRatio = true,
    ImageSource source = ImageSource.gallery,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );

    if (picked == null) return null;

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
    return File(croppedFile.path);
  }

  /// Pick one or more photos without in-app crop.
  /// Gallery allows multi-select; camera returns a single file.
  Future<List<File>?> pickPhotos({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (source == ImageSource.gallery) {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (pickedFiles.isEmpty) return null;
      return pickedFiles.map((file) => File(file.path)).toList();
    }

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );

    if (picked == null) return null;
    return [File(picked.path)];
  }

  /// Pick a video from gallery, trim when needed (max 60s),
  /// then return the processed video + thumbnail.
  Future<(File video, File thumbnail)?> pickAndProcessVideo(
    BuildContext context,
  ) async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return null;

    try {
      File finalVideoFile = File(picked.path);
      var wasTrimmed = false;

      final mediaInfo = await VideoCompress.getMediaInfo(finalVideoFile.path);
      final durationMs = (mediaInfo.duration ?? 0).round();
      if (durationMs > _maxVideoDurationMs) {
        if (!context.mounted) return null;
        final trimmedVideo = await _openVideoTrimmer(
          context,
          finalVideoFile.path,
        );
        if (trimmedVideo == null) return null;
        finalVideoFile = trimmedVideo;
        wasTrimmed = true;
      }

      final shouldCompress = !wasTrimmed;
      if (shouldCompress) {
        finalVideoFile = await _compressVideo(finalVideoFile);
      }

      final finalInfo = await VideoCompress.getMediaInfo(finalVideoFile.path);
      final finalDurationMs = (finalInfo.duration ?? 0).round();
      if (finalDurationMs >
          _maxVideoDurationMs + _processedDurationToleranceMs) {
        if (context.mounted) {
          AppSnackBar.error(
            context,
            'Nao foi possivel ajustar o video para 1 minuto. Tente novamente.',
          );
        }
        return null;
      }

      try {
        await UploadValidator.validateVideo(finalVideoFile);
      } on UploadValidationException catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, e.message);
        }
        return null;
      }

      final thumbnail = await VideoCompress.getFileThumbnail(
        finalVideoFile.path,
        quality: 75,
        position: 0,
      );
      return (finalVideoFile, thumbnail);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Video processing failed path=${picked.path}',
        error,
        stackTrace,
      );
      if (context.mounted) {
        AppSnackBar.error(context, 'Erro ao processar video. Tente novamente.');
      }
      return null;
    }
  }

  Future<File?> _openVideoTrimmer(
    BuildContext context,
    String videoPath,
  ) async {
    return Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (_) => VideoTrimScreen(
          videoPath: videoPath,
          maxDurationSeconds: maxVideoDurationSeconds,
        ),
      ),
    );
  }

  Future<File> _compressVideo(File sourceFile) async {
    final compressedVideo = await VideoCompress.compressVideo(
      sourceFile.path,
      quality: VideoQuality.Res640x480Quality,
      deleteOrigin: false,
      includeAudio: true,
    );

    return compressedVideo?.file ?? sourceFile;
  }

  /// Dispose video compress resources.
  void dispose() {
    VideoCompress.dispose();
  }
}

/// Internal widget for the source picker bottom sheet options.
class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all12,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
            borderRadius: AppRadius.all12,
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(label, style: AppTypography.titleMedium),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
