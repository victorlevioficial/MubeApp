import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/public_username.dart';
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

    /// Account visibility status: 'ativo', 'rascunho', 'inativo', 'suspenso'.
    /// Band creation flows must override this to 'rascunho' explicitly.
    @Default('ativo') String status,

    /// User's registration name (full/legal name for internal records).
    String? nome,

    /// Profile photo URL.
    String? foto,

    /// Thumbnail-sized profile photo URL when available.
    @JsonKey(name: 'foto_thumb') String? fotoThumb,

    /// Short biography.
    String? bio,

    /// Public profile handle used in shareable URLs like `mubeapp.com.br/@user`.
    String? username,

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

    /// Number of times this user has been favorited (Received Favorites).
    @Default(0) @JsonKey(name: 'favorites_count') int favoritesCount,

    /// List of user IDs that are members of this band (if type is band).
    @Default([]) List<String> members,

    /// Document creation timestamp.
    @JsonKey(name: 'created_at') dynamic createdAt,

    /// List of user IDs that this user has blocked.
    @Default([]) @JsonKey(name: 'blocked_users') List<String> blockedUsers,

    /// Privacy settings: 'ghost_mode', 'visible_in_search', etc.
    @Default({})
    @JsonKey(name: 'privacy_settings')
    Map<String, dynamic> privacySettings,

    /// Optional music streaming links shared across non-contractor profiles.
    @Default({}) @JsonKey(name: 'music_links') Map<String, String> musicLinks,

    /// MatchPoint configuration data.
    /// Contains: is_active, intent, genres, hashtags, target_roles, search_radius.
    @JsonKey(name: 'matchpoint_profile')
    Map<String, dynamic>? matchpointProfile,
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

  /// Name used for internal registration data.
  String get registrationName => (nome ?? '').trim();

  /// Whether the email is Apple's private relay alias from Sign in with Apple.
  bool get hasApplePrivateRelayEmail =>
      email.trim().toLowerCase().endsWith('@privaterelay.appleid.com');

  /// Name shown in app surfaces (cards, profile headers, search, etc).
  ///
  /// Rules:
  /// - Professional: `profissional.nomeArtistico`
  /// - Band: `banda.nomeBanda` (fallbacks for legacy keys)
  /// - Studio: `estudio.nomeEstudio` (fallbacks for legacy keys)
  /// - Contractor: `contratante.nomeExibicao` (fallback to short name from `nome`)
  String get appDisplayName {
    switch (tipoPerfil) {
      case AppUserType.professional:
        return _firstNonEmptyName([
          dadosProfissional?['nomeArtistico'],
        ], 'Profissional');
      case AppUserType.band:
        return _firstNonEmptyName([
          dadosBanda?['nomeBanda'],
          dadosBanda?['nomeArtistico'],
          dadosBanda?['nome'],
        ], 'Banda');
      case AppUserType.studio:
        return _firstNonEmptyName([
          dadosEstudio?['nomeEstudio'],
          dadosEstudio?['nomeArtistico'],
          dadosEstudio?['nome'],
        ], 'Estudio');
      case AppUserType.contractor:
        return _firstNonEmptyName([
          dadosContratante?['nomeExibicao'],
          _buildShortPersonName(nome),
          nome,
        ], 'Contratante');
      default:
        return _firstNonEmptyName([], 'Perfil');
    }
  }

  /// Biography shown in profile surfaces.
  ///
  /// Uses top-level `bio` first and falls back to legacy nested maps when
  /// older documents stored the value inside the type-specific payload.
  String? get profileBio {
    switch (tipoPerfil) {
      case AppUserType.professional:
        return _firstNonEmptyText([bio, dadosProfissional?['bio']]);
      case AppUserType.band:
        return _firstNonEmptyText([bio, dadosBanda?['bio']]);
      case AppUserType.studio:
        return _firstNonEmptyText([
          bio,
          dadosEstudio?['bio'],
          dadosProfissional?['bio'],
        ]);
      case AppUserType.contractor:
        return _firstNonEmptyText([bio, dadosContratante?['bio']]);
      default:
        return _firstNonEmptyText([bio]);
    }
  }

  /// Public username normalized to the canonical lowercase form.
  String? get publicUsername => normalizedPublicUsernameOrNull(username);

  /// Best avatar URL for compact surfaces such as headers, lists and chips.
  String? get avatarPreviewUrl => _firstNonEmptyText([fotoThumb, foto]);

  /// Best avatar URL for large/full surfaces such as media viewers.
  String? get avatarFullUrl => _firstNonEmptyText([foto, fotoThumb]);

  /// Public handle shown in shareable contexts.
  String? get publicHandle {
    final normalized = publicUsername;
    if (normalized == null || !isValidPublicUsername(normalized)) {
      return null;
    }
    return publicUsernameHandle(normalized);
  }

  /// Phone number stored in the active profile map for the user type.
  String get profilePhone => _readActiveProfileString('celular');

  /// Birth date stored in the active profile map for the user type.
  String get profileBirthDate => _readActiveProfileString('dataNascimento');

  /// Gender stored in the active profile map for the user type.
  String get profileGender => _readActiveProfileString('genero');

  /// Instagram handle stored in the active profile map for the user type.
  String get profileInstagram => _readActiveProfileString('instagram');

  /// Professional categories (e.g. singer, instrumentalist) from `dadosProfissional['categorias']`.
  List<String> get professionalCategories =>
      _stringList(dadosProfissional?['categorias']);

  /// Professional role ids from `dadosProfissional['funcoes']`.
  List<String> get professionalRoles =>
      _stringList(dadosProfissional?['funcoes']);

  /// Instruments from `dadosProfissional['instrumentos']`.
  List<String> get professionalInstruments =>
      _stringList(dadosProfissional?['instrumentos']);

  /// Musical genres from `dadosProfissional['generosMusicais']`.
  List<String> get professionalGenres =>
      _stringList(dadosProfissional?['generosMusicais']);

  String _readActiveProfileString(String key) {
    final Map<String, dynamic>? data;
    switch (tipoPerfil) {
      case AppUserType.professional:
        data = dadosProfissional;
        break;
      case AppUserType.band:
        data = dadosBanda;
        break;
      case AppUserType.studio:
        data = dadosEstudio;
        break;
      case AppUserType.contractor:
        data = dadosContratante;
        break;
      default:
        return '';
    }
    final value = data?[key];
    return value is String ? value : '';
  }

  static List<String> _stringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? const <String>[] : <String>[normalized];
    }
    return const <String>[];
  }

  String _firstNonEmptyName(List<dynamic> candidates, [String fallback = '']) {
    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  String _buildShortPersonName(String? rawName) {
    final normalized = (rawName ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return '';

    final parts = normalized.split(' ');
    if (parts.length <= 2) return normalized;

    const connectors = {'de', 'da', 'do', 'dos', 'das', 'e'};
    final takeCount = connectors.contains(parts[1].toLowerCase()) ? 3 : 2;
    return parts.take(takeCount).join(' ');
  }

  String? _firstNonEmptyText(List<dynamic> candidates) {
    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

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
