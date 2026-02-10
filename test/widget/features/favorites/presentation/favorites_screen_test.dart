import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/favorites/domain/favorite_controller.dart';
import 'package:mube/src/features/favorites/presentation/favorites_screen.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeFavoriteRepository fakeFavoriteRepo;
  late FakeFeedRepository fakeFeedRepo;
  late FakeFeedImagePrecacheService fakePrecacheService;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeFavoriteRepo = FakeFavoriteRepository();
    fakeFeedRepo = FakeFeedRepository();
    fakePrecacheService = FakeFeedImagePrecacheService();
  });

  Widget createSubject({Set<String> favorites = const {'fav-1'}}) {
    final user = TestData.user(uid: 'user-1');
    fakeAuthRepo.appUser = user;
    fakeAuthRepo.emitUser(FakeFirebaseUser(uid: 'user-1'));

    final feedItem = TestData.feedItem(id: 'fav-1', nome: 'Favorite User');
    fakeFavoriteRepo.favorites = favorites;
    fakeFeedRepo.nearbyUsers = [feedItem];

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/user/:id',
          builder: (context, state) =>
              Scaffold(body: Text('User Profile: ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepo),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
        feedImagePrecacheServiceProvider.overrideWithValue(fakePrecacheService),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('FavoritesScreen', () {
    testWidgets('renders correctly with app bar', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Meus Favoritos'), findsOneWidget);
      expect(find.byType(FavoritesScreen), findsOneWidget);
    });

    testWidgets('renders filter bar with all options', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Músicos'), findsOneWidget);
      expect(find.text('Bandas'), findsOneWidget);
      expect(find.text('Estúdios'), findsOneWidget);
    });

    testWidgets('shows empty state when no favorites', (tester) async {
      await tester.pumpWidget(createSubject(favorites: {}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Você ainda não tem favoritos.'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('renders favorite items in list', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Favorite User'), findsOneWidget);
    });

    testWidgets('navigates to profile when item tapped', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Favorite User'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('User Profile: fav-1'), findsOneWidget);
    });

    testWidgets('shows error state on load failure', (tester) async {
      fakeFeedRepo.throwError = true;

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Erro ao carregar favoritos'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}
