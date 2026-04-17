import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/bands/domain/band_activation_rules.dart';

import '../../helpers/firebase_mocks.dart';

class _FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

class _FakeAppCheck extends Fake implements app_check.FirebaseAppCheck {
  @override
  Future<String?> getToken([bool? forceRefresh]) async => 'app-check-token';
}

void main() {
  group('AuthRemoteDataSourceImpl.completeOnboardingProfile', () {
    late FakeFirebaseFirestore firestore;
    late AuthRemoteDataSourceImpl dataSource;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      dataSource = AuthRemoteDataSourceImpl(
        MockFirebaseAuth(),
        firestore,
        functions: _FakeFirebaseFunctions(),
        publicUsernameFunctions: _FakeFirebaseFunctions(),
        appCheck: _FakeAppCheck(),
      );
    });

    Future<DocumentSnapshot<Map<String, dynamic>>> readUserDoc(
      String uid,
    ) async {
      return firestore.collection(FirestoreCollections.users).doc(uid).get();
    }

    test('persists status="rascunho" for band onboarding completion', () async {
      const uid = 'band-1';
      // Seed the existing perfil_pendente document.
      await firestore.collection(FirestoreCollections.users).doc(uid).set({
        'uid': uid,
        'email': 'banda@example.com',
        'cadastro_status': RegistrationStatus.profilePending,
        'tipo_perfil': AppUserType.band.id,
        'status': AccountStatus.active,
      });

      const user = AppUser(
        uid: uid,
        email: 'banda@example.com',
        nome: 'Minha Banda',
        cadastroStatus: RegistrationStatus.complete,
        tipoPerfil: AppUserType.band,
        status: profileDraftStatus,
      );

      await dataSource.completeOnboardingProfile(user);

      final stored = (await readUserDoc(uid)).data()!;
      expect(stored['cadastro_status'], RegistrationStatus.complete);
      expect(stored['status'], profileDraftStatus);
    });

    test(
      'persists status="ativo" for non-band onboarding completion',
      () async {
        const uid = 'pro-1';
        await firestore.collection(FirestoreCollections.users).doc(uid).set({
          'uid': uid,
          'email': 'pro@example.com',
          'cadastro_status': RegistrationStatus.profilePending,
          'tipo_perfil': AppUserType.professional.id,
          'status': AccountStatus.active,
        });

        const user = AppUser(
          uid: uid,
          email: 'pro@example.com',
          nome: 'Pro Test',
          cadastroStatus: RegistrationStatus.complete,
          tipoPerfil: AppUserType.professional,
          status: profileActiveStatus,
        );

        await dataSource.completeOnboardingProfile(user);

        final stored = (await readUserDoc(uid)).data()!;
        expect(stored['cadastro_status'], RegistrationStatus.complete);
        expect(stored['status'], profileActiveStatus);
      },
    );

    test('updateUserProfile keeps the existing status untouched', () async {
      const uid = 'pro-2';
      await firestore.collection(FirestoreCollections.users).doc(uid).set({
        'uid': uid,
        'email': 'pro2@example.com',
        'cadastro_status': RegistrationStatus.complete,
        'tipo_perfil': AppUserType.professional.id,
        'status': AccountStatus.active,
      });

      const user = AppUser(
        uid: uid,
        email: 'pro2@example.com',
        nome: 'Pro Two',
        cadastroStatus: RegistrationStatus.complete,
        tipoPerfil: AppUserType.professional,
        // Try to escalate to draft via the regular update API.
        status: profileDraftStatus,
      );

      await dataSource.updateUserProfile(user);

      final stored = (await readUserDoc(uid)).data()!;
      // updateUserProfile must drop the status field client-side, so
      // the previously stored 'ativo' value remains in place.
      expect(stored['status'], AccountStatus.active);
    });
  });
}
