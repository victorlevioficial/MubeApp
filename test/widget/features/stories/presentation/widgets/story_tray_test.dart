import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/stories/domain/story_item.dart';
import 'package:mube/src/features/stories/domain/story_tray_bundle.dart';
import 'package:mube/src/features/stories/presentation/widgets/story_ring_avatar.dart';
import 'package:mube/src/features/stories/presentation/widgets/story_tray.dart';

import '../../../../../helpers/test_data.dart';

void main() {
  StoryItem buildStory({
    String id = 'story-1',
    String ownerUid = 'current-user',
    String ownerName = 'Usuario atual',
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
    String ownerUid = 'current-user',
    String ownerName = 'Usuario atual',
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

  Widget buildSubject({
    required List<StoryTrayBundle> storyBundles,
    required VoidCallback onCreateStory,
    required void Function(StoryTrayBundle bundle) onOpenStoryBundle,
    required void Function(StoryTrayBundle bundle)
    onOpenCurrentUserStoryOptions,
    int pendingProcessingCount = 0,
    VoidCallback? onRefreshPending,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StoryTray(
          currentUser: TestData.user(uid: 'current-user'),
          storyBundles: storyBundles,
          pendingProcessingCount: pendingProcessingCount,
          onCreateStory: onCreateStory,
          onOpenStoryBundle: onOpenStoryBundle,
          onOpenCurrentUserStoryOptions: onOpenCurrentUserStoryOptions,
          onRefreshPending: onRefreshPending ?? () {},
        ),
      ),
    );
  }

  group('StoryTray', () {
    testWidgets(
      'tapping Seu story without published stories opens the creator directly',
      (tester) async {
        var createTapCount = 0;
        StoryTrayBundle? openedBundle;
        StoryTrayBundle? openedOptionsBundle;

        await tester.pumpWidget(
          buildSubject(
            storyBundles: const [],
            onCreateStory: () => createTapCount++,
            onOpenStoryBundle: (bundle) => openedBundle = bundle,
            onOpenCurrentUserStoryOptions: (bundle) {
              openedOptionsBundle = bundle;
            },
          ),
        );

        await tester.tap(find.text('Seu story'));
        await tester.pump();

        final currentUserAvatar = tester
            .widgetList<StoryRingAvatar>(find.byType(StoryRingAvatar))
            .first;

        expect(createTapCount, 1);
        expect(openedBundle, isNull);
        expect(openedOptionsBundle, isNull);
        expect(currentUserAvatar.hasStory, isFalse);
        expect(find.text('Publicar'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Seu story while a video is processing refreshes instead of opening creator',
      (tester) async {
        var createTapCount = 0;
        var refreshTapCount = 0;
        StoryTrayBundle? openedBundle;
        StoryTrayBundle? openedOptionsBundle;

        await tester.pumpWidget(
          buildSubject(
            storyBundles: const [],
            pendingProcessingCount: 1,
            onCreateStory: () => createTapCount++,
            onRefreshPending: () => refreshTapCount++,
            onOpenStoryBundle: (bundle) => openedBundle = bundle,
            onOpenCurrentUserStoryOptions: (bundle) {
              openedOptionsBundle = bundle;
            },
          ),
        );

        await tester.tap(find.text('Seu story'));
        await tester.pump();

        expect(refreshTapCount, 1);
        expect(createTapCount, 0);
        expect(openedBundle, isNull);
        expect(openedOptionsBundle, isNull);
        expect(find.text('Processando'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Seu story with a published story opens the current user options',
      (tester) async {
        var createTapCount = 0;
        StoryTrayBundle? openedBundle;
        StoryTrayBundle? openedOptionsBundle;

        await tester.pumpWidget(
          buildSubject(
            storyBundles: [
              buildBundle(isCurrentUser: true),
              buildBundle(ownerUid: 'other-user', ownerName: 'Outro usuario'),
            ],
            onCreateStory: () => createTapCount++,
            onOpenStoryBundle: (bundle) => openedBundle = bundle,
            onOpenCurrentUserStoryOptions: (bundle) {
              openedOptionsBundle = bundle;
            },
          ),
        );

        await tester.tap(find.text('Seu story'));
        await tester.pump();

        final currentUserAvatar = tester
            .widgetList<StoryRingAvatar>(find.byType(StoryRingAvatar))
            .first;

        expect(createTapCount, 0);
        expect(openedBundle, isNull);
        expect(openedOptionsBundle?.isCurrentUser, isTrue);
        expect(currentUserAvatar.hasStory, isTrue);
        expect(find.text('Ver ou publicar'), findsOneWidget);
      },
    );
  });
}
