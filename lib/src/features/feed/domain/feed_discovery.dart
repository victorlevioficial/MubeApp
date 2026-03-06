import '../../../constants/firestore_constants.dart';
import 'feed_item.dart';

/// Canonical filters used by feed discovery surfaces.
enum FeedDiscoveryFilter {
  all,
  professionals,
  artists,
  technicians,
  bands,
  studios,
}

/// Shared discovery helpers so every feed surface applies the same rules.
abstract final class FeedDiscovery {
  static bool matchesFilter(FeedItem item, FeedDiscoveryFilter filter) {
    switch (filter) {
      case FeedDiscoveryFilter.all:
        return true;
      case FeedDiscoveryFilter.professionals:
        return item.tipoPerfil == ProfileType.professional;
      case FeedDiscoveryFilter.artists:
        return item.tipoPerfil == ProfileType.professional &&
            !isPureTechnician(item);
      case FeedDiscoveryFilter.technicians:
        return isPureTechnician(item);
      case FeedDiscoveryFilter.bands:
        return item.tipoPerfil == ProfileType.band;
      case FeedDiscoveryFilter.studios:
        return item.tipoPerfil == ProfileType.studio;
    }
  }

  static bool isPureTechnician(FeedItem item) {
    if (item.tipoPerfil != ProfileType.professional) return false;

    final normalizedCategories = item.subCategories
        .map(_normalizeCategory)
        .where((value) => value.isNotEmpty)
        .toSet();

    final hasCrew = normalizedCategories.contains('crew');
    final hasArtistCategory =
        normalizedCategories.contains('singer') ||
        normalizedCategories.contains('instrumentalist') ||
        normalizedCategories.contains('dj');

    return hasCrew && !hasArtistCategory;
  }

  static int compareByDistance(FeedItem a, FeedItem b) {
    final distanceComparison = _compareNullableDistance(
      a.distanceKm,
      b.distanceKm,
    );
    if (distanceComparison != 0) return distanceComparison;

    final popularityComparison = b.likeCount.compareTo(a.likeCount);
    if (popularityComparison != 0) return popularityComparison;

    final nameComparison = a.displayName.toLowerCase().compareTo(
      b.displayName.toLowerCase(),
    );
    if (nameComparison != 0) return nameComparison;

    return a.uid.compareTo(b.uid);
  }

  static int _compareNullableDistance(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static String _normalizeCategory(String value) {
    if (value.trim().isEmpty) return '';

    final normalized = value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    switch (normalized) {
      case 'crew':
      case 'equipe_tecnica':
      case 'equipe_tecnico':
      case 'tecnico':
      case 'tecnica':
        return 'crew';
      case 'cantor':
      case 'cantora':
      case 'cantor_a':
      case 'vocalista':
      case 'singer':
        return 'singer';
      case 'instrumentista':
      case 'instrumentalist':
        return 'instrumentalist';
      case 'dj':
        return 'dj';
      default:
        return normalized;
    }
  }
}
