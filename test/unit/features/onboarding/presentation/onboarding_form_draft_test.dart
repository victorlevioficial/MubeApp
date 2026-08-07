import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/onboarding/presentation/onboarding_form_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/firebase_test_config.dart';
import '../../../../helpers/test_fakes.dart';

class _FakeUser extends Fake implements firebase_auth.User {
  _FakeUser(this.uid);

  @override
  final String uid;
}

/// The onboarding draft is the user's half-finished signup. Losing it sends
/// them back to step 1, which in practice means they abandon the signup.
void main() {
  const storageKey = 'onboarding_form_state';

  setUpAll(() async {
    await setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  String draftFor(String uid, {String name = 'Rascunho Teste'}) {
    return json.encode({
      'uid': uid,
      'state': {'nome': name},
    });
  }

  Future<ProviderContainer> buildContainer(
    FakeAuthRepository authRepository,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        sharedPreferencesLoaderProvider.overrideWithValue(() async => prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('onboarding draft persistence', () {
    test(
      'keeps the draft when auth has not restored the session yet',
      () async {
        SharedPreferences.setMockInitialValues({
          storageKey: draftFor('user-1'),
        });
        // No current user yet: this is the state during app boot, before
        // Firebase Auth finishes restoring the signed-in session.
        final authRepository = FakeAuthRepository();
        final container = await buildContainer(authRepository);

        container.read(onboardingFormProvider);
        await Future<void>.delayed(const Duration(milliseconds: 300));

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(storageKey),
          isNotNull,
          reason: 'draft must survive an unresolved auth session',
        );
      },
    );

    test('restores the draft once auth resolves the same user', () async {
      SharedPreferences.setMockInitialValues({
        storageKey: draftFor('user-1', name: 'Maria Guitarrista'),
      });
      final authRepository = FakeAuthRepository(
        initialUser: _FakeUser('user-1'),
      );
      final container = await buildContainer(authRepository);

      container.read(onboardingFormProvider);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(container.read(onboardingFormProvider).nome, 'Maria Guitarrista');
    });

    test('discards a draft that belongs to a different account', () async {
      SharedPreferences.setMockInitialValues({
        storageKey: draftFor('someone-else'),
      });
      final authRepository = FakeAuthRepository(
        initialUser: _FakeUser('user-1'),
      );
      final container = await buildContainer(authRepository);

      container.read(onboardingFormProvider);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(storageKey), isNull);
      expect(container.read(onboardingFormProvider).nome, isNull);
    });
  });
}
