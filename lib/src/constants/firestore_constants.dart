class FirestoreCollections {
  static const String users = 'users';
  static const String deletedUsers = 'deleted_users';
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
