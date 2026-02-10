import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/analytics/analytics_provider.dart';
import '../../../core/typedefs.dart';
import '../data/auth_repository.dart';

part 'register_controller.g.dart';

@riverpod
class RegisterController extends _$RegisterController {
  @override
  FutureOr<void> build() {
    // initial state is void (null)
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(
      action: () => ref
          .read(authRepositoryProvider)
          .registerWithEmailAndPassword(email: email, password: password),
      method: 'email',
      logSignupComplete: true,
    );
  }

  Future<void> signInWithGoogle() async {
    await _runAuthAction(
      action: () => ref.read(authRepositoryProvider).signInWithGoogle(),
      method: 'google',
    );
  }

  Future<void> signInWithApple() async {
    await _runAuthAction(
      action: () => ref.read(authRepositoryProvider).signInWithApple(),
      method: 'apple',
    );
  }

  Future<void> _runAuthAction({
    required FutureResult<Unit> Function() action,
    required String method,
    bool logSignupComplete = false,
  }) async {
    state = const AsyncLoading();
    final result = await action();

    result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
      },
      (success) {
        if (logSignupComplete) {
          ref
              .read(analyticsServiceProvider)
              .logAuthSignupComplete(method: method);
        }
        state = const AsyncData(null);
      },
    );
  }
}
