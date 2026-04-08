class FirestoreCollections {
  static const String users = 'users';
  static const String deletedUsers = 'deletedUsers';
  static const String matches = 'matches';
  static const String interactions = 'interactions';
  static const String matchpointCommands = 'matchpointCommands';
  static const String matchpointFeeds = 'matchpointFeeds';
  static const String matchpointFeedRefreshRequests =
      'matchpointFeedRefreshRequests';
  static const String reports = 'reports';
  static const String blocked = 'blocked';
  static const String gigs = 'gigs';
  static const String gigApplications = 'gig_applications';
  static const String gigReviews = 'gig_reviews';
}

class FirestoreFields {
  // Common
  static const String registrationStatus = 'cadastro_status';
  static const String profileType = 'tipo_perfil';
  static const String location = 'location';
  static const String geohash = 'geohash';
  static const String name = 'nome';
  static const String photo = 'foto';
  static const String deletedAt = 'deleted_at';
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

class GigFields {
  static const String title = 'title';
  static const String description = 'description';
  static const String gigType = 'gig_type';
  static const String gigDate = 'gig_date';
  static const String dateMode = 'date_mode';
  static const String locationType = 'location_type';
  static const String location = 'location';
  static const String geohash = 'geohash';
  static const String genres = 'genres';
  static const String requiredInstruments = 'required_instruments';
  static const String requiredCrewRoles = 'required_crew_roles';
  static const String requiredStudioServices = 'required_studio_services';
  static const String slotsTotal = 'slots_total';
  static const String slotsFilled = 'slots_filled';
  static const String compensationType = 'compensation_type';
  static const String compensationValue = 'compensation_value';
  static const String status = 'status';
  static const String creatorId = 'creator_id';
  static const String applicantCount = 'applicant_count';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String expiresAt = 'expires_at';

  static const String applicantId = 'applicant_id';
  static const String message = 'message';
  static const String appliedAt = 'applied_at';
  static const String respondedAt = 'responded_at';

  static const String gigId = 'gig_id';
  static const String reviewerId = 'reviewer_id';
  static const String reviewedUserId = 'reviewed_user_id';
  static const String rating = 'rating';
  static const String comment = 'comment';
  static const String reviewType = 'review_type';
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
  @Deprecated('Use production and stageTech.')
  static const String techCrew = 'Equipe Técnica';
  static const String production = 'Produção Musical';
  static const String stageTech = 'Técnica de Palco';
  static const String professional = 'Profissional';
}
