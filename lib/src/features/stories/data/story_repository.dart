import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../features/favorites/data/favorite_repository.dart';
import '../../../utils/app_check_refresh_coordinator.dart';
import '../../../utils/app_logger.dart';
import '../domain/story_constants.dart';
import '../domain/story_item.dart';
import '../domain/story_repository_exception.dart';
import '../domain/story_tray_bundle.dart';
import '../domain/story_upload_media.dart';
import '../domain/story_view_receipt.dart';
import '../domain/story_viewer_route_args.dart';
import 'story_media_uploader.dart';

export 'story_media_uploader.dart'
    show
        StoryImageUploadTarget,
        StoryMediaUploadResult,
        StoryMediaUploader,
        StoryPublishProgress,
        StoryPublishProgressCallback;

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository(
    ref.read(firebaseFirestoreProvider),
    ref.read(firebaseStorageProvider),
    ref.read(firebaseFunctionsProvider),
    ref.read(firebaseAuthProvider),
    ref.read(favoriteRepositoryProvider),
    appCheck: ref.read(firebaseAppCheckProvider),
  );
});

class StoryRepository {
  static const int _ownerQueryBatchSize = 10;
  static const int _publicStorySnapshotLimit = 120;
  static const int _publicTrayOwnerLimit = 48;
  static const Duration _forcedAppCheckRefreshCooldown = Duration(minutes: 2);
  static const Duration _throttledAppCheckBackoff = Duration(minutes: 10);

  StoryRepository(
    this._firestore,
    this._storage,
    this._functions,
    this._auth,
    this._favoriteRepository, {
    app_check.FirebaseAppCheck? appCheck,
  }) : _appCheck = appCheck;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final FavoriteRepository _favoriteRepository;
  final app_check.FirebaseAppCheck? _appCheck;

  late final StoryMediaUploader _mediaUploader = StoryMediaUploader(
    _storage,
    ensureSecurityContext: _ensureSecurityContext,
  );

  String? _cachedViewerUid;
  String? _cachedViewerName;
  String? _cachedViewerPhoto;

