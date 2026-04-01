import 'story_tray_bundle.dart';

class StoryViewerRouteArgs {
  const StoryViewerRouteArgs({
    required this.bundles,
    required this.initialOwnerUid,
    this.initialStoryId,
  });

  final List<StoryTrayBundle> bundles;
  final String initialOwnerUid;
  final String? initialStoryId;
}
