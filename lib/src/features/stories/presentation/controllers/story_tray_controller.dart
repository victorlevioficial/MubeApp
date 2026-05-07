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

final currentUserPendingStoriesProvider = FutureProvider<List<StoryItem>>((
  ref,
) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const <StoryItem>[];

  try {
    final stories = await ref
        .read(storyRepositoryProvider)
        .loadCurrentUserProcessingStories();
    if (stories.isNotEmpty) {
      final timer = Timer(const Duration(seconds: 8), () {
        ref.invalidateSelf();
        ref.invalidate(storyTrayControllerProvider);
      });
      ref.onDispose(timer.cancel);
      scheduleMicrotask(() => ref.invalidate(storyTrayControllerProvider));
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
