import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../constants/firestore_constants.dart';
import '../../../utils/distance_calculator.dart';
import '../domain/feed_discovery.dart';
import '../domain/feed_item.dart';
import 'feed_pool_diagnostics.dart';

/// Pure mapping/filtering helpers that turn Firestore documents into visible
/// [FeedItem]s, applying the feed visibility rules (profile type, registration
/// status, activity, privacy) and distance calculation.
final class FeedItemMappers {
  const FeedItemMappers._();

  static List<FeedItem> processSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
    double? userLat,
    double? userLong,
  ) {
    final items = <FeedItem>[];

    for (final doc in snapshot.docs) {
      if (doc.id == currentUserId) continue;

      items.add(
        _withDistance(
          FeedItem.fromFirestore(doc.data(), doc.id),
          userLat,
          userLong,
        ),
      );
    }

    return items;
  }

  static List<FeedItem> processPublicContractorsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
    double? userLat,
    double? userLong,
    List<String> excludedIds,
  ) {
    final items = <FeedItem>[];

    for (final doc in snapshot.docs) {
      final item = buildVisiblePublicContractorFeedItem(
        data: doc.data(),
        docId: doc.id,
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        excludedIds: excludedIds,
      );
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  static FeedItem? buildVisibleFeedItem({
    required Map<String, dynamic> data,
    required String docId,
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    required List<String> excludedIds,
    FeedPoolDiagnostics? diagnostics,
  }) {
    if (docId == currentUserId) {
      diagnostics?.skippedSelf++;
      return null;
    }
    if (excludedIds.contains(docId)) {
      diagnostics?.skippedBlocked++;
      return null;
    }

    final tipoPerfil = data[FirestoreFields.profileType] as String?;
    if (tipoPerfil != ProfileType.professional &&
        tipoPerfil != ProfileType.band &&
        tipoPerfil != ProfileType.studio) {
      diagnostics?.skippedType++;
      return null;
    }

    final cadastroStatus = data[FirestoreFields.registrationStatus] as String?;
    if (cadastroStatus != RegistrationStatus.complete) {
      diagnostics?.skippedIncomplete++;
      return null;
    }

    final status = data['status'] as String? ?? 'ativo';
    if (status != 'ativo') {
      diagnostics?.skippedInactive++;
      return null;
    }

    final privacy = data['privacy_settings'] as Map<String, dynamic>?;
    if (privacy != null && privacy['visible_in_home'] == false) {
      diagnostics?.skippedHidden++;
      return null;
    }

    var item = FeedItem.fromFirestore(data, docId);

    if (userLat != null && userLong != null && item.location != null) {
      final itemLat = (item.location!['lat'] as num?)?.toDouble();
      final itemLng = (item.location!['lng'] as num?)?.toDouble();
      if (itemLat != null && itemLng != null) {
        item = item.copyWith(
          distanceKm: DistanceCalculator.haversine(
            fromLat: userLat,
            fromLng: userLong,
            toLat: itemLat,
            toLng: itemLng,
          ),
        );
      } else {
        diagnostics?.resultsWithoutDistance++;
      }
    } else {
      diagnostics?.resultsWithoutDistance++;
    }

    return item;
  }

  static FeedItem? buildVisiblePublicContractorFeedItem({
    required Map<String, dynamic> data,
    required String docId,
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    required List<String> excludedIds,
  }) {
    if (docId == currentUserId || excludedIds.contains(docId)) {
      return null;
    }

    final tipoPerfil = data[FirestoreFields.profileType] as String?;
    if (tipoPerfil != ProfileType.contractor) {
      return null;
    }

    final cadastroStatus = data[FirestoreFields.registrationStatus] as String?;
    if (cadastroStatus != RegistrationStatus.complete) {
      return null;
    }

    final status = data['status'] as String? ?? 'ativo';
    if (status != 'ativo') {
      return null;
    }

    final contractorData =
        data[FirestoreFields.contractor] as Map<String, dynamic>? ?? {};
    if (contractorData['isPublic'] != true) {
      return null;
    }

    return _withDistance(
      FeedItem.fromFirestore(data, docId),
      userLat,
      userLong,
    );
  }

  static List<FeedItem> filterProfessionals(
    List<FeedItem> items, {
    required bool techniciansOnly,
  }) {
    return items.where((item) {
      final pureTechnician = FeedDiscovery.isPureTechnician(item);
      return techniciansOnly ? pureTechnician : !pureTechnician;
    }).toList();
  }

  static List<FeedItem> mergeUniqueItems(
    List<FeedItem> primaryItems,
    List<FeedItem> secondaryItems,
  ) {
    final uniqueItems = <String, FeedItem>{};
    for (final item in primaryItems) {
      uniqueItems[item.uid] = item;
    }
    for (final item in secondaryItems) {
      uniqueItems[item.uid] = item;
    }
    return uniqueItems.values.toList(growable: false);
  }

  static FeedItem _withDistance(
    FeedItem item,
    double? userLat,
    double? userLong,
  ) {
    if (userLat == null || userLong == null || item.location == null) {
      return item;
    }

    final itemLat = (item.location!['lat'] as num?)?.toDouble();
    final itemLng = (item.location!['lng'] as num?)?.toDouble();
    if (itemLat == null || itemLng == null) {
      return item;
    }

    return item.copyWith(
      distanceKm: DistanceCalculator.haversine(
        fromLat: userLat,
        fromLng: userLong,
        toLat: itemLat,
        toLng: itemLng,
      ),
    );
  }
}
