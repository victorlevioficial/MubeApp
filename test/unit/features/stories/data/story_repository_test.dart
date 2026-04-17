import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/stories/data/story_repository.dart';
import 'package:mube/src/features/stories/domain/story_item.dart';
import 'package:mube/src/features/stories/domain/story_repository_exception.dart';
import 'package:mube/src/features/stories/domain/story_view_receipt.dart';

import '../../../../helpers/firebase_mocks.dart';
import '../../../../helpers/test_fakes.dart';

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late FakeFavoriteRepository fakeFavoriteRepository;
  late StoryRepository repository;
  late DateTime baseCreatedAt;
  late DateTime baseExpiresAt;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser(uid: 'current-user', email: 'current@example.com');
    fakeFavoriteRepository = FakeFavoriteRepository();

    when(mockAuth.currentUser).thenReturn(mockUser);

    repository = StoryRepository(
      fakeFirestore,
      MockFirebaseStorage(),
      _FakeFirebaseFunctions(),
      mockAuth,
      fakeFavoriteRepository,
    );

    final now = DateTime.now();
    baseCreatedAt = now.subtract(const Duration(hours: 6));
    baseExpiresAt = baseCreatedAt.add(const Duration(hours: 24));
  });

  StoryItem buildStory({
    required String id,
    required String ownerUid,
    required String ownerName,
    required DateTime createdAt,
    required DateTime expiresAt,
    StoryMediaType mediaType = StoryMediaType.image,
    StoryStatus status = StoryStatus.active,
    String? ownerPhoto,
    String? ownerPhotoPreview,
    bool withCaption = false,
  }) {
    return StoryItem(
      id: id,
      ownerUid: ownerUid,
      ownerName: ownerName,
      ownerPhoto: ownerPhoto,
      ownerPhotoPreview: ownerPhotoPreview,
      ownerType: 'profissional',
      mediaType: mediaType,
      mediaUrl: 'https://example.com/$id',
      thumbnailUrl: mediaType == StoryMediaType.video
          ? 'https://example.com/$id-thumb'
          : null,
      caption: withCaption ? 'Caption for $id' : null,
      createdAt: createdAt,
      expiresAt: expiresAt,
      publishedDayKey: '2026-03-10',
      durationSeconds: mediaType == StoryMediaType.video ? 12 : null,
      aspectRatio: mediaType == StoryMediaType.video ? 9 / 16 : null,
      viewersCount: 0,
      status: status,
    );
  }

  Future<void> seedStory(StoryItem story) async {
    await fakeFirestore.collection('stories').doc(story.id).set(story.toJson());
  }

  Future<void> seedUser({
    required String uid,
    List<String> blockedUsers = const [],
    bool hasActiveStory = false,
  }) async {
    await fakeFirestore.collection('users').doc(uid).set({
      'uid': uid,
      'nome': uid,
      'cadastro_status': 'concluido',
      'status': 'ativo',
      'blocked_users': blockedUsers,
      'story_state': {
        'has_active_story': hasActiveStory,
        'active_story_count': hasActiveStory ? 1 : 0,
      },
    }, SetOptions(merge: true));
  }

  group('StoryRepository', () {
    test('resolveImageUploadTarget preserves jpeg fallback metadata', () {
      final target = StoryRepository.resolveImageUploadTarget(
        file: File('story_photo.jpg'),
        basePathWithoutExtension: 'stories_images/user/story/full',
      );

      expect(target.path, 'stories_images/user/story/full.jpg');
      expect(target.contentType, 'image/jpeg');
    });

    test('resolveImageUploadTarget keeps webp uploads as webp', () {
      final target = StoryRepository.resolveImageUploadTarget(
        file: File('story_photo.webp'),
        basePathWithoutExtension: 'stories_images/user/story/full',
      );

      expect(target.path, 'stories_images/user/story/full.webp');
      expect(target.contentType, 'image/webp');
    });

    test(
      'loadTray orders the current user first, then favorites, then other authors',
      () async {
        fakeFavoriteRepository.favorites = {'favorite-user'};
        await seedUser(uid: 'current-user', hasActiveStory: true);
        await seedUser(uid: 'favorite-user', hasActiveStory: true);
        await seedUser(uid: 'other-user', hasActiveStory: true);

        await seedStory(
          buildStory(
            id: 'story-current',
            ownerUid: 'current-user',
            ownerName: 'Current User',
            createdAt: baseCreatedAt,
            expiresAt: baseExpiresAt,
          ),
        );
        await seedStory(
          buildStory(
            id: 'story-favorite',
            ownerUid: 'favorite-user',
            ownerName: 'Favorite User',
            createdAt: baseCreatedAt.add(const Duration(hours: 1)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 1)),
          ),
        );
        await seedStory(
          buildStory(
            id: 'story-other',
            ownerUid: 'other-user',
            ownerName: 'Other User',
            createdAt: baseCreatedAt.add(const Duration(hours: 2)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 2)),
          ),
        );

        final bundles = await repository.loadTray(
          discoveryOwnerIds: const ['other-user'],
        );

        expect(bundles.map((bundle) => bundle.ownerUid), [
          'current-user',
          'favorite-user',
          'other-user',
        ]);
        expect(bundles.first.isCurrentUser, isTrue);
        expect(bundles[1].isFavorite, isTrue);
        expect(bundles[2].isFavorite, isFalse);
      },
    );

    test(
      'loadTray groups multiple stories from the same owner in chronological order',
      () async {
        await seedUser(uid: 'owner-user', hasActiveStory: true);
        await seedStory(
          buildStory(
            id: 'story-owner-older',
            ownerUid: 'owner-user',
            ownerName: 'Owner User',
            createdAt: baseCreatedAt,
            expiresAt: baseExpiresAt,
          ),
        );
        await seedStory(
          buildStory(
            id: 'story-owner-newer',
            ownerUid: 'owner-user',
            ownerName: 'Owner User',
            createdAt: baseCreatedAt.add(const Duration(hours: 1)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 1)),
          ),
        );

        final bundles = await repository.loadTray(
          discoveryOwnerIds: const ['owner-user'],
        );

        expect(bundles, hasLength(1));
        expect(bundles.single.ownerUid, 'owner-user');
        expect(bundles.single.stories.map((story) => story.id), [
          'story-owner-older',
          'story-owner-newer',
        ]);
        expect(bundles.single.latestStory?.id, 'story-owner-newer');
        expect(bundles.single.hasUnseen, isTrue);
      },
    );

    test(
      'loadTray includes active public authors outside the discovery surface',
      () async {
        await seedUser(uid: 'current-user');
        await seedUser(uid: 'favorite-user', hasActiveStory: true);
        await seedUser(uid: 'discovered-user', hasActiveStory: true);
        await seedUser(uid: 'outside-user', hasActiveStory: true);
        fakeFavoriteRepository.favorites = {'favorite-user'};

        await seedStory(
          buildStory(
            id: 'story-favorite',
            ownerUid: 'favorite-user',
            ownerName: 'Favorite User',
            createdAt: baseCreatedAt,
            expiresAt: baseExpiresAt,
          ),
        );
        await seedStory(
          buildStory(
            id: 'story-discovered',
            ownerUid: 'discovered-user',
            ownerName: 'Discovered User',
            createdAt: baseCreatedAt.add(const Duration(hours: 1)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 1)),
          ),
        );
        await seedStory(
          buildStory(
            id: 'story-outside',
            ownerUid: 'outside-user',
            ownerName: 'Outside User',
            createdAt: baseCreatedAt.add(const Duration(hours: 2)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 2)),
          ),
        );

        final bundles = await repository.loadTray(
          discoveryOwnerIds: const ['discovered-user'],
        );

        expect(bundles.map((bundle) => bundle.ownerUid), [
          'favorite-user',
          'outside-user',
          'discovered-user',
        ]);
      },
    );

    test(
      'loadTray keeps active public authors even when profile filters would hide them',
      () async {
        await seedUser(uid: 'current-user');
        await fakeFirestore.collection('users').doc('outside-user').set({
          'uid': 'outside-user',
          'nome': 'outside-user',
          'cadastro_status': 'pendente',
          'status': 'ativo',
          'blocked_users': const <String>[],
          'story_state': {'has_active_story': false, 'active_story_count': 0},
        }, SetOptions(merge: true));

        await seedStory(
          buildStory(
            id: 'story-outside',
            ownerUid: 'outside-user',
            ownerName: 'Outside User',
            createdAt: baseCreatedAt.add(const Duration(hours: 2)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 2)),
          ),
        );

        final bundles = await repository.loadTray();

        expect(bundles.map((bundle) => bundle.ownerUid), ['outside-user']);
      },
    );

    test(
      'loadTray keeps active public authors even when owner profile document is missing',
      () async {
        await seedUser(uid: 'current-user');
        await seedStory(
          buildStory(
            id: 'story-missing-owner-doc',
            ownerUid: 'missing-owner-doc',
            ownerName: 'Missing Owner',
            createdAt: baseCreatedAt.add(const Duration(hours: 2)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 2)),
          ),
        );

        final bundles = await repository.loadTray();

        expect(bundles.map((bundle) => bundle.ownerUid), ['missing-owner-doc']);
      },
    );

    test('loadTray filters owners who blocked the current viewer', () async {
      await seedUser(uid: 'current-user');
      await seedUser(uid: 'visible-user', hasActiveStory: true);
      await seedUser(
        uid: 'blocked-by-owner',
        blockedUsers: const ['current-user'],
        hasActiveStory: true,
      );

      await seedStory(
        buildStory(
          id: 'story-visible',
          ownerUid: 'visible-user',
          ownerName: 'Visible User',
          createdAt: baseCreatedAt,
          expiresAt: baseExpiresAt,
        ),
      );
      await seedStory(
        buildStory(
          id: 'story-blocked',
          ownerUid: 'blocked-by-owner',
          ownerName: 'Blocked Owner',
          createdAt: baseCreatedAt.add(const Duration(hours: 1)),
          expiresAt: baseExpiresAt.add(const Duration(hours: 1)),
        ),
      );

      final bundles = await repository.loadTray(
        discoveryOwnerIds: const ['visible-user', 'blocked-by-owner'],
      );

      expect(bundles.map((bundle) => bundle.ownerUid), ['visible-user']);
    });

    test('loadViewerRouteArgs resolves a story bundle by story id', () async {
      await seedUser(uid: 'current-user');
      await seedUser(uid: 'owner-user', hasActiveStory: true);

      await seedStory(
        buildStory(
          id: 'story-older',
          ownerUid: 'owner-user',
          ownerName: 'Owner User',
          createdAt: baseCreatedAt,
          expiresAt: baseExpiresAt,
        ),
      );
      await seedStory(
        buildStory(
          id: 'story-target',
          ownerUid: 'owner-user',
          ownerName: 'Owner User',
          createdAt: baseCreatedAt.add(const Duration(hours: 1)),
          expiresAt: baseExpiresAt.add(const Duration(hours: 1)),
        ),
      );

      final args = await repository.loadViewerRouteArgs('story-target');

      expect(args.initialOwnerUid, 'owner-user');
      expect(args.initialStoryId, 'story-target');
      expect(args.bundles, hasLength(1));
      expect(args.bundles.single.stories.map((story) => story.id), [
        'story-older',
        'story-target',
      ]);
    });

    test(
      'loadViewerRouteArgs throws a typed unavailable error for missing stories',
      () async {
        expect(
          repository.loadViewerRouteArgs('missing-story'),
          throwsA(
            isA<StoryRepositoryException>().having(
              (error) => error.code,
              'code',
              StoryRepositoryExceptionCode.storyUnavailable,
            ),
          ),
        );
      },
    );

    test(
      'markStoryViewed stores viewer metadata for another user story',
      () async {
        await fakeFirestore.collection('users').doc('current-user').set({
          'tipo_perfil': 'profissional',
          'nome': 'Viewer Name',
          'foto_thumb': 'https://example.com/viewer-thumb.jpg',
          'profissional': {'nomeArtistico': 'DJ Viewer'},
        });

        final story = buildStory(
          id: 'story-1',
          ownerUid: 'owner-user',
          ownerName: 'Owner User',
          createdAt: baseCreatedAt,
          expiresAt: baseExpiresAt,
        );

        await repository.markStoryViewed(story);

        final viewDoc = await fakeFirestore
            .collection('stories')
            .doc('story-1')
            .collection('views')
            .doc('current-user')
            .get();

        expect(viewDoc.exists, isTrue);
        expect(viewDoc.data(), containsPair('viewer_uid', 'current-user'));
        expect(viewDoc.data(), containsPair('viewer_name', 'DJ Viewer'));
        expect(
          viewDoc.data(),
          containsPair('viewer_photo', 'https://example.com/viewer-thumb.jpg'),
        );
      },
    );

    test('markStoryViewed ignores the current user own story', () async {
      final ownStory = buildStory(
        id: 'story-own',
        ownerUid: 'current-user',
        ownerName: 'Current User',
        createdAt: baseCreatedAt,
        expiresAt: baseExpiresAt,
      );

      await repository.markStoryViewed(ownStory);

      final viewDoc = await fakeFirestore
          .collection('stories')
          .doc('story-own')
          .collection('views')
          .doc('current-user')
          .get();

      expect(viewDoc.exists, isFalse);
    });

    test(
      'loadCurrentUserProcessingStories returns only active processing docs',
      () async {
        await seedUser(uid: 'current-user', hasActiveStory: true);
        await seedStory(
          buildStory(
            id: 'story-processing-newer',
            ownerUid: 'current-user',
            ownerName: 'Current User',
            createdAt: baseCreatedAt.add(const Duration(hours: 3)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 3)),
            mediaType: StoryMediaType.video,
            status: StoryStatus.processing,
          ),
        );
        await seedStory(
          buildStory(
            id: 'story-processing-older',
            ownerUid: 'current-user',
            ownerName: 'Current User',
            createdAt: baseCreatedAt.add(const Duration(hours: 2)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 2)),
            mediaType: StoryMediaType.video,
            status: StoryStatus.processing,
          ),
        );
        await seedStory(
          buildStory(
            id: 'story-active',
            ownerUid: 'current-user',
            ownerName: 'Current User',
            createdAt: baseCreatedAt.add(const Duration(hours: 1)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 1)),
          ),
        );
        await seedStory(
          buildStory(
            id: 'story-other-user',
            ownerUid: 'other-user',
            ownerName: 'Other User',
            createdAt: baseCreatedAt.add(const Duration(hours: 4)),
            expiresAt: baseExpiresAt.add(const Duration(hours: 4)),
            mediaType: StoryMediaType.video,
            status: StoryStatus.processing,
          ),
        );

        final stories = await repository.loadCurrentUserProcessingStories();

        expect(stories.map((story) => story.id), [
          'story-processing-newer',
          'story-processing-older',
        ]);
      },
    );

    test('loadViewers returns the newest viewers first', () async {
      await fakeFirestore
          .collection('stories')
          .doc('story-1')
          .collection('views')
          .doc('viewer-older')
          .set({
            'viewer_uid': 'viewer-older',
            'viewer_name': 'Older Viewer',
            'viewer_photo': null,
            'viewed_at': Timestamp.fromDate(DateTime(2026, 3, 10, 9)),
          });
      await fakeFirestore
          .collection('stories')
          .doc('story-1')
          .collection('views')
          .doc('viewer-newer')
          .set({
            'viewer_uid': 'viewer-newer',
            'viewer_name': 'Newer Viewer',
            'viewer_photo': 'https://example.com/newer.jpg',
            'viewed_at': Timestamp.fromDate(DateTime(2026, 3, 10, 10)),
          });

      final viewers = await repository.loadViewers('story-1');

      expect(viewers, hasLength(2));
      expect(viewers.map((StoryViewReceipt receipt) => receipt.viewerUid), [
        'viewer-newer',
        'viewer-older',
      ]);
      expect(viewers.first.viewerPhoto, 'https://example.com/newer.jpg');
    });
  });
}
