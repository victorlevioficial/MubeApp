import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/moderation/data/moderation_repository.dart';
import 'package:mube/src/features/profile/presentation/public_profile_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeAuthRepository fakeAuthRepository;
  late FakeChatRepository fakeChatRepository;
  late FakeModerationRepository fakeModerationRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeChatRepository = FakeChatRepository();
    fakeModerationRepository = FakeModerationRepository();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        chatRepositoryProvider.overrideWithValue(fakeChatRepository),
        moderationRepositoryProvider.overrideWithValue(
          fakeModerationRepository,
        ),
        currentUserProfileProvider.overrideWith(
          (ref) => fakeAuthRepository.watchUser(''),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PublicProfileController', () {
    test('build loads user profile successfully', () async {
      // Setup
      final user = TestData.user(
        uid: 'user-1',
        tipoPerfil: AppUserType.professional,
      );
      // We set appUser in helper to "emit" it when requested via getUsersByIds if we impl logic there
      // My FakeAuthRepository implementation of getUsersByIds checks _appUser and filters by ID.
      // So I need to set _appUser to the target user 'user-1'.
      // But wait, what if I need current user AND target user?
      // The controller needs target user. Access to currentUser is for block/report.

      // Setup target user
      fakeAuthRepository.appUser = user;

      // Act
      final state = await container.read(
        publicProfileControllerProvider('user-1').future,
      );

      // Assert
      expect(state.isLoading, false);
      expect(state.user, user);
      expect(state.error, null);
    });

    test('build handles user not found', () async {
      // Setup - no user matches
      fakeAuthRepository.appUser = null;

      // Act
      final state = await container.read(
        publicProfileControllerProvider('missing-user').future,
      );

      // Assert
      expect(state.isLoading, false);
      expect(state.error, contains('Perfil não encontrado'));
      // Our implementation returns specific string, or failing via getUsersByIds returning empty list
    });

    test('build handles error from repository', () async {
      // Setup
      fakeAuthRepository.shouldThrow = true;

      // Act
      final state = await container.read(
        publicProfileControllerProvider('user-1').future,
      );

      // Assert
      expect(state.isLoading, false);
      expect(state.error, contains('Erro ao carregar perfil'));
    });

    test('blockUser calls repository successfully', () async {
      // Setup
      final targetUser = TestData.user(uid: 'target-1');
      fakeAuthRepository.appUser = targetUser; // For the builds to succeed

      // Initialize controller
      await container.read(publicProfileControllerProvider('target-1').future);

      // We need CURRENT user for blockUser.
      // Controller reads currentUser from ref.read(currentUserProfileProvider).value.
      // I can't easily change _appUser in FakeAuthRepository to be TWO different users at once for synchronous calls?
      // FakeAuthRepository has _currentUser (auth) and _appUser (firestore).
      // getUsersByIds uses _appUser.
      // watchUser uses _appUser.
      // This is a limitation of my FakeAuthRepository. It supports only ONE user at a time for data retrieval?

      // Let's see:
      // blockUser: final currentUser = ref.read(currentUserProfileProvider).value;
      // build: final result = await ref.read(authRepositoryProvider).getUsersByIds([uid]);

      // If I change fakeAuthRepository.appUser AFTER build, but BEFORE blockUser call...
      // But blockUser reads currentUserProfileProvider which stream comes from watchUser which yields _appUser.
      // So if I change _appUser, both streams update?

      // Solution:
      // 1. Set appUser = targetUser.
      // 2. Build controller -> gets targetUser.
      // 3. Set appUser = currentUser.
      // 4. Update currentUserProfileProvider?
      //    waitForUser(container) needed?

      // Actually, currentUserProfileProvider depends on authStateChangesProvider.
      // AND watchUser.

      // If I update appUser, the stream from watchUser will emit new user if it's listening to ANY changes?
      // My Fake implementation of watchUser: return Stream.value(_appUser);
      // It does NOT update dynamically when I change _appUser property unless I re-emit?
      // Real implementation would stream.

      // In FakeAuthRepository (lines 79-81):
      // set appUser(AppUser? user) { _appUser = user; }
      // This setter does NOT notify listeners of `watchUser` stream unless I implemented it so?
      // Line 92: return Stream.value(_appUser); -> A single value stream.

      // So I can't easily switch users dynamically for `currentUserProfileProvider` vs `getUsersByIds`.

      // Mocking strategy change:
      // I should override `currentUserProfileProvider` to return a FIXED stream for the logged-in user.
      // And let `authRepositoryProvider.getUsersByIds` use `_appUser` (the target).

      // Setup:
      final currentUser = TestData.user(uid: 'me');

      // Override currentUserProfileProvider with fixed value
      container.updateOverrides([
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        chatRepositoryProvider.overrideWithValue(fakeChatRepository),
        moderationRepositoryProvider.overrideWithValue(
          fakeModerationRepository,
        ),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(currentUser),
        ),
      ]);

      // Setup target user in fake repository
      final targetUserOnRepo = TestData.user(uid: 'target-1');
      fakeAuthRepository.appUser = targetUserOnRepo;

      // Act
      final controller = container.read(
        publicProfileControllerProvider('target-1').notifier,
      );
      // Wait for build
      await container.read(publicProfileControllerProvider('target-1').future);
      // Wait for currentUser to be available
      await waitForUser(container);

      final result = await controller.blockUser();

      // Assert
      expect(result, true);
    });
  });
}

Future<void> waitForUser(ProviderContainer container) async {
  final completer = Completer<void>();
  final sub = container.listen(currentUserProfileProvider, (previous, next) {
    if (next.hasValue && next.value != null) {
      if (!completer.isCompleted) completer.complete();
    }
  }, fireImmediately: true);
  await completer.future.timeout(const Duration(seconds: 1));
  sub.close();
}
