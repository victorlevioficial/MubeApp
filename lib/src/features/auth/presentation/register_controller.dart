import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .registerWithEmailAndPassword(email: email, password: password);

    result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
      },
      (success) {
        state = const AsyncData(null);
      },
    );
  }
}
