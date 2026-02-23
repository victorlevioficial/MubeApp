import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/feedback/empty_state_widget.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/feed/presentation/feed_screen.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_skeleton.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../helpers/test_fakes.dart';

void main() {
  late FakeFeedImagePrecacheService fakePrecacheService;
  late FakeFavoriteRepository fakeFavoriteRepository;
  late FakeFeedRepository fakeFeedRepository;
  late FakeAuthRepository fakeAuthRepository;
  late FakeFirebaseUser fakeUser;

  setUp(() {
    fakePrecacheService = FakeFeedImagePrecacheService();
    fakeFavoriteRepository = FakeFavoriteRepository();
    fakeFeedRepository = FakeFeedRepository();
    fakeAuthRepository = FakeAuthRepository();
    fakeUser = FakeFirebaseUser();

    fakeAuthRepository.appUser = const AppUser(
      uid: 'test-user-id',
      nome: 'Test User',
      email: 'test@example.com',
      location: {'lat': -23.5505, 'lng': -46.6333},
    );

    fakeAuthRepository.emitUser(fakeUser);
  });

  Widget createSubject({
    AsyncValue<AppUser?>? userState,
    List<dynamic> additionalOverrides = const [],
  }) {
    const defaultUser = AppUser(
      uid: 'test-user-id',
      nome: 'Test User',
      email: 'test@example.com',
      location: {'lat': -23.5505, 'lng': -46.6333},
    );

    return ProviderScope(
      overrides: [
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepository),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        authStateChangesProvider.overrideWith((ref) => Stream.value(fakeUser)),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(userState?.value ?? defaultUser),
        ),
        feedImagePrecacheServiceProvider.overrideWithValue(fakePrecacheService),
      ],
      child: const MaterialApp(home: FeedScreen()),
    );
  }

  group('FeedScreen', () {
    testWidgets('shows skeleton when loading', (tester) async {
      // Setup the completer to hang the repository request
      fakeFeedRepository.requestCompleter = Completer<void>();

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        // First pump renders initial frame
        await tester.pump();
        // Second pump processes addPostFrameCallback where loadAllData is called
        await tester.pump();
      });

      expect(find.byType(FeedScreenSkeleton), findsOneWidget);

      // Clean up the completer so the test can finish without unresolved promises
      fakeFeedRepository.requestCompleter!.complete();
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('shows error state when feed fails', (tester) async {
      fakeFeedRepository.throwError = true;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        // Trigger loadAllData
        await tester.pump();
        // Allow error propagation
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      expect(find.textContaining('Erro'), findsOneWidget);
    });

    testWidgets('shows empty state when no users found', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject());
        // Trigger loadAllData
        await tester.pump();
        // Allow data loading to complete (fake repo returns empty list by default)
        await tester.pumpAndSettle(const Duration(seconds: 2));
      });

      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });
  });
}
