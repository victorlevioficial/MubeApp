import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../features/gigs/domain/application_status.dart';
import '../../../utils/app_logger.dart';

enum ChatAccessTarget { conversations, requests }

enum ChatAccessReason {
  publicChat,
  favorite,
  matchpoint,
  acceptedGig,
  privateChat,
}

class ChatAccessDecision {
  const ChatAccessDecision({required this.target, required this.reason});

  final ChatAccessTarget target;
  final ChatAccessReason reason;

  bool get isAccepted => target == ChatAccessTarget.conversations;
  bool get isPending => target == ChatAccessTarget.requests;
}

class ChatAccessResolver {
  ChatAccessResolver(this._firestore);

  final FirebaseFirestore _firestore;
  static const Duration _decisionCacheTtl = Duration(seconds: 3);
  final Map<String, _CachedChatAccessDecision> _decisionCache = {};
  final Map<String, Future<ChatAccessDecision>> _inFlightDecisions = {};

  Future<ChatAccessDecision> resolveDelivery({
    required String senderId,
    required String recipientId,
    bool allowCached = true,
  }) async {
    final cacheKey = _decisionCacheKey(senderId, recipientId);
    if (!allowCached) {
      unawaited(_inFlightDecisions.remove(cacheKey));
      final decision = await _resolveDeliveryFresh(
        senderId: senderId,
        recipientId: recipientId,
      );
      _decisionCache[cacheKey] = _CachedChatAccessDecision(
        decision: decision,
        cachedAt: DateTime.now(),
      );
      return decision;
    }

    final now = DateTime.now();
    final cachedDecision = _decisionCache[cacheKey];
    if (cachedDecision != null &&
        now.difference(cachedDecision.cachedAt) < _decisionCacheTtl) {
      return cachedDecision.decision;
    }

    final inFlightDecision = _inFlightDecisions[cacheKey];
    if (inFlightDecision != null) {
      return await inFlightDecision;
    }

    final decisionFuture = _resolveDeliveryFresh(
      senderId: senderId,
      recipientId: recipientId,
    );
    _inFlightDecisions[cacheKey] = decisionFuture;

    try {
      final decision = await decisionFuture;
      _decisionCache[cacheKey] = _CachedChatAccessDecision(
        decision: decision,
        cachedAt: DateTime.now(),
      );
      return decision;
    } finally {
      unawaited(_inFlightDecisions.remove(cacheKey));
    }
  }

  Future<ChatAccessDecision> _resolveDeliveryFresh({
    required String senderId,
    required String recipientId,
  }) async {
    if (await _isRecipientChatOpen(recipientId)) {
      return const ChatAccessDecision(
        target: ChatAccessTarget.conversations,
        reason: ChatAccessReason.publicChat,
      );
    }

    if (await _hasRecipientFavoritedSender(
      recipientId: recipientId,
      senderId: senderId,
    )) {
      return const ChatAccessDecision(
        target: ChatAccessTarget.conversations,
        reason: ChatAccessReason.favorite,
      );
    }

    if (await _hasMatchBetween(senderId, recipientId)) {
      return const ChatAccessDecision(
        target: ChatAccessTarget.conversations,
        reason: ChatAccessReason.matchpoint,
      );
    }

    if (await _hasAcceptedGigBetween(senderId, recipientId)) {
      return const ChatAccessDecision(
        target: ChatAccessTarget.conversations,
        reason: ChatAccessReason.acceptedGig,
      );
    }

    return const ChatAccessDecision(
      target: ChatAccessTarget.requests,
      reason: ChatAccessReason.privateChat,
    );
  }

  String _decisionCacheKey(String senderId, String recipientId) {
    return '$senderId->$recipientId';
  }

  Future<bool> hasAuthorizationLink({
    required String senderId,
    required String recipientId,
  }) async {
    final decision = await resolveDelivery(
      senderId: senderId,
      recipientId: recipientId,
    );
    return decision.isAccepted;
  }

  Future<bool> _isRecipientChatOpen(String recipientId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(recipientId)
          .get();
      final data = snapshot.data();
      final privacySettings = data?['privacy_settings'];
      if (privacySettings is Map<String, dynamic>) {
        final chatOpen = privacySettings['chat_open'];
        if (chatOpen is bool) return chatOpen;
      } else if (privacySettings is Map) {
        final normalized = Map<String, dynamic>.from(privacySettings);
        final chatOpen = normalized['chat_open'];
        if (chatOpen is bool) return chatOpen;
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Chat access resolver: failed to read chat_open for $recipientId',
        error,
        stackTrace,
        false,
      );
      return false;
    }
  }

  Future<bool> _hasRecipientFavoritedSender({
    required String recipientId,
    required String senderId,
  }) async {
    try {
      final favoriteDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(recipientId)
          .collection('favorites')
          .doc(senderId)
          .get();
      return favoriteDoc.exists;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Chat access resolver: failed to check favorite authorization '
        '$recipientId <- $senderId',
        error,
        stackTrace,
        false,
      );
      return false;
    }
  }

  Future<bool> _hasMatchBetween(String userA, String userB) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.matches)
          .where('user_ids', arrayContains: userA)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userIds = data['user_ids'];
        if (userIds is! List) continue;
        if (userIds.whereType<String>().contains(userB)) {
          return true;
        }
      }
      return false;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Chat access resolver: failed to check match authorization '
        '$userA <-> $userB',
        error,
        stackTrace,
        false,
      );
      return false;
    }
  }

  Future<bool> _hasAcceptedGigBetween(String userA, String userB) async {
    final checks = await Future.wait<bool>([
      _hasAcceptedGigApplication(creatorId: userA, applicantId: userB),
      _hasAcceptedGigApplication(creatorId: userB, applicantId: userA),
    ]);
    return checks.any((value) => value);
  }

  Future<bool> _hasAcceptedGigApplication({
    required String creatorId,
    required String applicantId,
  }) async {
    try {
      final acceptedApplications = await _firestore
          .collectionGroup(FirestoreCollections.gigApplications)
          .where(GigFields.applicantId, isEqualTo: applicantId)
          .where(GigFields.status, isEqualTo: ApplicationStatus.accepted.name)
          .get();

      if (acceptedApplications.docs.isEmpty) {
        return false;
      }

      final gigRefs = <DocumentReference>[];
      for (final doc in acceptedApplications.docs) {
        final data = doc.data();
        final applicationCreatorId = (data[GigFields.creatorId] as String?)
            ?.trim();
        if (applicationCreatorId == creatorId) {
          return true;
        }

        final gigRef = doc.reference.parent.parent;
        if (gigRef == null) continue;
        gigRefs.add(gigRef);
      }

      if (gigRefs.isEmpty) {
        return false;
      }

      final gigSnapshots = await Future.wait(
        gigRefs.map((gigRef) => gigRef.get()),
      );
      for (final gigSnapshot in gigSnapshots) {
        final data = gigSnapshot.data();
        if (data is! Map<String, dynamic>) continue;
        if ((data[GigFields.creatorId] as String?)?.trim() == creatorId) {
          return true;
        }
      }
      return false;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Chat access resolver: failed to check accepted gig authorization '
        '$creatorId <-> $applicantId',
        error,
        stackTrace,
        false,
      );
      return false;
    }
  }
}

class _CachedChatAccessDecision {
  const _CachedChatAccessDecision({
    required this.decision,
    required this.cachedAt,
  });

  final ChatAccessDecision decision;
  final DateTime cachedAt;
}

final chatAccessResolverProvider = Provider<ChatAccessResolver>((ref) {
  return ChatAccessResolver(ref.read(firebaseFirestoreProvider));
});
