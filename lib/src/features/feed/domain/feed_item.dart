/// Model representing a user profile item in the feed.
class FeedItem {
  final String uid;
  final String nome;
  final String? nomeArtistico;
  final String? foto;
  final String? categoria;
  final List<String> generosMusicais;
  final String tipoPerfil;
  final Map<String, dynamic>? location;
  final int favoriteCount;
  final List<String> skills;

  /// Calculated at runtime based on user's location
  double? distanceKm;

  FeedItem({
    required this.uid,
    required this.nome,
    this.nomeArtistico,
    this.foto,
    this.categoria,
    this.generosMusicais = const [],
    required this.tipoPerfil,
    this.location,
    this.favoriteCount = 0,
    this.skills = const [],
    this.distanceKm,
  });

  /// Display name (artistic name if available, otherwise real name)
  String get displayName =>
      nomeArtistico?.isNotEmpty == true ? nomeArtistico! : nome;

  /// Formatted distance string
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '< 1 km';
    return '${distanceKm!.round()} km';
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
      if (profData['funcoes'] != null) {
        extractedSkills.addAll(List<String>.from(profData['funcoes']));
      }

      // Extract genres
      if (profData['generosMusicais'] != null) {
        extractedGenres = List<String>.from(profData['generosMusicais']);
      }
    } else if (tipoPerfil == 'banda') {
      // Band: nomeBanda (used as name), generosMusicais
      artisticName = bandData['nomeBanda'] as String?;
      category = 'Banda';

      // Bands don't have instruments/skills in the same way, but have genres
      if (bandData['generosMusicais'] != null) {
        extractedGenres = List<String>.from(bandData['generosMusicais']);
      }
    } else if (tipoPerfil == 'estudio') {
      // Studio: nomeArtistico (studio name), services
      artisticName = studioData['nomeArtistico'] as String?;
      category = 'Estúdio'; // Simple main category

      // Extract services as skills
      if (studioData['services'] != null) {
        extractedSkills.addAll(List<String>.from(studioData['services']));
      }
    } else if (tipoPerfil == 'contratante') {
      // Contractor: usually not shown in public feed, but handle gracefully
      category = 'Contratante';
    }

    return FeedItem(
      uid: docId,
      nome: data['nome'] ?? '',
      nomeArtistico: artisticName,
      foto: data['foto'],
      categoria: category,
      generosMusicais: extractedGenres,
      tipoPerfil: tipoPerfil,
      location: data['location'] as Map<String, dynamic>?,
      favoriteCount: data['favoriteCount'] ?? 0,
      skills: extractedSkills,
    );
  }
}
