import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/favorite_integration_effects.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/favorites/domain/favorite_effects.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';

import '../../../helpers/test_fakes.dart';

final _integrationEffectsProvider = Provider<FavoriteEffects>(
  (ref) => FavoriteIntegrationEffects(ref),
);

class _RecordingFeedController extends FeedController {
  final List<({String targetId, bool isLiked})> updates = [];

  @override
  FutureOr<FeedState> build() => const FeedState();

  @override
  void updateLikeCount(String targetId, {required bool isLiked}) {
    updates.add((targetId: targetId, isLiked: isLiked));
  }
}

void main() {
  test('projects optimistic favorite changes into the feed', () {
    final container = ProviderContainer(
      overrides: [
        feedControllerProvider.overrideWith(_RecordingFeedController.new),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(_integrationEffectsProvider)
        .onLocalStatusChanged('target-1', isFavorite: true);

    final controller =
        container.read(feedControllerProvider.notifier)
            as _RecordingFeedController;
    expect(controller.updates, [(targetId: 'target-1', isLiked: true)]);
  });

  test('reevaluates chat access after a favorite is synced', () async {
    final chatRepository = FakeChatRepository();
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(chatRepository)],
    );
    addTearDown(container.dispose);

    await container
        .read(_integrationEffectsProvider)
        .onFavoriteAdded(currentUserId: 'user-1', targetId: 'target-1');

    expect(chatRepository.reevaluateConversationAccessByUsersCalls, 1);
  });
}
