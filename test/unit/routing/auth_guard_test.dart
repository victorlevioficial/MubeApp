import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/splash/providers/splash_provider.dart';
import 'package:mube/src/routing/auth_guard.dart';
import 'package:mube/src/routing/route_paths.dart';

import '../../helpers/test_fakes.dart';

final _authGuardProvider = Provider<AuthGuard>((ref) => AuthGuard(ref));

Widget _rootBuilder(BuildContext context, GoRouterState state) {
  return const SizedBox.shrink();
}

RouteConfiguration _testConfiguration() {
  return RouteConfiguration(
    ValueNotifier<RoutingConfig>(
      RoutingConfig(
        routes: <RouteBase>[GoRoute(path: '/', builder: _rootBuilder)],
      ),
    ),
    navigatorKey: GlobalKey<NavigatorState>(),
  );
}

GoRouterState _stateForPath(String path) {
  return GoRouterState(
    _testConfiguration(),
    uri: Uri.parse(path),
    matchedLocation: path,
    fullPath: path,
    pathParameters: const <String, String>{},
    pageKey: ValueKey<String>('page:$path'),
  );
}

class _FakeBuildContext extends Fake implements BuildContext {}

void main() {
  group('AuthGuard', () {
    test(
      'refreshes security context instead of signing out on permission-related profile stream error',
      () async {
        final fakeUser = FakeFirebaseUser(
          uid: 'user-1',
          email: 'test@mube.app',
        );
        final fakeAuthRepository = FakeAuthRepository(initialUser: fakeUser)
          ..emitUser(fakeUser);
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            authStateChangesProvider.overrideWithValue(
              AsyncValue.data(fakeUser),
            ),
            currentUserProfileProvider.overrideWithValue(
              AsyncValue.error(
                Exception('permission-denied'),
                StackTrace.empty,
              ),
            ),
          ],
        );

        addTearDown(() {
          fakeAuthRepository.dispose();
          container.dispose();
        });

        container.read(splashFinishedProvider.notifier).finish();
        final context = _FakeBuildContext();

        final guard = container.read(_authGuardProvider);
        final redirect = await guard.redirect(
          context,
          _stateForPath(RoutePaths.feed),
        );

        expect(redirect, RoutePaths.splash);
        expect(fakeAuthRepository.refreshSecurityContextCalls, 1);
        expect(fakeAuthRepository.signOutCalls, 0);
        expect(fakeAuthRepository.ensureCurrentUserProfileExistsCalls, 0);
      },
    );

    test(
      'signs out only when refresh reports a terminal auth failure',
      () async {
        final fakeUser = FakeFirebaseUser(
          uid: 'user-1',
          email: 'test@mube.app',
        );
        final fakeAuthRepository = FakeAuthRepository(initialUser: fakeUser)
          ..emitUser(fakeUser)
          ..refreshSecurityContextResult = const Left(
            AuthFailure(
              message: 'Sua sessão expirou. Faça login novamente.',
              debugMessage: 'user-token-expired',
            ),
          );
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            authStateChangesProvider.overrideWithValue(
              AsyncValue.data(fakeUser),
            ),
            currentUserProfileProvider.overrideWithValue(
              AsyncValue.error(
                Exception('permission-denied'),
                StackTrace.empty,
              ),
            ),
          ],
        );

        addTearDown(() {
          fakeAuthRepository.dispose();
          container.dispose();
        });

        container.read(splashFinishedProvider.notifier).finish();
        final context = _FakeBuildContext();

        final guard = container.read(_authGuardProvider);
        final redirect = await guard.redirect(
          context,
          _stateForPath(RoutePaths.feed),
        );

        expect(redirect, RoutePaths.login);
        expect(fakeAuthRepository.refreshSecurityContextCalls, 1);
        expect(fakeAuthRepository.signOutCalls, 1);
        expect(fakeAuthRepository.currentUser, isNull);
      },
    );

    test(
      'retries missing profile creation after refreshing security context',
      () async {
        final fakeUser = FakeFirebaseUser(
          uid: 'user-1',
          email: 'test@mube.app',
        );
        final fakeAuthRepository = FakeAuthRepository(initialUser: fakeUser)
          ..emitUser(fakeUser)
          ..ensureCurrentUserProfileExistsResults.addAll([
            Left(PermissionFailure.firestore()),
            const Right(unit),
          ]);
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            authStateChangesProvider.overrideWithValue(
              AsyncValue.data(fakeUser),
            ),
            currentUserProfileProvider.overrideWithValue(
              const AsyncValue.data(null),
            ),
          ],
        );

        addTearDown(() {
          fakeAuthRepository.dispose();
          container.dispose();
        });

        container.read(splashFinishedProvider.notifier).finish();
        final context = _FakeBuildContext();

        final guard = container.read(_authGuardProvider);
        final redirect = await guard.redirect(
          context,
          _stateForPath(RoutePaths.feed),
        );

        expect(redirect, RoutePaths.splash);
        expect(fakeAuthRepository.ensureCurrentUserProfileExistsCalls, 2);
        expect(fakeAuthRepository.refreshSecurityContextCalls, 1);
        expect(fakeAuthRepository.signOutCalls, 0);
      },
    );
  });
}
