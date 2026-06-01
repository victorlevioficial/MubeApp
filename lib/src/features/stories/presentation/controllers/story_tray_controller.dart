import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../utils/app_logger.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../feed/domain/feed_item.dart';
import '../../../feed/presentation/feed_controller.dart';
import '../../data/story_repository.dart';
import '../../domain/story_item.dart';
import '../../domain/story_repository_exception.dart';
import '../../domain/story_tray_bundle.dart';

final storyTrayControllerProvider =
    AsyncNotifierProvider<StoryTrayController, List<StoryTrayBundle>>(
      StoryTrayController.new,
    );

const int _maxPendingStoryPolls = 6;
final Map<String, int> _pendingStoryPollAttempts = <String, int>{};

final currentUserPendingStoriesProvider = FutureProvider<List<StoryItem>>((
  ref,
) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const <StoryItem>[];

  try {
    final stories = await ref
        .read(storyRepositoryProvider)
        .loadCurrentUserProcessingStories();

    if (stories.isEmpty) {
      // Processing finished: refresh the tray once so the now-active story
      // shows up, then stop polling.
      final wasPolling = _pendingStoryPollAttempts.remove(uid) != null;
      if (wasPolling) {
        scheduleMicrotask(() => ref.invalidate(storyTrayControllerProvider));
      }
      return const <StoryItem>[];
    }

    // Re-check with an increasing backoff (8s, 13s, 18s, ...) up to a hard cap
    // instead of a fixed 8s loop that reloaded the entire tray forever.
    final attempt = _pendingStoryPollAttempts[uid] ?? 0;
    if (attempt < _maxPendingStoryPolls) {
      _pendingStoryPollAttempts[uid] = attempt + 1;
      final timer = Timer(
        Duration(seconds: 8 + attempt * 5),
        ref.invalidateSelf,
      );
      ref.onDispose(timer.cancel);
    }
    return stories;
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Falha ao carregar stories pendentes do usuario atual',
      error,
      stackTrace,
    );
    return const <StoryItem>[];
  }
});

class StoryTrayController extends AsyncNotifier<List<StoryTrayBundle>> {
  @override
  Future<List<StoryTrayBundle>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return const <StoryTrayBundle>[];

    final discoveryOwnerIds = ref.watch(
      feedControllerProvider.select(_discoveryOwnerFingerprint),
    );
    final ownerIds = discoveryOwnerIds.isEmpty
        ? const <String>[]
        : discoveryOwnerIds.split('|');

    return _loadTray(ownerIds);
  }

  Future<void> refresh() async {
    if (ref.read(currentUserIdProvider) == null) {
      state = const AsyncData(<StoryTrayBundle>[]);
      return;
    }

    final discoveryOwnerIds = _discoveryOwnerFingerprint(
      ref.read(feedControllerProvider),
    );
    final ownerIds = discoveryOwnerIds.isEmpty
        ? const <String>[]
        : discoveryOwnerIds.split('|');
    if (!state.hasValue) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(() => _loadTray(ownerIds));
  }

  /// Optimistically clears the "unseen" ring for [ownerUid] so the tray updates
  /// instantly after opening a bundle, without waiting for the server-side
  /// `story_seen_authors` write plus a full reload.
  void markBundleSeen(String ownerUid) {
    final current = state.value;
    if (current == null) return;
    if (!current.any((b) => b.ownerUid == ownerUid && b.hasUnseen)) return;
    state = AsyncData([
      for (final bundle in current)
        bundle.ownerUid == ownerUid
            ? bundle.copyWith(hasUnseen: false)
            : bundle,
    ]);
  }

  Future<List<StoryTrayBundle>> _loadTray(List<String> ownerIds) async {
    if (ref.read(currentUserIdProvider) == null) {
      return const <StoryTrayBundle>[];
    }

    try {
      return await ref
          .read(storyRepositoryProvider)
          .loadTray(discoveryOwnerIds: ownerIds);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao carregar a bandeja ampla de stories, tentando fallback',
        error,
        stackTrace,
      );

      try {
        return await ref
            .read(storyRepositoryProvider)
            .loadTray(includePublicOwners: false);
      } catch (fallbackError, fallbackStackTrace) {
        AppLogger.error(
          'Falha ao carregar a bandeja de stories',
          fallbackError,
          fallbackStackTrace,
        );
        if (fallbackError is StoryRepositoryException) {
          rethrow;
        }
        throw StoryRepositoryException.loadTrayFailed();
      }
    }
  }
}

String _discoveryOwnerFingerprint(AsyncValue<FeedState> feedStateAsync) {
  return buildStoryTrayDiscoveryFingerprint(feedStateAsync.value);
}

const int _maxStoryTrayFeaturedOwners = 4;
const int _maxStoryTraySectionOwnersPerSection = 2;
const int _maxStoryTrayMainFeedOwners = 8;
const int _maxStoryTrayDiscoveryOwners = 16;

@visibleForTesting
String buildStoryTrayDiscoveryFingerprint(FeedState? feedState) {
  if (feedState == null) {
    return '';
  }

  final ownerIds = <String>{};

  void collectOwnerIds(Iterable<FeedItem> items, {required int maxItems}) {
    var collected = 0;
    for (final item in items) {
      if (item.uid.isEmpty || ownerIds.contains(item.uid)) {
        continue;
      }

      ownerIds.add(item.uid);
      collected++;
      if (collected >= maxItems ||
          ownerIds.length >= _maxStoryTrayDiscoveryOwners) {
        return;
      }
    }
  }

  collectOwnerIds(
    feedState.featuredItems,
    maxItems: _maxStoryTrayFeaturedOwners,
  );

  for (final sectionItems in feedState.sectionItems.values) {
    if (ownerIds.length >= _maxStoryTrayDiscoveryOwners) {
      break;
    }
    collectOwnerIds(
      sectionItems,
      maxItems: _maxStoryTraySectionOwnersPerSection,
    );
  }

  if (ownerIds.length < _maxStoryTrayDiscoveryOwners) {
    collectOwnerIds(feedState.items, maxItems: _maxStoryTrayMainFeedOwners);
  }

  if (ownerIds.isEmpty) {
    return '';
  }

  final sortedOwnerIds = ownerIds.toList(growable: false)..sort();
  return sortedOwnerIds.join('|');
}
