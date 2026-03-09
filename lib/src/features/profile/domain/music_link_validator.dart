final class MusicLinkValidator {
  const MusicLinkValidator._();

  static const String spotifyKey = 'spotify';
  static const String deezerKey = 'deezer';
  static const String youtubeMusicKey = 'youtube_music';
  static const String appleMusicKey = 'apple_music';

  static const Set<String> supportedKeys = {
    spotifyKey,
    deezerKey,
    youtubeMusicKey,
    appleMusicKey,
  };

  static const Map<String, List<String>> _allowedHosts = {
    spotifyKey: ['open.spotify.com', 'spotify.link'],
    deezerKey: ['deezer.com', 'www.deezer.com'],
    youtubeMusicKey: ['music.youtube.com'],
    appleMusicKey: ['music.apple.com'],
  };

  static const Map<String, String> _labels = {
    spotifyKey: 'Spotify',
    deezerKey: 'Deezer',
    youtubeMusicKey: 'YouTube Music',
    appleMusicKey: 'Apple Music',
  };

  static String? validate(String platformKey, String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final label = _labels[platformKey];
    final allowedHosts = _allowedHosts[platformKey];
    if (label == null || allowedHosts == null) {
      return 'Plataforma não suportada.';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.trim().isEmpty) {
      return 'Use um link válido do $label.';
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return 'Use um link válido do $label.';
    }

    final host = uri.host.toLowerCase();
    final isAllowed = allowedHosts.any(
      (allowedHost) => host == allowedHost || host.endsWith('.$allowedHost'),
    );

    if (!isAllowed) {
      return 'Use um link válido do $label.';
    }

    return null;
  }

  static Map<String, String> sanitize(Map<String, String> rawLinks) {
    final sanitized = <String, String>{};
    for (final entry in rawLinks.entries) {
      final key = entry.key.trim();
      if (!supportedKeys.contains(key)) continue;

      final value = entry.value.trim();
      if (value.isEmpty) continue;

      sanitized[key] = value;
    }
    return sanitized;
  }

  static Map<String, String> validLinks(Map<String, String> rawLinks) {
    final sanitized = sanitize(rawLinks);
    final valid = <String, String>{};

    for (final entry in sanitized.entries) {
      if (validate(entry.key, entry.value) == null) {
        valid[entry.key] = entry.value;
      }
    }

    return valid;
  }
}
