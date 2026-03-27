import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/category_normalizer.dart';
import '../../../utils/professional_profile_utils.dart';

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
    @Default(false) bool offersRemoteRecording,
    // @Default(false) bool isFavorited, // Removed
    double? distanceKm,
  }) = _FeedItem;

  /// Display name exposed in the app.
  ///
  /// Professional, band and studio profiles must never fall back to the
  /// registration name. Only contractors can expose `nome`.
  String get displayName {
    final publicName = nomeArtistico?.trim() ?? '';
    if (publicName.isNotEmpty) return publicName;

    switch (tipoPerfil) {
      case 'profissional':
        return 'Profissional';
      case 'banda':
        return 'Banda';
      case 'estudio':
        return 'Estudio';
      case 'contratante':
        final contractorName = nome.trim();
        return contractorName.isNotEmpty ? contractorName : 'Contratante';
      default:
        return 'Perfil';
    }
  }

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
    final contractorData = data['contratante'] as Map<String, dynamic>? ?? {};

    // Determine which nested data to use for artistic name
    String? artisticName;
    String? category;
    final List<String> extractedSkills = [];
    final List<String> extractedSubCategories = [];
    List<String> extractedGenres = [];
    var offersRemoteRecording = false;

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
      final rawRoles = (profData['funcoes'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList();
      final legacyCategory = profData['categoria'];
      if (legacyCategory is String && legacyCategory.isNotEmpty) {
        rawCategories.add(legacyCategory);
      }
      extractedSubCategories.addAll(
        CategoryNormalizer.resolveCategories(
          rawCategories: rawCategories,
          rawRoles: rawRoles,
        ),
      );
      extractedSkills.addAll(rawRoles);
      offersRemoteRecording = professionalOffersRemoteRecording(profData);

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
      artisticName = contractorData['nomeExibicao'] as String?;
      category = 'Local';

      final amenities = contractorData['comodidades'];
      if (amenities is List) {
        extractedSkills.addAll(amenities.whereType<String>());
      }
    }

    // Optimization: Sort items by length for better UI display (cloud tags)
    // Shortest items first allows showing more chips in limited space
    extractedSkills.sort((a, b) => a.length.compareTo(b.length));
    extractedGenres.sort((a, b) => a.length.compareTo(b.length));

    return FeedItem(
      uid: docId,
      nome: data['nome'] ?? '',
      nomeArtistico: artisticName,
      foto: data['foto'],
      categoria: category,
      generosMusicais: extractedGenres,
      tipoPerfil: tipoPerfil,
      location: data['location'] as Map<String, dynamic>?,
      likeCount: data['likeCount'] ?? 0,
      skills: extractedSkills,
      subCategories: extractedSubCategories.toSet().toList(),
      offersRemoteRecording: offersRemoteRecording,
    );
  }
}
