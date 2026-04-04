import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../features/favorites/data/favorite_repository.dart';
import '../../../features/storage/domain/image_compressor.dart';
import '../../../utils/app_logger.dart';
import '../domain/story_constants.dart';
import '../domain/story_item.dart';
import '../domain/story_repository_exception.dart';
import '../domain/story_tray_bundle.dart';
import '../domain/story_upload_media.dart';
import '../domain/story_view_receipt.dart';
import '../domain/story_viewer_route_args.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository(
    ref.read(firebaseFirestoreProvider),
    ref.read(firebaseStorageProvider),
    ref.read(firebaseFunctionsProvider),
    ref.read(firebaseAuthProvider),
    ref.read(favoriteRepositoryProvider),
  );
});

typedef StoryPublishProgressCallback =
    void Function(StoryPublishProgress progress);

class StoryPublishProgress {
  const StoryPublishProgress({required this.value, required this.label});

  final double value;
  final String label;
}

class StoryRepository {
  static const int _ownerQueryBatchSize = 10;
  static const int _publicStorySnapshotLimit = 120;
  static const int _publicTrayOwnerLimit = 48;
  static const Duration _uploadNoProgressTimeout = Duration(seconds: 45);

  StoryRepository(
    this._firestore,
    this._storage,
    this._functions,
    this._auth,
    this._favoriteRepository,
  );

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final FavoriteRepository _favoriteRepository;

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
    _emitProgress(onProgress, 0.08, 'Preparando upload');
    final upload = await _uploadStoryMedia(
      userId: uid,
      storyId: storyId,
      media: media,
      onProgress: onProgress,
    );

