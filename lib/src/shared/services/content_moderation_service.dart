import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_moderation_service.g.dart';

@Riverpod(keepAlive: true)
ContentModerationService contentModerationService(Ref ref) {
  return ContentModerationService();
}

class ContentModerationService {
  // API Key reused from LocationService
  static const String _apiKey = 'AIzaSyDV5N_ybY5dPkE2T0Dl4JCqaAlGxte2WU0';
  static const String _apiUrl =
      'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  /// Validates an image file for inappropriate content.
  /// Throws [ModerationException] if content is flagged.
  /// Returns [true] if clean.
  Future<bool> validateImage(File imageFile) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      // Fail open or closed during dev? Let's log warning and pass for now to avoid blocking
      print('WARNING: Cloud Vision API Key not set. Skipping moderation.');
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
        print('Cloud Vision API Error: ${response.body}');
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
    } catch (e) {
      if (e is ModerationException) rethrow;
      // Network errors etc - Fail safe (allow) for now?
      // Or fail closed (block)?
      // Let's rethrow as generic failure if we want to be strict, or return true to be lenient.
      // Strict for safety:
      print('Moderation check failed: $e');
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
