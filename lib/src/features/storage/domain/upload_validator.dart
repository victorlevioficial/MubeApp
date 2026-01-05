import 'dart:io';

/// Exceções específicas para erros de upload
class UploadValidationException implements Exception {
  final String message;
  const UploadValidationException(this.message);

  @override
  String toString() => message;
}

/// Constantes de limites de upload
class UploadLimits {
  /// Tamanho máximo para fotos: 10MB
  static const int maxPhotoSizeBytes = 10 * 1024 * 1024;

  /// Tamanho máximo para vídeos: 50MB
  static const int maxVideoSizeBytes = 50 * 1024 * 1024;

  /// Extensões de imagem permitidas
  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
  ];

  /// Extensões de vídeo permitidas
  static const List<String> allowedVideoExtensions = ['.mp4', '.mov', '.webm'];
}

/// Classe utilitária para validar arquivos antes do upload
class UploadValidator {
  /// Valida um arquivo de imagem antes do upload.
  /// Lança [UploadValidationException] se inválido.
  static Future<void> validateImage(File file) async {
    await _validateFileExists(file);
    _validateExtension(file, UploadLimits.allowedImageExtensions, 'imagem');
    await _validateFileSize(file, UploadLimits.maxPhotoSizeBytes, 'Foto');
  }

  /// Valida um arquivo de vídeo antes do upload.
  /// Lança [UploadValidationException] se inválido.
  static Future<void> validateVideo(File file) async {
    await _validateFileExists(file);
    _validateExtension(file, UploadLimits.allowedVideoExtensions, 'vídeo');
    await _validateFileSize(file, UploadLimits.maxVideoSizeBytes, 'Vídeo');
  }

  /// Valida um arquivo de mídia (imagem ou vídeo).
  /// [isVideo] indica se é vídeo (true) ou imagem (false).
  static Future<void> validateMedia(File file, {required bool isVideo}) async {
    if (isVideo) {
      await validateVideo(file);
    } else {
      await validateImage(file);
    }
  }

  // ============================================
  // MÉTODOS PRIVADOS DE VALIDAÇÃO
  // ============================================

  static Future<void> _validateFileExists(File file) async {
    if (!await file.exists()) {
      throw const UploadValidationException(
        'Arquivo não encontrado. Por favor, selecione outro arquivo.',
      );
    }
  }

  static void _validateExtension(
    File file,
    List<String> allowedExtensions,
    String mediaType,
  ) {
    final extension = file.path.toLowerCase().split('.').last;
    final extensionWithDot = '.$extension';

    if (!allowedExtensions.contains(extensionWithDot)) {
      final formattedExtensions = allowedExtensions
          .map((e) => e.replaceFirst('.', '').toUpperCase())
          .join(', ');
      throw UploadValidationException(
        'Formato de $mediaType não suportado. '
        'Use: $formattedExtensions.',
      );
    }
  }

  static Future<void> _validateFileSize(
    File file,
    int maxSizeBytes,
    String mediaType,
  ) async {
    final fileSize = await file.length();

    if (fileSize > maxSizeBytes) {
      final maxSizeMB = maxSizeBytes ~/ (1024 * 1024);
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw UploadValidationException(
        '$mediaType muito grande ($fileSizeMB MB). '
        'O tamanho máximo é $maxSizeMB MB.',
      );
    }
  }

  /// Retorna o tamanho do arquivo em formato legível (ex: "2.5 MB")
  static Future<String> getReadableFileSize(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