    _emitProgress(onProgress, 0.94, 'Finalizando story');
    final callable = _functions.httpsCallable('publishStory');
    try {
      await callable.call({
        'storyId': storyId,
        'mediaType': media.mediaType.name,
        'mediaUrl': upload.mediaUrl,
        'thumbnailUrl': upload.thumbnailUrl,
        'caption': caption?.trim(),
        'durationSeconds': media.durationSeconds,
        'aspectRatio': media.aspectRatio,
      });
    } on FirebaseFunctionsException catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao finalizar publicacao do story',
        error,
        stackTrace,
      );
      throw StoryRepositoryException.publishFailed(error.message);
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao finalizar publicacao do story',
        error,
        stackTrace,
      );
      throw StoryRepositoryException.publishFailed(error.message);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Falha ao finalizar publicacao do story',
        error,
        stackTrace,
      );
      throw StoryRepositoryException.publishFailed();
    }
    _emitProgress(onProgress, 1.0, 'Story publicado');
  }

  Future<void> deleteStory(StoryItem story) async {
    final callable = _functions.httpsCallable('deleteStory');
    try {
      await callable.call({'storyId': story.id});
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

  Future<void> markStoryViewed(StoryItem story) async {
    final uid = _uid;
    if (story.ownerUid == uid) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? const <String, dynamic>{};
    final viewerName = _resolveDisplayName(userData);
    final viewerPhoto =
        (userData['foto_thumb'] as String?) ?? userData['foto'] as String?;

    await _firestore
        .collection(StoryConstants.storiesCollection)
        .doc(story.id)
        .collection(StoryConstants.viewsSubcollection)
        .doc(uid)
        .set({
          'viewer_uid': uid,
          'viewer_name': viewerName,
          'viewer_photo': viewerPhoto,
          'viewed_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<List<StoryItem>> loadCurrentUserProcessingStories() async {
    final uid = _uid;
    try {
      final snapshot = await _firestore
          .collection(StoryConstants.storiesCollection)
          .where('owner_uid', isEqualTo: uid)
          .limit(10)
          .get();

      final now = DateTime.now();
      final stories =
          snapshot.docs
              .map((doc) => StoryItem.fromJson(doc.data(), id: doc.id))
              .where(
                (story) =>
                    story.ownerUid == uid &&
                    story.status == StoryStatus.processing &&
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
    final ownerIdsFromUserState = await _loadPublicOwnerIdsFromUserState();
    if (ownerIdsFromUserState.isNotEmpty) {
      return ownerIdsFromUserState;
    }

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
    final batchFutures =
        <Future<QuerySnapshot<Map<String, dynamic>>>>[];
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

  Future<_StoryMediaUploadResult> _uploadStoryMedia({
    required String userId,
    required String storyId,
    required StoryUploadMedia media,
    StoryPublishProgressCallback? onProgress,
  }) async {
    if (media.mediaType == StoryMediaType.image) {
      return _uploadImageStory(
        userId: userId,
        storyId: storyId,
        media: media,
        onProgress: onProgress,
      );
    }

    return _uploadVideoStory(
      userId: userId,
      storyId: storyId,
      media: media,
      onProgress: onProgress,
    );
  }

  Future<_StoryMediaUploadResult> _uploadImageStory({
    required String userId,
    required String storyId,
    required StoryUploadMedia media,
    StoryPublishProgressCallback? onProgress,
  }) async {
    File fullFile;
    File thumbFile;
    try {
      _emitProgress(onProgress, 0.12, 'Otimizando foto');
      fullFile = await ImageCompressor.compressGalleryPhoto(
        media.file,
        format: ImageFormat.webp,
      );
      thumbFile = await ImageCompressor.compressThumbnail(media.file);
    } catch (e, stack) {
      AppLogger.error('Falha ao comprimir imagem do story', e, stack);
      fullFile = media.file;
      thumbFile = media.file;
    }
    final fullUploadTarget = resolveImageUploadTarget(
      file: fullFile,
      basePathWithoutExtension: 'stories_images/$userId/$storyId/full',
    );
    final thumbUploadTarget = resolveImageUploadTarget(
      file: thumbFile,
      basePathWithoutExtension: 'stories_images/$userId/$storyId/thumb',
    );

    final fullUrl = await _uploadFile(
      file: fullFile,
      path: fullUploadTarget.path,
      contentType: fullUploadTarget.contentType,
      onProgress: (progress) {
        _emitProgress(
          onProgress,
          _progressBetween(progress, start: 0.18, end: 0.78),
          'Enviando foto',
        );
      },
    );
    final thumbUrl = await _uploadFile(
      file: thumbFile,
      path: thumbUploadTarget.path,
      contentType: thumbUploadTarget.contentType,
      onProgress: (progress) {
        _emitProgress(
          onProgress,
          _progressBetween(progress, start: 0.78, end: 0.9),
          'Enviando preview',
        );
      },
    );

    return _StoryMediaUploadResult(mediaUrl: fullUrl, thumbnailUrl: thumbUrl);
  }

  Future<_StoryMediaUploadResult> _uploadVideoStory({
    required String userId,
    required String storyId,
    required StoryUploadMedia media,
    StoryPublishProgressCallback? onProgress,
  }) async {
    File? thumbFile;
    if (media.thumbnailFile != null) {
      try {
        _emitProgress(onProgress, 0.12, 'Preparando thumb do video');
        thumbFile = await ImageCompressor.compressThumbnail(
          media.thumbnailFile!,
        );
      } catch (e, stack) {
        AppLogger.error('Falha ao comprimir thumbnail do video', e, stack);
        thumbFile = media.thumbnailFile;
      }
    }

    if (!await media.file.exists()) {
      throw StoryRepositoryException.uploadFileMissing();
    }

    final videoUrl = await _uploadFile(
      file: media.file,
      path: 'stories_videos_source/$userId/$storyId/source.mp4',
      contentType: 'video/mp4',
      onProgress: (progress) {
        _emitProgress(
          onProgress,
          _progressBetween(
            progress,
            start: 0.18,
            end: thumbFile == null ? 0.9 : 0.86,
          ),
          'Enviando video',
        );
      },
    );
    String? thumbUrl;
    if (thumbFile != null) {
      final thumbUploadTarget = resolveImageUploadTarget(
        file: thumbFile,
        basePathWithoutExtension:
            'stories_videos_thumbs/$userId/$storyId/thumb',
      );
      try {
        thumbUrl = await _uploadFile(
          file: thumbFile,
          path: thumbUploadTarget.path,
          contentType: thumbUploadTarget.contentType,
          onProgress: (progress) {
            _emitProgress(
              onProgress,
              _progressBetween(progress, start: 0.86, end: 0.92),
              'Enviando preview',
            );
          },
        );
      } catch (e, stack) {
        AppLogger.warning(
          'Falha ao upload thumbnail, continuando sem',
          e,
          stack,
        );
      }
    }

    return _StoryMediaUploadResult(mediaUrl: videoUrl, thumbnailUrl: thumbUrl);
  }

  Future<String> _uploadFile({
    required File file,
    required String path,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    StreamSubscription<TaskSnapshot>? progressSubscription;
    var uploadTimedOut = false;
    try {
      if (!await file.exists()) {
        throw StoryRepositoryException.uploadFileMissing();
      }
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putFile(file, metadata);
      onProgress?.call(0);
      progressSubscription = uploadTask.snapshotEvents
          .timeout(
            _uploadNoProgressTimeout,
            onTimeout: (sink) {
              uploadTimedOut = true;
              unawaited(uploadTask.cancel());
              sink.close();
            },
          )
          .listen((snapshot) {
            final totalBytes = snapshot.totalBytes;
            final rawProgress = totalBytes > 0
                ? snapshot.bytesTransferred / totalBytes
                : (snapshot.state == TaskState.success ? 1.0 : 0.0);
            onProgress?.call(clampDouble(rawProgress, 0, 1));
          });
      final snapshot = await uploadTask;
      onProgress?.call(1);
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e, stack) {
      AppLogger.error('Firebase upload error: $path', e, stack);
      if (uploadTimedOut || e.code == 'canceled') {
        throw StoryRepositoryException.uploadFailed(
          contentType.startsWith('video/')
              ? 'O envio do video ficou sem progresso. Tente novamente em uma rede melhor ou com um video menor.'
              : 'O envio do arquivo ficou sem progresso. Tente novamente.',
        );
      }
      throw StoryRepositoryException.uploadFailed(
        'Erro ao enviar arquivo: ${e.message ?? 'tente novamente'}',
      );
    } on StoryRepositoryException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Upload error: $path', e, stack);
      throw StoryRepositoryException.uploadFailed();
    } finally {
      await progressSubscription?.cancel();
    }
  }

  void _emitProgress(
    StoryPublishProgressCallback? onProgress,
    double value,
    String label,
  ) {
    onProgress?.call(
      StoryPublishProgress(value: clampDouble(value, 0, 1), label: label),
    );
  }

  double _progressBetween(
    double progress, {
    required double start,
    required double end,
  }) {
    final normalizedProgress = clampDouble(progress, 0, 1);
    return start + ((end - start) * normalizedProgress);
  }

  @visibleForTesting
  static StoryImageUploadTarget resolveImageUploadTarget({
    required File file,
    required String basePathWithoutExtension,
  }) {
    final extension = path.extension(file.path).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.jpg',
        contentType: 'image/jpeg',
      ),
      '.png' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.png',
        contentType: 'image/png',
      ),
      '.gif' => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.gif',
        contentType: 'image/gif',
      ),
      _ => StoryImageUploadTarget(
        path: '$basePathWithoutExtension.webp',
        contentType: 'image/webp',
      ),
    };
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
            'Estudio';
      case 'contratante':
        return (userData['contratante']?['nomeExibicao'] as String?) ??
            (userData['nome'] as String?) ??
            'Contratante';
      default:
        return (userData['nome'] as String?) ?? 'Usuario';
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

class _StoryMediaUploadResult {
  const _StoryMediaUploadResult({
    required this.mediaUrl,
    required this.thumbnailUrl,
  });

  final String mediaUrl;
  final String? thumbnailUrl;
}

class StoryImageUploadTarget {
  const StoryImageUploadTarget({required this.path, required this.contentType});

  final String path;
  final String contentType;
}
