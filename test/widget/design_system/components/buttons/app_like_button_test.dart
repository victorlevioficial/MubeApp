import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:like_button/like_button.dart';
import 'package:mube/src/design_system/components/buttons/app_like_button.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/favorites/domain/favorite_controller.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

class _StubFeedController extends FeedController {
  @override
  FutureOr<FeedState> build() => const FeedState();

  @override
  void updateLikeCount(String targetId, {required bool isLiked}) {
    // no-op for button widget tests
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeFavoriteRepository fakeFavoriteRepo;
  late ProviderContainer container;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeFavoriteRepo = FakeFavoriteRepository();

    fakeAuthRepo.emitUser(FakeFirebaseUser(uid: 'u1'));
    fakeAuthRepo.appUser = TestData.user(uid: 'u1');

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepo),
        feedControllerProvider.overrideWith(_StubFeedController.new),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<void> pumpButton(
    WidgetTester tester, {
    required String targetId,
    required int initialCount,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLikeButton(
                targetId: targetId,
                initialCount: initialCount,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppLikeButton', () {
    testWidgets(
      'keeps optimistic count across screen recreation with stale initialCount',
      (tester) async {
        // Home screen: server says 0.
        await pumpButton(tester, targetId: 'target-1', initialCount: 0);

        // User likes on Home -> optimistic count becomes 1.
        await tester.tap(find.byType(LikeButton));
        await tester.pumpAndSettle();
        expect(
          container.read(favoriteControllerProvider).likeCounts['target-1'],
          1,
        );

        // Search screen recreated with stale backend payload still at 0.
        await pumpButton(tester, targetId: 'target-1', initialCount: 0);

        // Regression assertion: count must remain 1 (not fall back to 0).
        expect(
          container.read(favoriteControllerProvider).likeCounts['target-1'],
          1,
        );
      },
    );
  });
}
