import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/stories/domain/story_item.dart';
import 'package:mube/src/features/stories/domain/story_tray_bundle.dart';
import 'package:mube/src/features/stories/presentation/widgets/story_ring_avatar.dart';
import 'package:mube/src/features/stories/presentation/widgets/story_tray.dart';

import '../../helpers/firebase_test_config.dart';
import '../../helpers/test_data.dart';

/// Integration tests for the stories feature.
///
/// Wraps `StoryTray` in a `ProviderScope` + `MaterialApp` surface so it
/// exercises the same providers/theme stack the feed uses, complementing the
/// widget-level tests under `test/widget/features/stories/...` which only
/// verify the tap routing between the create/options callbacks.
///
/// Coverage:
/// - Empty tray still renders the current user's "Seu story" publish entry.
/// - Active current-user bundle routes the tap to `onOpenCurrentUserStoryOptions`
///   instead of `onCreateStory`.
/// - Tapping another user's avatar invokes `onOpenStoryBundle` with that
///   user's bundle.
void main() {
  setUpAll(() async => await setupFirebaseCoreMocks());

  group('Stories Flow Integration Tests', () {
    setUp(() {
      scaffoldMessengerKey.currentState?.clearSnackBars();
    });

    StoryItem buildStory({
      String id = 'story-1',
      String ownerUid = 'user-1',
      String ownerName = 'Test User',
    }) {
      return StoryItem(
        id: id,
        ownerUid: ownerUid,
        ownerName: ownerName,
        ownerType: 'profissional',
        mediaType: StoryMediaType.image,
        mediaUrl: 'https://example.com/$id.jpg',
        createdAt: DateTime(2026, 4, 1, 10),
        expiresAt: DateTime(2026, 4, 2, 10),
        status: StoryStatus.active,
      );
    }

    StoryTrayBundle buildBundle({
      required String ownerUid,
      required String ownerName,
      bool isCurrentUser = false,
      bool hasUnseen = false,
    }) {
      return StoryTrayBundle(
        ownerUid: ownerUid,
        ownerName: ownerName,
        ownerType: 'profissional',
        stories: [buildStory(ownerUid: ownerUid, ownerName: ownerName)],
        hasUnseen: hasUnseen,
        isCurrentUser: isCurrentUser,
      );
    }

    Future<void> pumpStoryTrayApp(
      WidgetTester tester, {
      required AppUser currentUser,
      required List<StoryTrayBundle> storyBundles,
      int pendingProcessingCount = 0,
      required VoidCallback onCreateStory,
      required void Function(StoryTrayBundle bundle) onOpenStoryBundle,
      required void Function(StoryTrayBundle bundle)
      onOpenCurrentUserStoryOptions,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: ThemeData.dark(),
            home: Scaffold(
              body: StoryTray(
                currentUser: currentUser,
                storyBundles: storyBundles,
                pendingProcessingCount: pendingProcessingCount,
                onCreateStory: onCreateStory,
                onOpenStoryBundle: onOpenStoryBundle,
                onOpenCurrentUserStoryOptions: onOpenCurrentUserStoryOptions,
                onRefreshPending: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders Seu story publish entry when the tray is empty', (
      tester,
    ) async {
      final user = TestData.user(uid: 'user-1', nome: 'Usuario atual');
      var createCount = 0;
      StoryTrayBundle? openedBundle;
      StoryTrayBundle? openedOptionsBundle;

      await pumpStoryTrayApp(
        tester,
        currentUser: user,
        storyBundles: const [],
        onCreateStory: () => createCount++,
        onOpenStoryBundle: (bundle) => openedBundle = bundle,
        onOpenCurrentUserStoryOptions: (bundle) {
          openedOptionsBundle = bundle;
        },
      );

      expect(find.byType(StoryTray), findsOneWidget);
      expect(find.text('Seu story'), findsOneWidget);
      expect(find.text('Publicar'), findsOneWidget);

      final currentUserAvatar = tester
          .widgetList<StoryRingAvatar>(find.byType(StoryRingAvatar))
          .first;
      expect(currentUserAvatar.hasStory, isFalse);
      expect(currentUserAvatar.showAddBadge, isTrue);

      // Nothing was tapped yet — callbacks must remain untouched.
      expect(createCount, 0);
      expect(openedBundle, isNull);
      expect(openedOptionsBundle, isNull);
    });

    testWidgets(
      'tapping Seu story with an active bundle routes to the options callback',
      (tester) async {
        const currentUserName = 'Usuario atual';
        final user = TestData.user(uid: 'user-1', nome: currentUserName);
        var createCount = 0;
        StoryTrayBundle? openedBundle;
        StoryTrayBundle? openedOptionsBundle;

        final currentUserBundle = buildBundle(
          ownerUid: user.uid,
          ownerName: currentUserName,
          isCurrentUser: true,
        );

        await pumpStoryTrayApp(
          tester,
          currentUser: user,
          storyBundles: [currentUserBundle],
          onCreateStory: () => createCount++,
          onOpenStoryBundle: (bundle) => openedBundle = bundle,
          onOpenCurrentUserStoryOptions: (bundle) {
            openedOptionsBundle = bundle;
          },
        );

        expect(find.text('Seu story'), findsOneWidget);
        expect(find.text('Ver ou publicar'), findsOneWidget);

        final currentUserAvatar = tester
            .widgetList<StoryRingAvatar>(find.byType(StoryRingAvatar))
            .first;
        expect(currentUserAvatar.hasStory, isTrue);

        await tester.tap(find.text('Seu story'));
        await tester.pump();

        expect(createCount, 0);
        expect(openedBundle, isNull);
        expect(openedOptionsBundle, isNotNull);
        expect(openedOptionsBundle!.isCurrentUser, isTrue);
        expect(openedOptionsBundle!.ownerUid, user.uid);
      },
    );

    testWidgets(
      'tapping another user bundle triggers onOpenStoryBundle with that bundle',
      (tester) async {
        const currentUserName = 'Usuario atual';
        final user = TestData.user(uid: 'user-1', nome: currentUserName);
        var createCount = 0;
        StoryTrayBundle? openedBundle;
        StoryTrayBundle? openedOptionsBundle;

        final currentUserBundle = buildBundle(
          ownerUid: user.uid,
          ownerName: currentUserName,
          isCurrentUser: true,
        );
        final otherBundle = buildBundle(
          ownerUid: 'user-2',
          ownerName: 'Outro Usuario',
          hasUnseen: true,
        );

        await pumpStoryTrayApp(
          tester,
          currentUser: user,
          storyBundles: [currentUserBundle, otherBundle],
          onCreateStory: () => createCount++,
          onOpenStoryBundle: (bundle) => openedBundle = bundle,
          onOpenCurrentUserStoryOptions: (bundle) {
            openedOptionsBundle = bundle;
          },
        );

        expect(find.text('Outro Usuario'), findsOneWidget);

        await tester.tap(find.text('Outro Usuario'));
        await tester.pump();

        expect(createCount, 0);
        expect(openedOptionsBundle, isNull);
        expect(openedBundle, isNotNull);
        expect(openedBundle!.ownerUid, 'user-2');
        expect(openedBundle!.isCurrentUser, isFalse);
      },
    );
  });
}
