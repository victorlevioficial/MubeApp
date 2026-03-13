import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/match_swipe_deck.dart';

void main() {
  group('MatchSwipeDeck', () {
    testWidgets('keeps swipes enabled while a backend action is pending', (
      tester,
    ) async {
      final swipeCompleter = Completer<bool>();
      var likeCalls = 0;
      var dislikeCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 720,
              child: MatchSwipeDeck(
                candidates: const [
                  AppUser(uid: '1', email: 'one@mube.app', nome: 'One'),
                  AppUser(uid: '2', email: 'two@mube.app', nome: 'Two'),
                  AppUser(uid: '3', email: 'three@mube.app', nome: 'Three'),
                ],
                controller: CardSwiperController(),
                onSwipeRight: (_) {
                  likeCalls += 1;
                  return swipeCompleter.future;
                },
                onSwipeLeft: (_) async {
                  dislikeCalls += 1;
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      CardSwiper swiper() => tester.widget<CardSwiper>(find.byType(CardSwiper));

      expect(swiper().isDisabled, isFalse);

      final firstSwipeAccepted = swiper().onSwipe!(
        0,
        1,
        CardSwiperDirection.right,
      );
      await tester.pump();

      expect(firstSwipeAccepted, isTrue);
      expect(likeCalls, 1);
      expect(swiper().isDisabled, isFalse);

      final secondSwipeAccepted = swiper().onSwipe!(
        1,
        2,
        CardSwiperDirection.left,
      );
      await tester.pump();

      expect(secondSwipeAccepted, isTrue);
      expect(dislikeCalls, 1);

      swipeCompleter.complete(true);
      await tester.pump();
      await tester.pump();

      expect(swiper().isDisabled, isFalse);
    });
  });
}
