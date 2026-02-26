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

/// Service for picking, cropping and compressing media files.
class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  static const int maxVideoDurationSeconds = 30;

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

    return File(croppedFile.path);
  }

  /// Pick a video, validate duration <= 30s, compress and generate thumbnail.
  /// Returns (videoFile, thumbnailFile) or null if cancelled/invalid.
  Future<(File video, File thumbnail)?> pickAndProcessVideo(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
  }) async {
    final maxDuration = source == ImageSource.camera
        ? const Duration(seconds: maxVideoDurationSeconds)
        : null;

    final XFile? picked = await _picker.pickVideo(
      source: source,
      maxDuration: maxDuration,
    );

    if (picked == null) return null;

    try {
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
    } catch (e) {
      // video_compress can crash on low-end devices — show friendly error
      if (context.mounted) {
        AppSnackBar.error(
          context,
          'Erro ao processar vídeo. Tente um vídeo menor.',
        );
      }
      return null;
    }
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
