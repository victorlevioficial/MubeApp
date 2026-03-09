import '../../../constants/firestore_constants.dart';
import '../../../utils/category_normalizer.dart';
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
    return CategoryNormalizer.isPureTechnician(
      rawCategories: item.subCategories,
      rawRoles: item.skills,
    );
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
}
