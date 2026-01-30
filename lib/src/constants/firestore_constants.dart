class FirestoreCollections {
  static const String users = 'users';
  static const String deletedUsers = 'deleted_users';
  static const String matches = 'matches';
  static const String interactions = 'interactions';
}

class FirestoreFields {
  // Common
  static const String registrationStatus = 'cadastro_status';
  static const String profileType = 'tipo_perfil';
  static const String location = 'location';
  static const String geohash = 'geohash';
  static const String name = 'nome';
  static const String photo = 'foto';
  static const String deletedAt = 'deletedAt';
  static const String createdAt = 'createdAt';

  // Profile Fields
  static const String professional = 'profissional';
  static const String band = 'banda';
  static const String studio = 'estudio';
  static const String contractor = 'contratante';

  // Nested Fields
  static const String category = 'categoria';
  static const String instruments = 'instrumentos';
  static const String functions = 'funcoes';
  static const String musicalGenres = 'generosMusicais';
  static const String artisticName = 'nomeArtistico';
  static const String bandName = 'nomeBanda';
  static const String services = 'services';

  // MatchPoint
  static const String matchpointProfile = 'matchpoint_profile';
  static const String isActive = 'is_active';
  static const String intent = 'intent';
  static const String hashtags = 'hashtags';
  static const String targetRoles = 'target_roles';
  static const String searchRadius = 'search_radius';
  static const String type = 'type';
  static const String timestamp = 'timestamp';
  static const String targetId = 'targetId';
  static const String fromId = 'fromId';
}

class RegistrationStatus {
  static const String complete = 'concluido';
  static const String pending = 'tipo_pendente';
}

class ProfileType {
  static const String professional = 'profissional';
  static const String band = 'banda';
  static const String studio = 'estudio';
  static const String contractor = 'contratante';
}

class ProfessionalCategory {
  static const String techCrew = 'Equipe Técnica';
  static const String professional = 'Profissional';
}
