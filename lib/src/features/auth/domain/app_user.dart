import 'package:freezed_annotation/freezed_annotation.dart';

import '../../settings/domain/saved_address.dart';
import 'user_type.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// Represents a user in the MubeApp system.
///
/// This model maps to the Firestore `users` collection document.
/// It contains both common fields and type-specific data stored in nested maps.
///
/// ## Registration Flow
/// Users progress through these statuses:
/// 1. `tipo_pendente` - Just registered, needs to select profile type
/// 2. `perfil_pendente` - Type selected, needs to complete profile
/// 3. `concluido` - Registration complete
///
/// ## Profile Types
/// - [AppUserType.professional] - Musicians, singers, DJs, crew
/// - [AppUserType.band] - Musical groups
/// - [AppUserType.studio] - Recording studios
/// - [AppUserType.contractor] - Event organizers, venues
///
/// See also:
/// - [AppUserType] for profile type enum
/// - [AuthRepository] for data operations
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    /// Unique identifier (matches Firebase Auth UID).
    required String uid,

    /// User's email address.
    required String email,

    /// Registration status: 'tipo_pendente', 'perfil_pendente', or 'concluido'.
    @Default('tipo_pendente')
    @JsonKey(name: 'cadastro_status')
    String cadastroStatus,

    /// Profile type, set after initial type selection.
    @JsonKey(name: 'tipo_perfil') AppUserType? tipoPerfil,

    /// Account visibility status: 'ativo', 'inativo', 'suspenso'.
    @Default('ativo') String status,

    /// User's display name.
    String? nome,

    /// Profile photo URL.
    String? foto,

    /// Short biography.
    String? bio,

    /// Location data: cidade, estado, lat, lng. (Legacy - kept for backward compatibility)
    Map<String, dynamic>? location,

    /// Geohash for efficient location-based queries (precision 5 = ~5km squares).
    /// Generated from location.lat and location.lng.
    /// Optional for backward compatibility with existing users.
    String? geohash,

    /// List of saved addresses (up to 5). One should be marked as primary.
    @Default([]) List<SavedAddress> addresses,

    /// Professional-specific data (musicians, DJs, crew).
    @JsonKey(name: 'profissional') Map<String, dynamic>? dadosProfissional,

    /// Band-specific data (musical groups).
    @JsonKey(name: 'banda') Map<String, dynamic>? dadosBanda,

    /// Studio-specific data (recording studios).
    @JsonKey(name: 'estudio') Map<String, dynamic>? dadosEstudio,

    /// Contractor-specific data (venues, organizers).
    @JsonKey(name: 'contratante') Map<String, dynamic>? dadosContratante,

    /// Document creation timestamp.
    @JsonKey(name: 'created_at') dynamic createdAt,
  }) = _AppUser;

  /// Creates an [AppUser] from a Firestore document JSON.
  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  const AppUser._();

  /// Whether the user still needs to select a profile type.
  bool get isCadastroConcluido => cadastroStatus == 'concluido';

  /// Whether the user has completed the type selection.
  bool get isTipoPendente => cadastroStatus == 'tipo_pendente';

  /// Whether the user needs to complete their profile form.
  bool get isPerfilPendente => cadastroStatus == 'perfil_pendente';

  /// Converts to Firestore-compatible Map, properly serializing addresses.
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    // Convert SavedAddress objects to Maps for Firestore
    if (addresses.isNotEmpty) {
      json['addresses'] = addresses.map((a) => a.toJson()).toList();
    }
    return json;
  }
}
