import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Utility class for compressing images before upload.
///
/// This helps reduce:
/// - Upload time
/// - Storage costs
/// - Bandwidth usage
class ImageCompressor {
  /// Maximum width for profile photos (maintains aspect ratio).
  static const int profileMaxWidth = 800;

  /// Maximum width for gallery photos (maintains aspect ratio).
  static const int galleryMaxWidth = 1920;

  /// Maximum width for video thumbnails.
  static const int thumbnailMaxWidth = 600;

  /// JPEG quality for profile photos (0-100).
  static const int profileQuality = 85;

  /// JPEG quality for gallery photos (0-100).
  static const int galleryQuality = 80;

  /// JPEG quality for thumbnails (0-100).
  static const int thumbnailQuality = 75;

  /// Compresses an image file and returns a new compressed file.
  ///
  /// Returns the original file if compression fails or if the compressed
  /// file is larger than the original.
  static Future<File> compressImage(
    File file, {
    int maxWidth = galleryMaxWidth,
    int quality = galleryQuality,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final originalSize = bytes.length;

      // Compress the image
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxWidth,
        minHeight: maxWidth, // This maintains aspect ratio
        quality: quality,
        format: CompressFormat.jpeg,
      );

      final compressedSize = compressed.length;

      // Only use compressed version if it's actually smaller
      if (compressedSize >= originalSize) {
        return file;
      }

      // Save compressed image to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File(
        path.join(tempDir.path, 'compressed_$timestamp.jpg'),
      );

      await compressedFile.writeAsBytes(compressed);

      debugPrint(
        'ImageCompressor: Compressed ${(originalSize / 1024).toStringAsFixed(1)}KB → '
        '${(compressedSize / 1024).toStringAsFixed(1)}KB '
        '(${((1 - compressedSize / originalSize) * 100).toStringAsFixed(0)}% reduction)',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('ImageCompressor: Error compressing image: $e');
      return file; // Return original on any error
    }
  }

  /// Compresses a profile photo with appropriate settings.
  static Future<File> compressProfilePhoto(File file) {
    return compressImage(
      file,
      maxWidth: profileMaxWidth,
      quality: profileQuality,
    );
  }

  /// Compresses a gallery photo with appropriate settings.
  static Future<File> compressGalleryPhoto(File file) {
    return compressImage(
      file,
      maxWidth: galleryMaxWidth,
      quality: galleryQuality,
    );
  }

  /// Compresses a video thumbnail with appropriate settings.
  static Future<File> compressThumbnail(File file) {
    return compressImage(
      file,
      maxWidth: thumbnailMaxWidth,
      quality: thumbnailQuality,
    );
  }
}
