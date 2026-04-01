import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/stories/data/story_repository.dart';
import 'package:mube/src/features/stories/domain/story_item.dart';
import 'package:mube/src/features/stories/domain/story_tray_bundle.dart';
import 'package:mube/src/features/stories/domain/story_view_receipt.dart';
import 'package:mube/src/features/stories/domain/story_viewer_route_args.dart';
import 'package:mube/src/features/stories/presentation/screens/story_viewer_route_loader.dart';
import 'package:mube/src/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:mube/src/features/stories/presentation/services/story_media_picker_service.dart';
import 'package:network_image_mock/network_image_mock.dart';

class _FakeStoryRepository extends Fake implements StoryRepository {
  _FakeStoryRepository({this.routeArgs});

  final StoryViewerRouteArgs? routeArgs;
  final List<String> deletedStoryIds = <String>[];

  @override
  Future<void> markStoryViewed(StoryItem story) async {}

  @override
  Future<void> deleteStory(StoryItem story) async {
    deletedStoryIds.add(story.id);
  }

  @override
  Future<List<StoryViewReceipt>> loadViewers(String storyId) async {
    return const [];
  }

  @override
  Future<List<StoryTrayBundle>> loadTray({
    Iterable<String> discoveryOwnerIds = const <String>[],
  }) async {
    return const [];
  }

  @override
  Future<StoryViewerRouteArgs> loadViewerRouteArgs(String storyId) async {
    if (routeArgs == null) {
      throw Exception('Story nao encontrado.');
    }
    return routeArgs!;
  }
}

StoryItem _story({
  required String id,
  required String caption,
  required DateTime createdAt,
}) {
  return StoryItem(
    id: id,
    ownerUid: 'owner-user',
    ownerName: 'Owner User',
    ownerType: 'profissional',
    mediaType: StoryMediaType.image,
    mediaUrl: 'https://example.com/$id.jpg',
    caption: caption,
    createdAt: createdAt,
    expiresAt: createdAt.add(const Duration(hours: 24)),
    status: StoryStatus.active,
  );
}

StoryTrayBundle _bundle(List<StoryItem> stories, {bool isCurrentUser = false}) {
  return StoryTrayBundle(
    ownerUid: 'owner-user',
    ownerName: 'Owner User',
    ownerType: 'profissional',
    stories: stories,
    hasUnseen: true,
    isCurrentUser: isCurrentUser,
  );
}

