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
    // Extract nested professional data if available
    final profData = data['profissional'] as Map<String, dynamic>? ?? {};
    final studioData = data['estudio'] as Map<String, dynamic>? ?? {};

    return FeedItem(
      uid: docId,
      nome: data['nome'] ?? '',
      nomeArtistico: profData['nomeArtistico'] ?? studioData['nomeFantasia'],
      foto: data['foto'],
      categoria: profData['categoria'],
      generosMusicais: List<String>.from(profData['generosMusicais'] ?? []),
      tipoPerfil: data['tipoPerfil'] ?? 'profissional',
      location: data['location'] as Map<String, dynamic>?,
      favoriteCount: data['favoriteCount'] ?? 0,
    );
  }
}
