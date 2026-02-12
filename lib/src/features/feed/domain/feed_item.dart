import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_item.freezed.dart';

/// Model representing a user profile item in the feed.
@freezed
sealed class FeedItem with _$FeedItem {
  const FeedItem._(); // Private constructor for custom methods

  const factory FeedItem({
    required String uid,
    required String nome,
    String? nomeArtistico,
    String? foto,
    String? categoria,
    @Default([]) List<String> generosMusicais,
    required String tipoPerfil,
    Map<String, dynamic>? location,
    @Default(0) int likeCount,
    @Default([]) List<String> skills,
    @Default([]) List<String> subCategories,
    // @Default(false) bool isFavorited, // Removed
    double? distanceKm,
  }) = _FeedItem;

  /// Display name (artistic name if available, otherwise real name)
  String get displayName =>
      nomeArtistico?.isNotEmpty == true ? nomeArtistico! : nome;

  /// Formatted distance string
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '< 1 km';
    return '${distanceKm!.round()} km';
  }

  /// Formatted genres (converts snake_case IDs to readable labels)
  List<String> get formattedGenres =>
      generosMusicais.map(_formatGenreLabel).toList();

  /// Converts a genre ID (snake_case) to a readable label
  static String _formatGenreLabel(String genreId) {
    // Replace underscores with spaces and capitalize each word
    return genreId
        .split('_')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  factory FeedItem.fromFirestore(Map<String, dynamic> data, String docId) {
    // Extract nested data based on profile type
    final profData = data['profissional'] as Map<String, dynamic>? ?? {};
    final bandData = data['banda'] as Map<String, dynamic>? ?? {};
    final studioData = data['estudio'] as Map<String, dynamic>? ?? {};

    // Determine which nested data to use for artistic name
    String? artisticName;
    String? category;
    final List<String> extractedSkills = [];
    final List<String> extractedSubCategories = [];
    List<String> extractedGenres = [];

    final tipoPerfil = data['tipo_perfil'] as String? ?? 'profissional';

    if (tipoPerfil == 'profissional') {
      // Professional: nomeArtistico, instrumentos, funcoes, generosMusicais
      artisticName = profData['nomeArtistico'] as String?;

      // Main category is always 'Profissional' (sub-categories like singer/instrumentalist are skills)
      category = 'Profissional';

      // Extract skills: instruments + roles
      if (profData['instrumentos'] != null) {
        extractedSkills.addAll(List<String>.from(profData['instrumentos']));
      }
      final rawCategories = (profData['categorias'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();
      final legacyCategory = profData['categoria'];
      if (legacyCategory is String && legacyCategory.isNotEmpty) {
        rawCategories.add(legacyCategory);
      }
      extractedSubCategories.addAll(
        _normalizeProfessionalCategories(rawCategories),
      );
      if (profData['funcoes'] != null) {
        extractedSkills.addAll(List<String>.from(profData['funcoes']));
      }

      // Extract genres
      if (profData['generosMusicais'] != null) {
        extractedGenres = List<String>.from(profData['generosMusicais']);
      }
    } else if (tipoPerfil == 'banda') {
      // Band: nomeBanda (used as name), generosMusicais
      artisticName =
          bandData['nomeBanda'] as String? ??
          bandData['nomeArtistico'] as String? ??
          bandData['nome'] as String?;
      category = 'Banda';

      // Bands don't have instruments/skills in the same way, but have genres
      if (bandData['generosMusicais'] != null) {
        extractedGenres = List<String>.from(bandData['generosMusicais']);
      }
    } else if (tipoPerfil == 'estudio') {
      // Studio: nomeArtistico (studio name), services
      artisticName =
          studioData['nomeEstudio'] as String? ??
          studioData['nomeArtistico'] as String? ??
          studioData['nome'] as String?;
      category = 'Estúdio'; // Simple main category

      // Extract services as skills
      final studioServices =
          studioData['services'] ?? studioData['servicosOferecidos'];
      if (studioServices != null) {
        extractedSkills.addAll(List<String>.from(studioServices));
      }
    } else if (tipoPerfil == 'contratante') {
      // Contractor: usually not shown in public feed, but handle gracefully
      category = 'Contratante';
    }

    // Optimization: Sort items by length for better UI display (cloud tags)
    // Shortest items first allows showing more chips in limited space
    extractedSkills.sort((a, b) => a.length.compareTo(b.length));
    extractedGenres.sort((a, b) => a.length.compareTo(b.length));

    return FeedItem(
      uid: docId,
      nome: data['nome'] ?? '',
      nomeArtistico: artisticName ?? (data['nome'] as String?),
      foto: data['foto'],
      categoria: category,
      generosMusicais: extractedGenres,
      tipoPerfil: tipoPerfil,
      location: data['location'] as Map<String, dynamic>?,
      likeCount: data['likeCount'] ?? 0,
      skills: extractedSkills,
      subCategories: extractedSubCategories.toSet().toList(),
    );
  }

  static List<String> _normalizeProfessionalCategories(List<String> raw) {
    return raw
        .map(_normalizeCategoryId)
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _normalizeCategoryId(String raw) {
    if (raw.trim().isEmpty) return '';

    final normalized = _sanitizeCategoryValue(raw);
    switch (normalized) {
      case 'crew':
      case 'equipe_tecnica':
      case 'equipe_tecnico':
      case 'tecnico':
      case 'tecnica':
        return 'crew';
      case 'cantor':
      case 'cantora':
      case 'cantor_a':
      case 'vocalista':
      case 'singer':
        return 'singer';
      case 'instrumentista':
      case 'instrumentalist':
        return 'instrumentalist';
      case 'dj':
        return 'dj';
      default:
        return normalized;
    }
  }

  static String _sanitizeCategoryValue(String value) {
    final withoutAccents = value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');

    return withoutAccents
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
