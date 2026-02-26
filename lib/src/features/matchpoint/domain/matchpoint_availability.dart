import '../../auth/domain/user_type.dart';

/// MatchPoint is available only for professionals and bands.
bool isMatchpointAvailableForType(AppUserType? userType) {
  return userType == AppUserType.professional || userType == AppUserType.band;
}
