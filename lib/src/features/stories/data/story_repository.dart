import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../features/favorites/data/favorite_repository.dart';
import '../../../features/storage/domain/image_compressor.dart';
import '../../../utils/app_logger.dart';
import '../domain/story_constants.dart';
import '../domain/story_item.dart';
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

class StoryRepository {
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
      throw Exception('Usuario nao autenticado');
    }
    return currentUser.uid;
  }

  Future<List<StoryTrayBundle>> loadTray({
    Iterable<String> discoveryOwnerIds = const <String>[],
  }) async {
    final uid = _uid;
    final results = await Future.wait([
      _favoriteRepository.loadFavorites(),
      _loadSeenAuthorTimestamps(uid),
      _loadBlockedIds(uid),
    ]);

    final favoriteIds = results[0] as Set<String>;
    final seenAuthors = results[1] as Map<String, DateTime>;
    final blockedIds = results[2] as Set<String>;

    final candidateOwnerIds =
        <String>{uid, ...favoriteIds, ...discoveryOwnerIds}..removeWhere(
          (ownerUid) =>
              ownerUid.trim().isEmpty ||
              (blockedIds.contains(ownerUid) && ownerUid != uid),
        );

    final ownerIdsToQuery = await _resolveOwnersToQuery(
      candidateOwnerIds,
      currentUserId: uid,
      blockedIds: blockedIds,
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
      throw Exception('Story nao encontrado.');
    }

    final story = StoryItem.fromJson(
      storyDoc.data() ?? <String, dynamic>{},
      id: storyDoc.id,
    );
    if (story.ownerUid.isEmpty) {
      throw Exception('Story nao encontrado.');
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
      throw Exception('Story nao encontrado.');
    }
    if (!story.isActive && !isCurrentUserStory) {
      throw Exception('Story nao encontrado.');
    }

    final ownerIdsToQuery = await _resolveOwnersToQuery(
      <String>{story.ownerUid},
      currentUserId: uid,
      blockedIds: blockedIds,
    );
    if (ownerIdsToQuery.isEmpty) {
      throw Exception('Story nao encontrado.');
    }

    final bundles = await _loadBundlesForOwners(
      ownerIds: ownerIdsToQuery,
      favoriteIds: favoriteIds,
      seenAuthors: seenAuthors,
      blockedIds: blockedIds,
      currentUid: uid,
    );

    if (bundles.isEmpty) {
      throw Exception('Story nao encontrado.');
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
  }) async {
    final uid = _uid;
    final storyId = const Uuid().v4();
    final upload = await _uploadStoryMedia(
      userId: uid,
      storyId: storyId,
      media: media,
    );

    final callable = _functions.httpsCallable('publishStory');
    await callable.call({
      'storyId': storyId,
      'mediaType': media.mediaType.name,
      'mediaUrl': upload.mediaUrl,
      'thumbnailUrl': upload.thumbnailUrl,
      'caption': caption?.trim(),
      'durationSeconds': media.durationSeconds,
      'aspectRatio': media.aspectRatio,
    });
  }

  Future<void> deleteStory(StoryItem story) async {
    final callable = _functions.httpsCallable('deleteStory');
    await callable.call({'storyId': story.id});
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

  Future<List<StoryViewReceipt>> loadViewers(String storyId) async {
    final snapshot = await _firestore
        .collection(StoryConstants.storiesCollection)
        .doc(storyId)
        .collection(StoryConstants.viewsSubcollection)
        .orderBy('viewed_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => StoryViewReceipt.fromJson(doc.data(), id: doc.id))
        .toList(growable: false);
  }

  Future<Set<String>> _resolveOwnersToQuery(
    Set<String> candidateOwnerIds, {
    required String currentUserId,
    required Set<String> blockedIds,
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
      if (ownerUid == currentUserId) {
        ownerIdsToQuery.add(ownerUid);
        continue;
      }
      if (blockedIds.contains(ownerUid)) {
        continue;
      }

      final ownerData = docsById[ownerUid];
      if (ownerData == null) {
        continue;
      }
      if (_readStringSet(ownerData['blocked_users']).contains(currentUserId)) {
        continue;
      }

      final cadastroStatus = ownerData['cadastro_status'] as String?;
      if (cadastroStatus != null && cadastroStatus != 'concluido') {
        continue;
      }

      final accountStatus = ownerData['status'] as String? ?? 'ativo';
      if (accountStatus != 'ativo') {
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
    final storySnapshots = await Future.wait(
      ownerIds.map(
        (ownerUid) => _firestore
            .collection(StoryConstants.storiesCollection)
            .where('owner_uid', isEqualTo: ownerUid)
            .where('status', isEqualTo: StoryConstants.statusActive)
            .where('expires_at', isGreaterThan: now)
            .orderBy('expires_at')
            .get(),
      ),
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadUsersByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return const [];
    }

    const batchSize = 30;
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < ids.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, ids.length);
      final batchIds = ids.sublist(i, end);
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();
      docs.addAll(snapshot.docs);
    }

    return docs;
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
  }) async {
    if (media.mediaType == StoryMediaType.image) {
      return _uploadImageStory(userId: userId, storyId: storyId, media: media);
    }

    return _uploadVideoStory(userId: userId, storyId: storyId, media: media);
  }

  Future<_StoryMediaUploadResult> _uploadImageStory({
    required String userId,
    required String storyId,
    required StoryUploadMedia media,
  }) async {
    final fullFile = await ImageCompressor.compressGalleryPhoto(
      media.file,
      format: ImageFormat.webp,
    );
    final thumbFile = await ImageCompressor.compressThumbnail(media.file);

    final fullUrl = await _uploadFile(
      file: fullFile,
      path: 'stories_images/$userId/$storyId/full.webp',
      contentType: 'image/webp',
    );
    final thumbUrl = await _uploadFile(
      file: thumbFile,
      path: 'stories_images/$userId/$storyId/thumb.webp',
      contentType: 'image/webp',
    );

    return _StoryMediaUploadResult(mediaUrl: fullUrl, thumbnailUrl: thumbUrl);
  }

  Future<_StoryMediaUploadResult> _uploadVideoStory({
    required String userId,
    required String storyId,
    required StoryUploadMedia media,
  }) async {
    final thumbFile = media.thumbnailFile == null
        ? null
        : await ImageCompressor.compressThumbnail(media.thumbnailFile!);

    final videoUrl = await _uploadFile(
      file: media.file,
      path: 'stories_videos_source/$userId/$storyId/source.mp4',
      contentType: 'video/mp4',
    );
    final thumbUrl = thumbFile == null
        ? null
        : await _uploadFile(
            file: thumbFile,
            path: 'stories_videos_thumbs/$userId/$storyId/thumb.webp',
            contentType: 'image/webp',
          );

    return _StoryMediaUploadResult(mediaUrl: videoUrl, thumbnailUrl: thumbUrl);
  }

  Future<String> _uploadFile({
    required File file,
    required String path,
    required String contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final snapshot = await ref.putFile(file, metadata);
    return snapshot.ref.getDownloadURL();
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
