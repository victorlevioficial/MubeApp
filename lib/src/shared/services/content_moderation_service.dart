import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../utils/app_logger.dart';

part 'content_moderation_service.g.dart';

@Riverpod(keepAlive: true)
ContentModerationService contentModerationService(Ref ref) {
  return ContentModerationService();
}

class ContentModerationService {
  // API Key now comes from environment configuration
  String get _apiUrl => AppConfig.visionApiUrl;

  /// Validates an image file for inappropriate content.
  /// Throws [ModerationException] if content is flagged.
  /// Returns [true] if clean.
  Future<bool> validateImage(File imageFile) async {
    if (AppConfig.googleVisionApiKey.isEmpty) {
      // Fail open during dev to avoid blocking uploads
      AppLogger.warning(
        'GOOGLE_VISION_API_KEY not set. Skipping moderation. '
        'Run with: --dart-define=GOOGLE_VISION_API_KEY=your_key',
      );
      return true;
    }

    try {
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'SAFE_SEARCH_DETECTION'},
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        AppLogger.error('Cloud Vision API Error: ${response.body}');
        // Decision: If API fails (quota, network), do we block upload?
        // For MVP, let's allow it but log error.
        return true;
      }

      final data = jsonDecode(response.body);
      final annotations =
          data['responses']?[0]['safeSearchAnnotation']
              as Map<String, dynamic>?;

      if (annotations == null) return true;

      // Check for likelihoods
      if (_isLikely(annotations['adult']) ||
          _isLikely(annotations['violence']) ||
          _isLikely(annotations['racy']) ||
          _isLikely(annotations['medical'])) {
        throw ModerationException(
          'Conteúdo impróprio detectado na imagem. Por favor, escolha outra foto.',
        );
      }

      return true;
    } catch (e, stackTrace) {
      if (e is ModerationException) rethrow;
      // Network errors etc - Fail safe (allow) for now
      AppLogger.error('Moderation check failed', e, stackTrace);
      return true; // Skipping on error to not block user if internet is flaky
    }
  }

  bool _isLikely(String? likelihood) {
    if (likelihood == null) return false;
    return likelihood == 'LIKELY' || likelihood == 'VERY_LIKELY';
  }
}

class ModerationException implements Exception {
  final String message;
  ModerationException(this.message);
  @override
  String toString() => message;
}
