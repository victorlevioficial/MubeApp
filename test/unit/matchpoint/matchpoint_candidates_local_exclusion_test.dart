import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/providers/app_config_provider.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_feed_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_swipe_outbox_store.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_feed_snapshot.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fakes.dart';

class _FakeMatchpointFeedRepository implements MatchpointFeedRepository {
  @override
  FutureResult<MatchpointFeedSnapshot> fetchExploreFeed({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    return Right(
      MatchpointFeedSnapshot(
        candidates: const [
          AppUser(uid: 'target-1', email: 'target-1@mube.app'),
          AppUser(uid: 'target-2', email: 'target-2@mube.app'),
        ],
        fetchedAt: DateTime(2026, 4, 9, 1),
        source: MatchpointFeedSource.projectedFeed,
        isServerRanked: true,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MatchpointCandidates excludes users pending in local outbox', () async {
    SharedPreferences.setMockInitialValues({});

    final authRepository = FakeAuthRepository(
      initialUser: FakeFirebaseUser(uid: 'user-1', email: 'user-1@mube.app'),
    )..appUser = const AppUser(
        uid: 'user-1',
        email: 'user-1@mube.app',
        nome: 'User 1',
        matchpointProfile: {
          'musicalGenres': ['rock'],
        },
        privacySettings: {},
        blockedUsers: [],
      );

    final outboxStore = MatchpointSwipeOutboxStore(SharedPreferences.getInstance);
    await outboxStore.enqueue(
      userId: 'user-1',
      entry: PersistedMatchpointSwipeCommand(
        commandId: 'cmd-1',
        command: MatchpointSwipeCommand(
          sourceUserId: 'user-1',
          targetUserId: 'target-1',
          action: MatchpointSwipeAction.like,
          createdAt: DateTime(2026, 4, 9, 1),
          idempotencyKey: 'cmd-1',
        ),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        currentUserProfileProvider.overrideWithValue(
          const AsyncData(
            AppUser(
              uid: 'user-1',
              email: 'user-1@mube.app',
              nome: 'User 1',
              matchpointProfile: {
                'musicalGenres': ['rock'],
              },
              privacySettings: {},
              blockedUsers: [],
            ),
          ),
        ),
        appConfigProvider.overrideWith((ref) async => const AppConfig()),
        blockedUsersProvider.overrideWith((ref) => Stream.value(const [])),
        matchpointFeedRepositoryProvider.overrideWithValue(
          _FakeMatchpointFeedRepository(),
        ),
        matchpointSwipeOutboxStoreProvider.overrideWithValue(outboxStore),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(authRepository.dispose);

    final candidates = await container.read(matchpointCandidatesProvider.future);

    expect(candidates.map((candidate) => candidate.uid).toList(), ['target-2']);
  });
}
