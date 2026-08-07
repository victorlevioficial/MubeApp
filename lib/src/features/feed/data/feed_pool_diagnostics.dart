import '../../../constants/firestore_constants.dart';
import '../domain/feed_discovery.dart';
import '../domain/feed_item.dart';

/// Mutable counters describing why documents were skipped (or kept) while
/// building a discovery pool. Reported to performance spans via [toMap].
final class FeedPoolDiagnostics {
  int skippedSelf = 0;
  int skippedBlocked = 0;
  int skippedType = 0;
  int skippedIncomplete = 0;
  int skippedInactive = 0;
  int skippedHidden = 0;
  int professionals = 0;
  int bands = 0;
  int studios = 0;
  int technicians = 0;
  int artists = 0;
  int resultsWithoutDistance = 0;

  void countAdded(FeedItem item) {
    switch (item.tipoPerfil) {
      case ProfileType.professional:
        professionals++;
        if (FeedDiscovery.isPureTechnician(item)) {
          technicians++;
        } else {
          artists++;
        }
        break;
      case ProfileType.band:
        bands++;
        break;
      case ProfileType.studio:
        studios++;
        break;
    }
  }

  Map<String, Object> toMap() {
    return {
      'skipped_self': skippedSelf,
      'skipped_blocked': skippedBlocked,
      'skipped_type': skippedType,
      'skipped_incomplete': skippedIncomplete,
      'skipped_inactive': skippedInactive,
      'skipped_hidden': skippedHidden,
      'pool_professionals': professionals,
      'pool_artists': artists,
      'pool_technicians': technicians,
      'pool_bands': bands,
      'pool_studios': studios,
      'results_without_distance': resultsWithoutDistance,
    };
  }
}