  String get _uid {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StoryRepositoryException.unauthenticated();
    }
    return currentUser.uid;
  }

  Future<List<StoryTrayBundle>> loadTray({
    Iterable<String> discoveryOwnerIds = const <String>[],
    bool includePublicOwners = true,
  }) async {
    final uid = _uid;
    final now = Timestamp.now();
    final favoriteIdsFuture = _favoriteRepository.loadFavorites();
    final seenAuthorsFuture = _loadSeenAuthorTimestamps(uid);
    final blockedIdsFuture = _loadBlockedIds(uid);
    final publicOwnerIdsFuture = includePublicOwners
        ? _loadPublicOwnerIds(now: now)
        : Future.value(const <String>{});
    final results = await Future.wait([
      favoriteIdsFuture,
      seenAuthorsFuture,
      blockedIdsFuture,
      publicOwnerIdsFuture,
    ]);

    final favoriteIds = results[0] as Set<String>;
    final seenAuthors = results[1] as Map<String, DateTime>;
    final blockedIds = results[2] as Set<String>;
    final publicOwnerIds = results[3] as Set<String>;

    final candidateOwnerIds =
        <String>{uid, ...favoriteIds, ...discoveryOwnerIds, ...publicOwnerIds}
          ..removeWhere(
            (ownerUid) =>
                ownerUid.trim().isEmpty ||
                (blockedIds.contains(ownerUid) && ownerUid != uid),
          );

    final ownerIdsToQuery = await _resolveOwnersToQuery(
      candidateOwnerIds,
      currentUserId: uid,
      blockedIds: blockedIds,
      forcedOwnerIds: publicOwnerIds,
    );

    return _loadBundlesForOwners(
      ownerIds: ownerIdsToQuery,
      favoriteIds: favoriteIds,
      seenAuthors: seenAuthors,
      blockedIds: blockedIds,
      currentUid: uid,
    );
  }

  Future<StoryViewerRouteArgs> loadViewerRouteArgs(String storyId) async {
    final uid = _uid;
    final storyDoc = await _firestore
        .collection(StoryConstants.storiesCollection)
        .doc(storyId)
        .get();
    if (!storyDoc.exists) {
      throw StoryRepositoryException.storyUnavailable();
    }

    final story = StoryItem.fromJson(
      storyDoc.data() ?? <String, dynamic>{},
      id: storyDoc.id,
    );
    if (story.ownerUid.isEmpty) {
      throw StoryRepositoryException.storyUnavailable();
    }

    final results = await Future.wait([
      _favoriteRepository.loadFavorites(),
      _loadSeenAuthorTimestamps(uid),
      _loadBlockedIds(uid),
    ]);
    final favoriteIds = results[0] as Set<String>;
    final seenAuthors = results[1] as Map<String, DateTime>;
    final blockedIds = results[2] as Set<String>;
    final isCurrentUserStory = story.ownerUid == uid;

    if (blockedIds.contains(story.ownerUid) && !isCurrentUserStory) {
      throw StoryRepositoryException.storyUnavailable();
    }
    if (!story.isActive && !isCurrentUserStory) {
      throw StoryRepositoryException.storyUnavailable();
    }

    final ownerIdsToQuery = await _resolveOwnersToQuery(
      <String>{story.ownerUid},
      currentUserId: uid,
      blockedIds: blockedIds,
      forcedOwnerIds: !isCurrentUserStory && story.isActive
          ? <String>{story.ownerUid}
          : const <String>{},
    );
    if (ownerIdsToQuery.isEmpty) {
      throw StoryRepositoryException.storyUnavailable();
    }

    final bundles = await _loadBundlesForOwners(
      ownerIds: ownerIdsToQuery,
      favoriteIds: favoriteIds,
      seenAuthors: seenAuthors,
      blockedIds: blockedIds,
      currentUid: uid,
    );

    if (bundles.isEmpty) {
      throw StoryRepositoryException.storyUnavailable();
    }

    return StoryViewerRouteArgs(
      bundles: bundles,
      initialOwnerUid: story.ownerUid,
      initialStoryId: storyId,
    );
  }

  Future<void> publishStory({
    required StoryUploadMedia media,
    String? caption,
    StoryPublishProgressCallback? onProgress,
  }) async {
    final uid = _uid;
    final storyId = const Uuid().v4();
    final normalizedCaption = caption?.trim();
    var didReserveStory = false;

    try {
      emitStoryPublishProgress(onProgress, 0.04, 'Validando sessao');
      await _ensureSecurityContext(operationLabel: 'publicacao de story');

      emitStoryPublishProgress(onProgress, 0.08, 'Reservando story');
      await _callFunctionWithRecovery(
        'beginStoryUpload',
        data: {
          'storyId': storyId,
          'mediaType': media.mediaType.name,
          'caption': normalizedCaption,
          'durationSeconds': media.durationSeconds,
          'aspectRatio': media.aspectRatio,
        },
      );
      didReserveStory = true;

      emitStoryPublishProgress(onProgress, 0.12, 'Preparando upload');
      final upload = await _mediaUploader.uploadStoryMedia(
        userId: uid,
        storyId: storyId,
        media: media,
        onProgress: onProgress,
      );

      if (media.mediaType == StoryMediaType.video) {
        emitStoryPublishProgress(onProgress, 1.0, 'Story enviado');
        return;
      }

      emitStoryPublishProgress(onProgress, 0.94, 'Finalizando story');
      await _callFunctionWithRecovery(
        'publishStory',
        data: {
          'storyId': storyId,
          'mediaType': media.mediaType.name,
          'mediaUrl': upload.mediaUrl,
          'thumbnailUrl': upload.thumbnailUrl,
          'caption': normalizedCaption,
          'durationSeconds': media.durationSeconds,
          'aspectRatio': media.aspectRatio,
        },
      );
      emitStoryPublishProgress(onProgress, 1.0, 'Story publicado');
    } on FirebaseFunctionsException catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao finalizar publicacao do story',
        error,
        stackTrace,
      );
      if (await _isStoryAcceptedAfterPublishFailure(storyId, media.mediaType)) {
        emitStoryPublishProgress(onProgress, 1.0, 'Story publicado');
        return;
      }
      if (didReserveStory) await _abandonPreparedStory(storyId);
      throw StoryRepositoryException.publishFailed(error.message);
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao finalizar publicacao do story',
        error,
        stackTrace,
      );
      if (await _isStoryAcceptedAfterPublishFailure(storyId, media.mediaType)) {
        emitStoryPublishProgress(onProgress, 1.0, 'Story publicado');
        return;
      }
      if (didReserveStory) await _abandonPreparedStory(storyId);
      throw StoryRepositoryException.publishFailed(error.message);
    } on AppCheckRefreshException catch (error, stackTrace) {
      AppLogger.error(
        'Falha de App Check ao publicar story',
        error,
        stackTrace,
      );
      if (didReserveStory) await _abandonPreparedStory(storyId);
      throw StoryRepositoryException.publishFailed(error.message);
    } on StoryRepositoryException catch (error) {
      if (error.code == StoryRepositoryExceptionCode.uploadFailed ||
          error.code == StoryRepositoryExceptionCode.uploadFileMissing) {
        if (didReserveStory) await _abandonPreparedStory(storyId);
      }
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao finalizar publicacao do story',
        error,
        stackTrace,
      );
      if (await _isStoryAcceptedAfterPublishFailure(storyId, media.mediaType)) {
        emitStoryPublishProgress(onProgress, 1.0, 'Story publicado');
        return;
      }
      if (didReserveStory) await _abandonPreparedStory(storyId);
      throw StoryRepositoryException.publishFailed();
    }
  }

  Future<void> deleteStory(StoryItem story) async {
    try {
      await _callFunctionWithRecovery(
        'deleteStory',
        data: {'storyId': story.id},
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      AppLogger.error('Falha ao excluir story', error, stackTrace);
      throw StoryRepositoryException.deleteFailed();
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao excluir story', error, stackTrace);
      throw StoryRepositoryException.deleteFailed();
    } catch (error, stackTrace) {
      AppLogger.error('Falha ao excluir story', error, stackTrace);
      throw StoryRepositoryException.deleteFailed();
    }
  }

  Future<HttpsCallableResult<dynamic>> _callFunctionWithRecovery(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    final callable = _functions.httpsCallable(functionName);

    try {
      return await callable.call(data);
    } on FirebaseFunctionsException catch (error) {
      if (!_isRecoverableFunctionsError(error)) rethrow;

      AppLogger.warning(
        '$functionName retornou ${error.code}. Atualizando contexto e tentando novamente.',
      );
      await _ensureSecurityContext(
        operationLabel: 'retry de $functionName',
        forceAuthRefresh: true,
      );
      return callable.call(data);
    }
  }

  Future<void> _ensureSecurityContext({
    required String operationLabel,
    bool forceAuthRefresh = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StoryRepositoryException.unauthenticated();
    }

    if (forceAuthRefresh) {
      try {
        await currentUser.getIdToken(true);
        await currentUser.reload();
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Falha ao atualizar token FirebaseAuth para stories',
          error,
          stackTrace,
          false,
        );
      }
    }

    final appCheck = _appCheck;
    if (appCheck == null) return;

    await AppCheckRefreshCoordinator.ensureValidTokenOrThrow(
      appCheck,
      operationLabel: operationLabel,
      forcedRefreshCooldown: _forcedAppCheckRefreshCooldown,
      throttledBackoff: _throttledAppCheckBackoff,
    );
  }

  bool _isRecoverableFunctionsError(FirebaseFunctionsException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code == 'unauthenticated') return true;

    final mentionsAppCheck = message.contains('app check');
    return mentionsAppCheck &&
        (code == 'failed-precondition' || code == 'permission-denied');
  }

  Future<bool> _isStoryAcceptedAfterPublishFailure(
    String storyId,
    StoryMediaType mediaType,
  ) async {
    try {
      final doc = await _firestore
          .collection(StoryConstants.storiesCollection)
          .doc(storyId)
          .get();
      if (!doc.exists) return false;
      final story = StoryItem.fromJson(doc.data() ?? const {}, id: doc.id);
      if (story.ownerUid != _auth.currentUser?.uid) return false;
      if (mediaType == StoryMediaType.video) {
        return story.status == StoryStatus.processing || story.isActive;
      }
      return story.isActive;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao reconciliar status do story apos erro de publicacao',
        error,
        stackTrace,
      );
      return false;
    }
  }

  Future<void> _abandonPreparedStory(String storyId) async {
    try {
      await _callFunctionWithRecovery(
        'deleteStory',
        data: {'storyId': storyId},
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao limpar story reservado apos erro de upload',
        error,
        stackTrace,
      );
    }
  }

  Future<void> markStoryViewed(StoryItem story) async {
    final uid = _uid;
    if (story.ownerUid == uid) return;

    // Resolve the viewer's display identity once per session instead of
    // re-reading the full user document on every single story view.
    if (_cachedViewerUid != uid) {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? const <String, dynamic>{};
      _cachedViewerName = _resolveDisplayName(userData);
      _cachedViewerPhoto =
          (userData['foto_thumb'] as String?) ?? userData['foto'] as String?;
      _cachedViewerUid = uid;
    }
    final viewerName = _cachedViewerName;
    final viewerPhoto = _cachedViewerPhoto;

    final viewRef = _firestore
        .collection(StoryConstants.storiesCollection)
        .doc(story.id)
        .collection(StoryConstants.viewsSubcollection)
        .doc(uid);

    try {
      // Firestore rules only allow `create` for view receipts. A second
      // viewing of the same story would fall into `update` and trigger a
      // permission-denied error, so we treat that as a no-op.
      await viewRef.set({
        'viewer_uid': uid,
        'viewer_name': viewerName,
        'viewer_photo': viewerPhoto,
        'viewed_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'permission-denied' || error.code == 'already-exists') {
        return;
      }
      AppLogger.warning(
        'Falha ao registrar visualizacao do story',
        error,
        stackTrace,
      );
    }
  }

  Future<List<StoryItem>> loadCurrentUserProcessingStories() async {
    final uid = _uid;
    try {
      final snapshot = await _firestore
          .collection(StoryConstants.storiesCollection)
          .where('owner_uid', isEqualTo: uid)
          .where(
            'status',
            whereIn: [
              StoryConstants.statusProcessing,
              StoryConstants.statusUploading,
            ],
          )
          .where('expires_at', isGreaterThan: Timestamp.now())
          .orderBy('expires_at')
          .limit(20)
          .get();

      final now = DateTime.now();
      final stories =
          snapshot.docs
              .map((doc) => StoryItem.fromJson(doc.data(), id: doc.id))
              .where(
                (story) =>
                    story.ownerUid == uid &&
                    (story.status == StoryStatus.processing ||
                        story.status == StoryStatus.uploading) &&
                    story.expiresAt.isAfter(now),
              )
              .toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return stories;
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao carregar stories em processamento do usuario atual',
        error,
        stackTrace,
      );
      throw StoryRepositoryException.loadTrayFailed();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao carregar stories em processamento do usuario atual',
        error,
        stackTrace,
      );
      throw StoryRepositoryException.loadTrayFailed();
    }
  }

  Future<List<StoryViewReceipt>> loadViewers(String storyId) async {
    try {
      final snapshot = await _firestore
          .collection(StoryConstants.storiesCollection)
          .doc(storyId)
          .collection(StoryConstants.viewsSubcollection)
          .orderBy('viewed_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StoryViewReceipt.fromJson(doc.data(), id: doc.id))
          .toList(growable: false);
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao carregar visualizacoes do story',
        error,
        stackTrace,
      );
      throw StoryRepositoryException.loadViewersFailed();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao carregar visualizacoes do story',
        error,
        stackTrace,
      );
      throw StoryRepositoryException.loadViewersFailed();
    }
  }

  Future<Set<String>> _resolveOwnersToQuery(
    Set<String> candidateOwnerIds, {
    required String currentUserId,
    required Set<String> blockedIds,
    Set<String> forcedOwnerIds = const <String>{},
  }) async {
    if (candidateOwnerIds.isEmpty) {
      return const <String>{};
    }

    final ownerIds = candidateOwnerIds.toList(growable: false);
    final userDocs = await _loadUsersByIds(ownerIds);
    final docsById = <String, Map<String, dynamic>>{
      for (final doc in userDocs) doc.id: doc.data(),
    };
    final ownerIdsToQuery = <String>{};

    for (final ownerUid in ownerIds) {
      final isForcedPublicOwner = forcedOwnerIds.contains(ownerUid);

      if (ownerUid == currentUserId) {
        ownerIdsToQuery.add(ownerUid);
        continue;
      }
      if (blockedIds.contains(ownerUid)) {
        continue;
      }

      final ownerData = docsById[ownerUid];
      if (ownerData == null) {
        if (isForcedPublicOwner) {
          ownerIdsToQuery.add(ownerUid);
        }
        continue;
      }
      if (_readStringSet(ownerData['blocked_users']).contains(currentUserId)) {
        continue;
      }

      final accountStatus = ownerData['status'] as String? ?? 'ativo';
      if (accountStatus != 'ativo') {
        continue;
      }

      if (isForcedPublicOwner) {
        ownerIdsToQuery.add(ownerUid);
        continue;
      }

      final cadastroStatus = ownerData['cadastro_status'] as String?;
      if (cadastroStatus != null && cadastroStatus != 'concluido') {
        continue;
      }

      final storyState = ownerData['story_state'];
      final hasActiveStory = storyState is Map<String, dynamic>
          ? storyState['has_active_story'] == true
          : storyState is Map
          ? storyState['has_active_story'] == true
          : null;

      if (hasActiveStory == true || hasActiveStory == null) {
        ownerIdsToQuery.add(ownerUid);
      }
    }

    return ownerIdsToQuery;
  }

  Future<List<StoryTrayBundle>> _loadBundlesForOwners({
    required Set<String> ownerIds,
    required Set<String> favoriteIds,
    required Map<String, DateTime> seenAuthors,
    required Set<String> blockedIds,
    required String currentUid,
  }) async {
    if (ownerIds.isEmpty) {
      return const <StoryTrayBundle>[];
    }

    final now = Timestamp.now();
    final storySnapshots = await _loadActiveStorySnapshots(
      ownerIds: ownerIds,
      now: now,
    );

    final nowDate = DateTime.now();
    final grouped = <String, List<StoryItem>>{};

    for (final snapshot in storySnapshots) {
      for (final doc in snapshot.docs) {
        final story = StoryItem.fromJson(doc.data(), id: doc.id);
        if (story.ownerUid.isEmpty ||
            (blockedIds.contains(story.ownerUid) &&
                story.ownerUid != currentUid) ||
            story.status != StoryStatus.active ||
            !story.expiresAt.isAfter(nowDate)) {
          continue;
        }

        grouped.putIfAbsent(story.ownerUid, () => <StoryItem>[]).add(story);
      }
    }

    final bundles =
        grouped.entries
            .map((entry) {
              final stories = [...entry.value]
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              final latestStoryAt = stories.last.createdAt;
              final seenAt = seenAuthors[entry.key];
              final hasUnseen =
                  seenAt == null || seenAt.isBefore(latestStoryAt);
              final latestStory = stories.last;
              return StoryTrayBundle(
                ownerUid: latestStory.ownerUid,
                ownerName: latestStory.ownerName,
                ownerPhoto: latestStory.ownerPhoto,
                ownerPhotoPreview: latestStory.ownerPhotoPreview,
                ownerType: latestStory.ownerType,
                stories: stories,
                hasUnseen: hasUnseen,
                isFavorite: favoriteIds.contains(latestStory.ownerUid),
                isCurrentUser: latestStory.ownerUid == currentUid,
              );
            })
            .toList(growable: false)
          ..sort(_compareBundles);

    return bundles;
  }

  Future<List<QuerySnapshot<Map<String, dynamic>>>> _loadActiveStorySnapshots({
    required Set<String> ownerIds,
    required Timestamp now,
  }) async {
    final ownerIdList = ownerIds.toList(growable: false)..sort();
    final batchFutures = <Future<List<QuerySnapshot<Map<String, dynamic>>>>>[];

    for (var i = 0; i < ownerIdList.length; i += _ownerQueryBatchSize) {
      final end = (i + _ownerQueryBatchSize).clamp(0, ownerIdList.length);
      final batchOwnerIds = ownerIdList.sublist(i, end);
      batchFutures.add(
        _loadActiveStorySnapshotBatch(ownerIds: batchOwnerIds, now: now),
      );
    }

    final results = await Future.wait(batchFutures);
    return results.expand((batch) => batch).toList(growable: false);
  }

  Future<Set<String>> _loadPublicOwnerIds({required Timestamp now}) async {
    final results = await Future.wait([
      _loadPublicOwnerIdsFromUserState(),
      _loadPublicOwnerIdsFromGlobalSnapshot(now: now),
    ]);

    return <String>{...results[0], ...results[1]};
  }

  Future<Set<String>> _loadPublicOwnerIdsFromGlobalSnapshot({
    required Timestamp now,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(StoryConstants.storiesCollection)
          .where('status', isEqualTo: StoryConstants.statusActive)
          .where('expires_at', isGreaterThan: now)
          .orderBy('expires_at', descending: true)
          .limit(_publicStorySnapshotLimit)
          .get();

      final ownerIds = <String>{};
      for (final doc in snapshot.docs) {
        final ownerUid = (doc.data()['owner_uid'] as String?)?.trim();
        if (ownerUid == null || ownerUid.isEmpty) {
          continue;
        }

        ownerIds.add(ownerUid);
        if (ownerIds.length >= _publicTrayOwnerLimit) {
          break;
        }
      }

      return ownerIds;
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao carregar owners publicos de stories pelo snapshot global',
        error,
        stackTrace,
      );
      return const <String>{};
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao carregar owners publicos de stories pelo snapshot global',
        error,
        stackTrace,
      );
      return const <String>{};
    }
  }

  Future<Set<String>> _loadPublicOwnerIdsFromUserState() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('story_state.has_active_story', isEqualTo: true)
          .orderBy('story_state.latest_story_at', descending: true)
          .limit(_publicTrayOwnerLimit * 3)
          .get();

      final rankedOwners =
          snapshot.docs
              .map((doc) {
                final data = doc.data();
                final ownerUid = doc.id.trim();
                final accountStatus = (data['status'] as String?)?.trim() ?? '';
                final latestStoryAt = _parseStoryStateTimestamp(
                  (data['story_state'] as Map?)?['latest_story_at'],
                );
                return (
                  ownerUid: ownerUid,
                  isActiveAccount:
                      accountStatus.isEmpty || accountStatus == 'ativo',
                  latestStoryAt: latestStoryAt,
                );
              })
              .where(
                (entry) => entry.ownerUid.isNotEmpty && entry.isActiveAccount,
              )
              .toList(growable: false)
            ..sort((a, b) => b.latestStoryAt.compareTo(a.latestStoryAt));

      final ownerIds = <String>{};
      for (final entry in rankedOwners) {
        ownerIds.add(entry.ownerUid);
        if (ownerIds.length >= _publicTrayOwnerLimit) {
          break;
        }
      }

      return ownerIds;
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao carregar owners publicos pelo story_state dos usuarios',
        error,
        stackTrace,
      );
      return const <String>{};
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao carregar owners publicos pelo story_state dos usuarios',
        error,
        stackTrace,
      );
      return const <String>{};
    }
  }

  DateTime _parseStoryStateTimestamp(dynamic rawValue) {
    if (rawValue is Timestamp) {
      return rawValue.toDate();
    }
    if (rawValue is DateTime) {
      return rawValue;
    }
    if (rawValue is String) {
      return DateTime.tryParse(rawValue) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<List<QuerySnapshot<Map<String, dynamic>>>>
  _loadActiveStorySnapshotBatch({
    required List<String> ownerIds,
    required Timestamp now,
  }) async {
    if (ownerIds.isEmpty) {
      return const <QuerySnapshot<Map<String, dynamic>>>[];
    }

    try {
      final baseQuery = _firestore
          .collection(StoryConstants.storiesCollection)
          .where('status', isEqualTo: StoryConstants.statusActive)
          .where('expires_at', isGreaterThan: now);
      final snapshot =
          await (ownerIds.length == 1
                  ? baseQuery.where('owner_uid', isEqualTo: ownerIds.single)
                  : baseQuery.where('owner_uid', whereIn: ownerIds))
              .orderBy('expires_at')
              .get();
      return <QuerySnapshot<Map<String, dynamic>>>[snapshot];
    } on FirebaseException catch (error, stackTrace) {
      if (error.code != 'permission-denied') {
        rethrow;
      }

      if (ownerIds.length == 1) {
        AppLogger.warning(
          'Story tray ignorou owner sem permissao de leitura',
          error,
          stackTrace,
        );
        return const <QuerySnapshot<Map<String, dynamic>>>[];
      }

      final midpoint = ownerIds.length ~/ 2;
      final leftSnapshots = await _loadActiveStorySnapshotBatch(
        ownerIds: ownerIds.sublist(0, midpoint),
        now: now,
      );
      final rightSnapshots = await _loadActiveStorySnapshotBatch(
        ownerIds: ownerIds.sublist(midpoint),
        now: now,
      );
      return <QuerySnapshot<Map<String, dynamic>>>[
        ...leftSnapshots,
        ...rightSnapshots,
      ];
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadUsersByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return const [];
    }

    const batchSize = 10;
    final batchFutures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < ids.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, ids.length);
      final batchIds = ids.sublist(i, end);
      batchFutures.add(
        _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get(),
      );
    }

    final results = await Future.wait(batchFutures);
    return results.expand((snapshot) => snapshot.docs).toList(growable: false);
  }

  Future<Map<String, DateTime>> _loadSeenAuthorTimestamps(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection(StoryConstants.storySeenAuthorsSubcollection)
        .get();

    final seen = <String, DateTime>{};
    for (final doc in snapshot.docs) {
      final raw = doc.data()['last_seen_at'];
      final lastSeenAt = raw is Timestamp
          ? raw.toDate()
          : DateTime.tryParse(raw?.toString() ?? '');
      if (lastSeenAt != null) {
        seen[doc.id] = lastSeenAt;
      }
    }
    return seen;
  }

  Future<Set<String>> _loadBlockedIds(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao carregar bloqueados para stories',
        error,
        stackTrace,
      );
      return <String>{};
    }
  }

  int _compareBundles(StoryTrayBundle a, StoryTrayBundle b) {
    if (a.isCurrentUser != b.isCurrentUser) {
      return a.isCurrentUser ? -1 : 1;
    }

    if (a.isFavorite != b.isFavorite) {
      return a.isFavorite ? -1 : 1;
    }

    if (a.hasUnseen != b.hasUnseen) {
      return a.hasUnseen ? -1 : 1;
    }

    return b.latestStoryAt.compareTo(a.latestStoryAt);
  }

  String _resolveDisplayName(Map<String, dynamic> userData) {
    final profileType = userData['tipo_perfil'] as String?;
    switch (profileType) {
      case 'profissional':
        return (userData['profissional']?['nomeArtistico'] as String?) ??
            (userData['nome'] as String?) ??
            'Profissional';
      case 'banda':
        return (userData['banda']?['nomeBanda'] as String?) ??
            (userData['nome'] as String?) ??
            'Banda';
      case 'estudio':
        return (userData['estudio']?['nomeEstudio'] as String?) ??
            (userData['nome'] as String?) ??
            'Estúdio';
      case 'contratante':
        return (userData['contratante']?['nomeExibicao'] as String?) ??
            (userData['nome'] as String?) ??
            'Contratante';
      default:
        return (userData['nome'] as String?) ?? 'Usuário';
    }
  }

  Set<String> _readStringSet(Object? value) {
    if (value is! Iterable) {
      return const <String>{};
    }

    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }
}
