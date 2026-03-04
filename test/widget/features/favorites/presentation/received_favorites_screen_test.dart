import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/favorites/presentation/received_favorites_screen.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeFavoriteRepository fakeFavoriteRepository;
  late FakeFeedRepository fakeFeedRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeFavoriteRepository = FakeFavoriteRepository();
    fakeFeedRepository = FakeFeedRepository();

    fakeAuthRepository.emitUser(
      FakeFirebaseUser(uid: 'current-user', email: 'current@test.com'),
    );
  });

  Widget createSubject() {
    final user = TestData.user(uid: 'current-user');

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepository),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepository),
      ],
      child: const MaterialApp(home: ReceivedFavoritesScreen()),
    );
  }

  group('ReceivedFavoritesScreen', () {
    testWidgets('shows empty state when no one favorited the user', (
      tester,
    ) async {
      fakeFavoriteRepository.receivedFavorites = [];

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Ninguém favoritou você ainda'), findsOneWidget);
    });

    testWidgets('renders users who favorited the current user', (tester) async {
      fakeFavoriteRepository.receivedFavorites = ['fan-2', 'fan-1'];
      fakeFeedRepository.professionals = [
        const FeedItem(
          uid: 'fan-1',
          nome: 'Fan 1',
          nomeArtistico: 'Fan 1',
          tipoPerfil: 'profissional',
          categoria: 'Profissional',
        ),
        const FeedItem(
          uid: 'fan-2',
          nome: 'Fan 2',
          nomeArtistico: 'Fan 2',
          tipoPerfil: 'profissional',
          categoria: 'Profissional',
        ),
      ];

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Fan 1'), findsOneWidget);
      expect(find.text('Fan 2'), findsOneWidget);

      final firstTile = tester.widget<ListTile>(find.byType(ListTile).first);
      final firstTitle = firstTile.title as Text;
      expect(firstTitle.data, 'Fan 2');
    });
  });
}
