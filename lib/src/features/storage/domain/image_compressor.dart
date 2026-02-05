import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Enum para definir o formato de compressão da imagem
enum ImageFormat {
  jpeg,
  webp,
  png,
}

/// Enum para definir o tamanho/resolução da imagem
enum ImageSize {
  /// Thumbnail pequeno (150px) - para avatares em listas
  thumbnail(150, 70, 'thumb'),

  /// Médio (400px) - para cards e previews
  medium(400, 80, 'medium'),

  /// Grande (800px) - para perfil e visualização
  large(800, 85, 'large'),

  /// Original/Full (1920px) - para galeria completa
  full(1920, 90, 'full');

  final int maxWidth;
  final int quality;
  final String suffix;

  const ImageSize(this.maxWidth, this.quality, this.suffix);
}

/// Utility class for compressing images before upload.
///
/// This helps reduce:
/// - Upload time
/// - Storage costs
/// - Bandwidth usage
///
/// Features:
/// - Suporte a múltiplos formatos (JPEG, WebP, PNG)
/// - Geração de múltiplas resoluções (thumbnail, medium, large, full)
/// - Compressão otimizada por tamanho alvo
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

  /// WebP quality padrão (0-100) - melhor compressão que JPEG
  static const int webpQuality = 80;

  /// Converte o enum ImageFormat para o formato do flutter_image_compress
  static CompressFormat _getCompressFormat(ImageFormat format) {
    switch (format) {
      case ImageFormat.jpeg:
        return CompressFormat.jpeg;
      case ImageFormat.webp:
        return CompressFormat.webp;
      case ImageFormat.png:
        return CompressFormat.png;
    }
  }

  /// Retorna a extensão do arquivo baseada no formato
  static String _getFileExtension(ImageFormat format) {
    switch (format) {
      case ImageFormat.jpeg:
        return 'jpg';
      case ImageFormat.webp:
        return 'webp';
      case ImageFormat.png:
        return 'png';
    }
  }

  /// Comprime uma imagem e retorna um novo arquivo.
  ///
  /// Parâmetros:
  /// - [file]: Arquivo de imagem original
  /// - [maxWidth]: Largura máxima (mantém aspect ratio)
  /// - [quality]: Qualidade da compressão (0-100)
  /// - [format]: Formato de saída (JPEG, WebP, PNG)
  /// - [outputPath]: Caminho opcional para salvar o arquivo
  ///
  /// Retorna o arquivo comprimido ou o original se a compressão falhar.
  static Future<File> compressImage(
    File file, {
    int maxWidth = galleryMaxWidth,
    int quality = galleryQuality,
    ImageFormat format = ImageFormat.jpeg,
    String? outputPath,
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
        format: _getCompressFormat(format),
      );

      final compressedSize = compressed.length;

      // Only use compressed version if it's actually smaller
      if (compressedSize >= originalSize) {
        return file;
      }

      // Save compressed image to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _getFileExtension(format);
      final compressedFile = File(
        outputPath ?? path.join(tempDir.path, 'compressed_$timestamp.$ext'),
      );

      await compressedFile.writeAsBytes(compressed);

      debugPrint(
        'ImageCompressor: Compressed ${(originalSize / 1024).toStringAsFixed(1)}KB → '
        '${(compressedSize / 1024).toStringAsFixed(1)}KB '
        '(${((1 - compressedSize / originalSize) * 100).toStringAsFixed(0)}% reduction) '
        'Format: ${format.name}',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('ImageCompressor: Error compressing image: $e');
      return file; // Return original on any error
    }
  }

  /// Gera múltiplas versões de uma imagem em diferentes tamanhos.
  ///
  /// Útil para upload de imagens que precisam de thumbnails e versões otimizadas.
  ///
  /// Parâmetros:
  /// - [file]: Arquivo de imagem original
  /// - [sizes]: Lista de tamanhos para gerar (padrão: todas as resoluções)
  /// - [format]: Formato de saída
  ///
  /// Retorna um mapa com [ImageSize] como chave e [File] como valor.
  static Future<Map<ImageSize, File>> generateMultipleSizes(
    File file, {
    List<ImageSize> sizes = ImageSize.values,
    ImageFormat format = ImageFormat.webp,
  }) async {
    final results = <ImageSize, File>{};
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = _getFileExtension(format);

    for (final size in sizes) {
      try {
        final outputPath = path.join(
          tempDir.path,
          'compressed_${size.suffix}_$timestamp.$ext',
        );

        final compressedFile = await compressImage(
          file,
          maxWidth: size.maxWidth,
          quality: size.quality,
          format: format,
          outputPath: outputPath,
        );

        results[size] = compressedFile;
      } catch (e) {
        debugPrint(
          'ImageCompressor: Error generating ${size.name} version: $e',
        );
      }
    }

    return results;
  }

  /// Comprime uma imagem para WebP com qualidade otimizada.
  ///
  /// WebP oferece melhor compressão que JPEG com qualidade similar.
  static Future<File> compressToWebP(
    File file, {
    int maxWidth = galleryMaxWidth,
    int quality = webpQuality,
  }) async {
    return compressImage(
      file,
      maxWidth: maxWidth,
      quality: quality,
      format: ImageFormat.webp,
    );
  }

  /// Comprime uma imagem diretamente para bytes (útil para upload em memória).
  static Future<Uint8List?> compressToBytes(
    File file, {
    int maxWidth = galleryMaxWidth,
    int quality = galleryQuality,
    ImageFormat format = ImageFormat.jpeg,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxWidth,
        minHeight: maxWidth,
        quality: quality,
        format: _getCompressFormat(format),
      );
    } catch (e) {
      debugPrint('ImageCompressor: Error compressing to bytes: $e');
      return null;
    }
  }

  /// Comprime uma foto de perfil com configurações apropriadas.
  static Future<File> compressProfilePhoto(
    File file, {
    ImageFormat format = ImageFormat.webp,
  }) {
    return compressImage(
      file,
      maxWidth: profileMaxWidth,
      quality: profileQuality,
      format: format,
    );
  }

  /// Gera múltiplas versões de uma foto de perfil.
  static Future<Map<ImageSize, File>> generateProfilePhotoSizes(File file) async {
    return generateMultipleSizes(
      file,
      sizes: [ImageSize.thumbnail, ImageSize.large],
      format: ImageFormat.webp,
    );
  }

  /// Comprime uma foto de galeria com configurações apropriadas.
  static Future<File> compressGalleryPhoto(
    File file, {
    ImageFormat format = ImageFormat.webp,
  }) {
    return compressImage(
      file,
      maxWidth: galleryMaxWidth,
      quality: galleryQuality,
      format: format,
    );
  }

  /// Gera múltiplas versões de uma foto de galeria.
  static Future<Map<ImageSize, File>> generateGalleryPhotoSizes(File file) async {
    return generateMultipleSizes(
      file,
      sizes: ImageSize.values,
      format: ImageFormat.webp,
    );
  }

  /// Comprime um thumbnail de vídeo com configurações apropriadas.
  static Future<File> compressThumbnail(File file) {
    return compressImage(
      file,
      maxWidth: thumbnailMaxWidth,
      quality: thumbnailQuality,
      format: ImageFormat.webp,
    );
  }

  /// Calcula o tamanho estimado após compressão.
  ///
  /// Útil para mostrar ao usuário antes do upload.
  static Future<String> getEstimatedSize(
    File file, {
    int maxWidth = galleryMaxWidth,
    int quality = galleryQuality,
    ImageFormat format = ImageFormat.webp,
  }) async {
    try {
      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;

      final compressed = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: maxWidth,
        minHeight: maxWidth,
        quality: quality,
        format: _getCompressFormat(format),
      );

      final compressedSize = compressed.length;
      final reduction = ((1 - compressedSize / originalSize) * 100)
          .toStringAsFixed(0);

      return '${_formatBytes(compressedSize)} ($reduction% menor)';
    } catch (e) {
      return 'Não foi possível estimar';
    }
  }

  /// Formata bytes para formato legível
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