void main() {
  group('StoryViewerScreen', () {
    testWidgets('starts on the story indicated by initialStoryId', (
      tester,
    ) async {
      final firstStory = _story(
        id: 'story-1',
        caption: 'Primeiro story',
        createdAt: DateTime(2026, 4, 10, 8),
      );
      final secondStory = _story(
        id: 'story-2',
        caption: 'Segundo story',
        createdAt: DateTime(2026, 4, 10, 9),
      );
      final args = StoryViewerRouteArgs(
        bundles: [
          _bundle([firstStory, secondStory]),
        ],
        initialOwnerUid: 'owner-user',
        initialStoryId: secondStory.id,
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storyRepositoryProvider.overrideWithValue(_FakeStoryRepository()),
            ],
            child: MaterialApp(home: StoryViewerScreen(args: args)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });

      expect(find.text('Segundo story'), findsOneWidget);
      expect(find.text('Primeiro story'), findsNothing);
    });

    testWidgets('shows a fallback state when no stories are available', (
      tester,
    ) async {
      const args = StoryViewerRouteArgs(
        bundles: [],
        initialOwnerUid: 'missing-owner',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storyRepositoryProvider.overrideWithValue(_FakeStoryRepository()),
          ],
          child: const MaterialApp(home: StoryViewerScreen(args: args)),
        ),
      );
      await tester.pump();

      expect(find.text('Story nao encontrado.'), findsOneWidget);
      expect(find.text('Esse story nao esta mais disponivel.'), findsOneWidget);
    });

    testWidgets(
      'deletes the current story and keeps the viewer open on the next one',
      (tester) async {
        final firstStory = _story(
          id: 'story-delete-1',
          caption: 'Story para excluir',
          createdAt: DateTime(2026, 4, 10, 8),
        );
        final secondStory = _story(
          id: 'story-delete-2',
          caption: 'Story restante',
          createdAt: DateTime(2026, 4, 10, 9),
        );
        final args = StoryViewerRouteArgs(
          bundles: [
            _bundle([firstStory, secondStory], isCurrentUser: true),
          ],
          initialOwnerUid: 'owner-user',
          initialStoryId: firstStory.id,
        );
        final repository = _FakeStoryRepository();

        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                storyRepositoryProvider.overrideWithValue(repository),
              ],
              child: MaterialApp(home: StoryViewerScreen(args: args)),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        });

        expect(find.text('Story para excluir'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('Excluir'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(repository.deletedStoryIds, ['story-delete-1']);
        expect(find.text('Story restante'), findsOneWidget);
        expect(find.text('Story para excluir'), findsNothing);
      },
    );
  });

  group('StoryMediaPickerService', () {
    test('requiresVideoNormalization matches the stories upload contract', () {
      expect(
        StoryMediaPickerService.requiresVideoNormalization(
          videoPath: 'C:/tmp/story.mp4',
          fileSizeBytes: 8 * 1024 * 1024,
        ),
        isFalse,
      );
      expect(
        StoryMediaPickerService.requiresVideoNormalization(
          videoPath: 'C:/tmp/story.mov',
          fileSizeBytes: 8 * 1024 * 1024,
        ),
        isTrue,
      );
      expect(
        StoryMediaPickerService.requiresVideoNormalization(
          videoPath: 'C:/tmp/story.mp4',
          fileSizeBytes: 120 * 1024 * 1024,
        ),
        isTrue,
      );
    });

    test('accepts only vertical media aspect ratios for stories', () {
      expect(
        StoryMediaPickerService.isSupportedStoryImageAspectRatio(9 / 16),
        isTrue,
      );
      expect(
        StoryMediaPickerService.isSupportedStoryImageAspectRatio(16 / 9),
        isFalse,
      );
      expect(
        StoryMediaPickerService.isSupportedStoryVideoAspectRatio(9 / 16),
        isTrue,
      );
      expect(
        StoryMediaPickerService.isSupportedStoryVideoAspectRatio(1.0),
        isFalse,
      );
    });
  });

  group('StoryViewerRouteLoader', () {
    testWidgets('loads viewer state from story id when no extra is provided', (
      tester,
    ) async {
      final story = _story(
        id: 'story-loader-fetch',
        caption: 'Story carregado por storyId',
        createdAt: DateTime(2026, 4, 10, 10),
      );
      final args = StoryViewerRouteArgs(
        bundles: [
          _bundle([story]),
        ],
        initialOwnerUid: 'owner-user',
        initialStoryId: story.id,
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storyRepositoryProvider.overrideWithValue(
                _FakeStoryRepository(routeArgs: args),
              ),
            ],
            child: MaterialApp(home: StoryViewerRouteLoader(storyId: story.id)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });

      expect(find.text('Story carregado por storyId'), findsOneWidget);
    });

    testWidgets('builds the viewer when route args are preloaded', (
      tester,
    ) async {
      final story = _story(
        id: 'story-loader',
        caption: 'Story carregado da rota',
        createdAt: DateTime(2026, 4, 10, 10),
      );
      final args = StoryViewerRouteArgs(
        bundles: [
          _bundle([story]),
        ],
        initialOwnerUid: 'owner-user',
        initialStoryId: story.id,
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storyRepositoryProvider.overrideWithValue(_FakeStoryRepository()),
            ],
            child: MaterialApp(
              home: StoryViewerRouteLoader(
                storyId: story.id,
                preloadedArgs: args,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      });

      expect(find.text('Story carregado da rota'), findsOneWidget);
    });
  });
}
