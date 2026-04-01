import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/story_repository.dart';
import '../../domain/story_item.dart';
import '../../domain/story_view_receipt.dart';
import '../../domain/story_viewer_route_args.dart';
import 'story_tray_controller.dart';

final storyViewerControllerProvider =
    Provider.autoDispose<StoryViewerController>((ref) {
      return StoryViewerController(ref);
    });

final storyViewersProvider = FutureProvider.autoDispose
    .family<List<StoryViewReceipt>, String>((ref, storyId) {
      return ref.read(storyViewerControllerProvider).loadViewers(storyId);
    });

final storyViewerRouteArgsProvider = FutureProvider.autoDispose
    .family<StoryViewerRouteArgs, String>((ref, storyId) {
      return ref.read(storyViewerControllerProvider).loadRouteArgs(storyId);
    });

class StoryViewerController {
  StoryViewerController(this._ref);

  final Ref _ref;

  Future<void> markViewed(StoryItem story) {
    return _ref.read(storyRepositoryProvider).markStoryViewed(story);
  }

  Future<void> deleteStory(StoryItem story) async {
    await _ref.read(storyRepositoryProvider).deleteStory(story);
    _ref.invalidate(storyTrayControllerProvider);
  }

  Future<List<StoryViewReceipt>> loadViewers(String storyId) {
    return _ref.read(storyRepositoryProvider).loadViewers(storyId);
  }

  Future<StoryViewerRouteArgs> loadRouteArgs(String storyId) {
    return _ref.read(storyRepositoryProvider).loadViewerRouteArgs(storyId);
  }
}
