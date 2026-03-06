import '../../../constants/firestore_constants.dart';
import 'feed_item.dart';

/// Builds a rotating spotlight window for the home carousel.
abstract final class SpotlightRotation {
  static const int visibleItems = 5;
  static const Duration rotationWindow = Duration(hours: 3);

  static List<FeedItem> build({
    required List<FeedItem> priorityItems,
    required List<FeedItem> candidateItems,
    DateTime? now,
    int maxItems = visibleItems,
  }) {
    if (maxItems <= 0) return const [];

    final poolByUid = <String, FeedItem>{};
    for (final item in [...priorityItems, ...candidateItems]) {
      if (!_isEligible(item)) continue;
      poolByUid.putIfAbsent(item.uid, () => item);
    }

    final pool = poolByUid.values.toList(growable: false);
    if (pool.length <= maxItems) return pool;

    final referenceTime = (now ?? DateTime.now()).toUtc();
    final bucketIndex =
        referenceTime.millisecondsSinceEpoch ~/ rotationWindow.inMilliseconds;
    final startIndex = (bucketIndex * maxItems) % pool.length;

    return List<FeedItem>.generate(
      maxItems,
      (index) => pool[(startIndex + index) % pool.length],
      growable: false,
    );
  }

  static bool _isEligible(FeedItem item) {
    return item.tipoPerfil == ProfileType.professional ||
        item.tipoPerfil == ProfileType.band ||
        item.tipoPerfil == ProfileType.studio;
  }
}
