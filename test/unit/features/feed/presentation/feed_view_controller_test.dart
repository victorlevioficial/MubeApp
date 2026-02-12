import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/feed_section.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';
import 'package:mube/src/features/feed/presentation/feed_view_controller.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeFeedRepository fakeFeedRepo;
  late ProviderContainer container;

  /// Creates a test FeedItem with the correct field names.
  FeedItem createItem(String id) =>
      FeedItem(uid: id, nome: 'User $id', tipoPerfil: 'profissional');

  FeedItem createTechnicianItem(String id) => FeedItem(
    uid: id,
    nome: 'Tech $id',
    tipoPerfil: 'profissional',
    subCategories: const ['crew'],
  );

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeFeedRepo = FakeFeedRepository();

    // Authenticated user with default location from TestData.
    final firebaseUser = FakeFirebaseUser(uid: 'u1', email: 'a@b.com');
    fakeAuthRepo.emitUser(firebaseUser);
    fakeAuthRepo.appUser = TestData.user(uid: 'u1');

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  /// Waits for the user profile provider to resolve.
  Future<void> waitForUser() async {
    final c = Completer<void>();
    final sub = container.listen(currentUserProfileProvider, (_, next) {
      if (next.hasValue && next.value != null && !c.isCompleted) {
        c.complete();
      }
    }, fireImmediately: true);
    await c.future.timeout(const Duration(seconds: 2));
    sub.close();
  }

  group('FeedListController', () {
    group('build (initial load)', () {
      test('returns empty state when user is null', () async {
        fakeAuthRepo.emitUser(null);
        fakeAuthRepo.appUser = null;

        final noUserContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
          ],
        );
        addTearDown(noUserContainer.dispose);

        final provider = feedListControllerProvider(FeedSectionType.artists);
        await noUserContainer.read(provider.future);
        final state = noUserContainer.read(provider).value!;

        expect(state.items, isEmpty);
        expect(state.hasMore, isFalse);
      });

      test(
        'loads technicians section with location (pure crew only)',
        () async {
          final items = [
            createTechnicianItem('tech-1'),
            createItem('artist-1'),
            createTechnicianItem('tech-2'),
          ];
          fakeFeedRepo.professionals = items;
          await waitForUser();

          final provider = feedListControllerProvider(
            FeedSectionType.technicians,
          );
          await container.read(provider.future);
          final state = container.read(provider).value!;

          expect(state.items.length, 2);
          expect(
            state.items.every((item) => item.subCategories.contains('crew')),
            isTrue,
          );
          expect(state.hasMore, isFalse);
        },
      );

      test('loads nearby section with empty results', () async {
        fakeFeedRepo.nearbyUsers = [];
        await waitForUser();

        final provider = feedListControllerProvider(FeedSectionType.nearby);
        await container.read(provider.future);
        final state = container.read(provider).value!;

        expect(state.items, isEmpty);
        expect(state.hasMore, isFalse);
      });

      test('loads bands section with location', () async {
        final items = List.generate(3, (i) => createItem('band-$i'));
        fakeFeedRepo.bands = items;
        await waitForUser();

        final provider = feedListControllerProvider(FeedSectionType.bands);
        await container.read(provider.future);
        final state = container.read(provider).value!;

        expect(state.items.length, 3);
      });

      test('loads with classic fallback when no location', () async {
        // User without location.
        fakeAuthRepo.appUser = TestData.user(uid: 'u1', location: {});

        final noLocContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
          ],
        );
        addTearDown(noLocContainer.dispose);

        final bandItems = [createItem('b1'), createItem('b2')];
        fakeFeedRepo.bands = bandItems;
        fakeFeedRepo.mainFeedResponse = PaginatedFeedResponse(
          items: bandItems,
          hasMore: false,
          lastDocument: null,
        );

        // Wait for user profile in the new container.
        final c = Completer<void>();
        final sub = noLocContainer.listen(currentUserProfileProvider, (
          _,
          next,
        ) {
          if (next.hasValue && next.value != null && !c.isCompleted) {
            c.complete();
          }
        }, fireImmediately: true);
        await c.future.timeout(const Duration(seconds: 2));
        sub.close();

        final provider = feedListControllerProvider(FeedSectionType.bands);
        await noLocContainer.read(provider.future);
        final state = noLocContainer.read(provider).value!;

        expect(state.items.length, 2);
      });

      test('nearby without location returns empty', () async {
        fakeAuthRepo.appUser = TestData.user(uid: 'u1', location: {});

        final noLocContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
          ],
        );
        addTearDown(noLocContainer.dispose);

        final c = Completer<void>();
        final sub = noLocContainer.listen(currentUserProfileProvider, (
          _,
          next,
        ) {
          if (next.hasValue && next.value != null && !c.isCompleted) {
            c.complete();
          }
        }, fireImmediately: true);
        await c.future.timeout(const Duration(seconds: 2));
        sub.close();

        final provider = feedListControllerProvider(FeedSectionType.nearby);
        await noLocContainer.read(provider.future);
        final state = noLocContainer.read(provider).value!;

        expect(state.items, isEmpty);
        expect(state.hasMore, isFalse);
      });
    });

    group('loadMore', () {
      test('local pagination with allSortedItems (technicians)', () async {
        // Create 25 items — initial load shows 20, loadMore shows rest.
        final items = List.generate(25, (i) => createTechnicianItem('item-$i'));
        fakeFeedRepo.professionals = items;
        await waitForUser();

        final provider = feedListControllerProvider(
          FeedSectionType.technicians,
        );
        await container.read(provider.future);

        var state = container.read(provider).value!;
        expect(state.items.length, 20);
        expect(state.hasMore, isTrue);

        // Load more.
        await container.read(provider.notifier).loadMore();

        state = container.read(provider).value!;
        expect(state.items.length, 25);
        expect(state.hasMore, isFalse);
      });

      test('does nothing when already loading', () async {
        final items = List.generate(25, (i) => createTechnicianItem('item-$i'));
        fakeFeedRepo.professionals = items;
        await waitForUser();

        final provider = feedListControllerProvider(
          FeedSectionType.technicians,
        );
        await container.read(provider.future);

        // Trigger two concurrent loadMore calls.
        final f1 = container.read(provider.notifier).loadMore();
        final f2 = container.read(provider.notifier).loadMore();
        await Future.wait([f1, f2]);

        final state = container.read(provider).value!;
        // Should only have loaded one extra page, total 25.
        expect(state.items.length, 25);
      });

      test('does nothing when hasMore is false', () async {
        final items = List.generate(5, (i) => createTechnicianItem('item-$i'));
        fakeFeedRepo.professionals = items;
        await waitForUser();

        final provider = feedListControllerProvider(
          FeedSectionType.technicians,
        );
        await container.read(provider.future);

        var state = container.read(provider).value!;
        expect(state.hasMore, isFalse);

        await container.read(provider.notifier).loadMore();

        state = container.read(provider).value!;
        expect(state.items.length, 5);
      });
    });
  });
}
