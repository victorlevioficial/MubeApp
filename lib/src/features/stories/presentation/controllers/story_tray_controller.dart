import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/presentation/feed_controller.dart';
import '../../data/story_repository.dart';
import '../../domain/story_tray_bundle.dart';

final storyTrayControllerProvider =
    AsyncNotifierProvider<StoryTrayController, List<StoryTrayBundle>>(
      StoryTrayController.new,
    );

class StoryTrayController extends AsyncNotifier<List<StoryTrayBundle>> {
  @override
  Future<List<StoryTrayBundle>> build() {
    final discoveryOwnerIds = ref.watch(
      feedControllerProvider.select(_discoveryOwnerFingerprint),
    );
    final ownerIds = discoveryOwnerIds.isEmpty
        ? const <String>[]
        : discoveryOwnerIds.split('|');
    return ref
        .read(storyRepositoryProvider)
        .loadTray(discoveryOwnerIds: ownerIds);
  }

  Future<void> refresh() async {
    final discoveryOwnerIds = _discoveryOwnerFingerprint(
      ref.read(feedControllerProvider),
    );
    final ownerIds = discoveryOwnerIds.isEmpty
        ? const <String>[]
        : discoveryOwnerIds.split('|');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(storyRepositoryProvider)
          .loadTray(discoveryOwnerIds: ownerIds),
    );
  }
}

String _discoveryOwnerFingerprint(AsyncValue<FeedState> feedStateAsync) {
  final ownerIds = <String>{};
  final feedState = feedStateAsync.value;
  if (feedState == null) {
    return '';
  }

  for (final item in feedState.featuredItems) {
    ownerIds.add(item.uid);
  }
  for (final item in feedState.items) {
    ownerIds.add(item.uid);
  }
  for (final sectionItems in feedState.sectionItems.values) {
    for (final item in sectionItems) {
      ownerIds.add(item.uid);
    }
  }

  if (ownerIds.isEmpty) {
    return '';
  }

  final sortedOwnerIds = ownerIds.toList(growable: false)..sort();
  return sortedOwnerIds.join('|');
}
