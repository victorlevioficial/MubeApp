import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/profile/presentation/edit_profile/controllers/edit_profile_controller.dart';
import 'package:mube/src/features/profile/presentation/profile_controller.dart';

import '../../../../helpers/test_fakes.dart';

void main() {
  group('EditProfileController.saveProfile', () {
    late FakeAuthRepository fakeAuthRepository;
    late FakeAnalyticsService fakeAnalyticsService;
    late ProviderContainer container;

    const contractorUser = AppUser(
      uid: 'contractor-1',
      email: 'contractor@example.com',
      cadastroStatus: 'concluido',
      tipoPerfil: AppUserType.contractor,
      nome: 'Victor Levi',
      dadosContratante: <String, dynamic>{},
    );

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      fakeAuthRepository.appUser = contractorUser;
      fakeAnalyticsService = FakeAnalyticsService();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          analyticsServiceProvider.overrideWithValue(fakeAnalyticsService),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(contractorUser),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeAuthRepository.dispose();
    });

    Future<void> saveProfile({
      required String username,
      AppUser user = contractorUser,
    }) {
      return container
          .read(editProfileControllerProvider(user.uid).notifier)
          .saveProfile(
            user: user,
            nome: 'Victor Levi',
            bio: 'Bio nova',
            username: username,
            nomeArtistico: '',
            celular: '',
            dataNascimento: '',
            genero: '',
            instagram: '',
            musicLinks: const <String, String>{},
          );
    }

    test(
      'updates public username before saving the rest of the profile',
      () async {
        await saveProfile(username: 'mube.oficial');

        expect(fakeAuthRepository.lastUpdatedPublicUsername, 'mube.oficial');
        expect(fakeAuthRepository.lastUpdatedUser, isNotNull);
        expect(fakeAuthRepository.lastUpdatedUser!.nome, 'Victor Levi');
      },
    );

    test('throws when the username reservation fails', () async {
      fakeAuthRepository.shouldFailPublicUsernameUpdate = true;

      await expectLater(
        saveProfile(username: 'mube.oficial'),
        throwsA(
          isA<Object>().having(
            (error) => error.toString(),
            'message',
            contains('Esse @usuario ja esta em uso. Escolha outro.'),
          ),
        ),
      );

      expect(fakeAuthRepository.lastUpdatedUser, isNull);
    });

    test(
      'surfaces profile save errors after a successful username update',
      () async {
        fakeAuthRepository.shouldThrow = true;

        await expectLater(
          saveProfile(username: 'mube.oficial'),
          throwsA(
            isA<Object>().having(
              (error) => error.toString(),
              'message',
              contains('O @usuario foi atualizado'),
            ),
          ),
        );

        final profileState = container.read(profileControllerProvider);
        expect(profileState.hasError, true);
      },
    );
  });
}
