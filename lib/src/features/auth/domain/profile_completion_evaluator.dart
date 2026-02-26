import 'app_user.dart';
import 'user_type.dart';

class ProfileCompletionResult {
  final int percent;
  final int completedItems;
  final int totalItems;
  final List<String> missingRequirements;

  const ProfileCompletionResult({
    required this.percent,
    required this.completedItems,
    required this.totalItems,
    required this.missingRequirements,
  });

  bool get isComplete => percent == 100;
}

class ProfileCompletionEvaluator {
  static ProfileCompletionResult evaluate(AppUser? user) {
    if (user == null) {
      return const ProfileCompletionResult(
        percent: 0,
        completedItems: 0,
        totalItems: 0,
        missingRequirements: ['Usuario nao autenticado'],
      );
    }

    final checks = <_CompletionCheck>[
      _CompletionCheck('Cadastro concluido', user.isCadastroConcluido),
      _CompletionCheck('Tipo de perfil', user.tipoPerfil != null),
      _CompletionCheck('Nome', _hasText(user.nome)),
      _CompletionCheck('Foto de perfil', _hasText(user.foto)),
      _CompletionCheck('Localizacao', _hasValidLocation(user.location)),
      _CompletionCheck('Bio', _hasText(user.bio)),
    ];

    final type = user.tipoPerfil;
    if (type != null) {
      checks.addAll(_buildPersonalChecks(user, type));
      if (_requiresGallery(type)) {
        checks.addAll(_buildGalleryChecks(user, type));
      }
    }

    final completed = checks.where((check) => check.isComplete).length;
    final total = checks.length;
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();

    return ProfileCompletionResult(
      percent: percent.clamp(0, 100),
      completedItems: completed,
      totalItems: total,
      missingRequirements: checks
          .where((check) => !check.isComplete)
          .map((check) => check.label)
          .toList(),
    );
  }

  static List<_CompletionCheck> _buildPersonalChecks(
    AppUser user,
    AppUserType type,
  ) {
    switch (type) {
      case AppUserType.professional:
        final data = user.dadosProfissional ?? const <String, dynamic>{};
        return [
          _CompletionCheck('Nome artistico', _hasText(data['nomeArtistico'])),
          _CompletionCheck('Celular', _hasText(data['celular'])),
          _CompletionCheck(
            'Data de nascimento',
            _hasText(data['dataNascimento']),
          ),
          _CompletionCheck('Genero', _hasText(data['genero'])),
        ];
      case AppUserType.band:
        final data = user.dadosBanda ?? const <String, dynamic>{};
        final hasBandName =
            _hasText(data['nomeArtistico']) ||
            _hasText(data['nomeBanda']) ||
            _hasText(data['nome']) ||
            _hasText(user.nome);
        final genres = _asStringList(data['generosMusicais']);
        return [
          _CompletionCheck('Nome da banda', hasBandName),
          _CompletionCheck('Generos musicais', genres.isNotEmpty),
        ];
      case AppUserType.studio:
        final data = _resolveStudioData(user);
        final services = _asStringList(data['services']).isNotEmpty
            ? _asStringList(data['services'])
            : _asStringList(data['servicosOferecidos']);
        final hasStudioName =
            _hasText(data['nomeArtistico']) ||
            _hasText(data['nomeEstudio']) ||
            _hasText(data['nome']);
        return [
          _CompletionCheck('Nome do estudio', hasStudioName),
          _CompletionCheck('Celular', _hasText(data['celular'])),
          _CompletionCheck('Tipo de estudio', _hasText(data['studioType'])),
          _CompletionCheck('Servicos do estudio', services.isNotEmpty),
        ];
      case AppUserType.contractor:
        final data = user.dadosContratante ?? const <String, dynamic>{};
        return [
          _CompletionCheck('Celular', _hasText(data['celular'])),
          _CompletionCheck(
            'Data de nascimento',
            _hasText(data['dataNascimento']),
          ),
          _CompletionCheck('Genero', _hasText(data['genero'])),
        ];
    }
  }

  static List<_CompletionCheck> _buildGalleryChecks(
    AppUser user,
    AppUserType type,
  ) {
    final data = switch (type) {
      AppUserType.professional =>
        user.dadosProfissional ?? const <String, dynamic>{},
      AppUserType.band => user.dadosBanda ?? const <String, dynamic>{},
      AppUserType.studio => _resolveStudioData(user),
      AppUserType.contractor => const <String, dynamic>{},
    };

    final gallery = data['gallery'];
    final photoCount = _countGalleryByType(gallery, expected: 'photo');
    final videoCount = _countGalleryByType(gallery, expected: 'video');

    return [
      _CompletionCheck('Galeria de fotos', photoCount > 0),
      _CompletionCheck('Galeria de videos', videoCount > 0),
    ];
  }

  static Map<String, dynamic> _resolveStudioData(AppUser user) {
    if (user.dadosEstudio != null && user.dadosEstudio!.isNotEmpty) {
      return user.dadosEstudio!;
    }

    // Legacy compatibility: old flows saved studio fields in professional map.
    if (user.tipoPerfil == AppUserType.studio &&
        user.dadosProfissional != null &&
        user.dadosProfissional!.isNotEmpty) {
      return user.dadosProfissional!;
    }

    return const <String, dynamic>{};
  }

  static bool _requiresGallery(AppUserType type) {
    return type == AppUserType.professional ||
        type == AppUserType.band ||
        type == AppUserType.studio;
  }

  static bool _hasText(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    return value.toString().trim().isNotEmpty;
  }

  static bool _hasValidLocation(Map<String, dynamic>? location) {
    if (location == null) return false;

    final lat = location['lat'];
    final lng = location['lng'];
    if (lat is! num || lng is! num) return false;

    return lat != 0 || lng != 0;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static int _countGalleryByType(
    dynamic galleryData, {
    required String expected,
  }) {
    if (galleryData is! List) return 0;

    return galleryData.where((item) {
      if (item is! Map) return false;
      final type = (item['type'] ?? '').toString().toLowerCase();

      if (expected == 'photo') {
        return type == 'photo' || type == 'foto' || type == 'image';
      }

      return type == 'video';
    }).length;
  }
}

class _CompletionCheck {
  final String label;
  final bool isComplete;

  const _CompletionCheck(this.label, this.isComplete);
}
