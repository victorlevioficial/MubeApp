import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/profile/domain/media_item.dart';
import 'package:mube/src/features/profile/presentation/edit_profile/controllers/edit_profile_controller.dart';
import 'package:mube/src/features/profile/presentation/profile_controller.dart';

import '../../../../helpers/test_fakes.dart';

void main() {
  group('EditProfileController.build', () {
    test('parses photo gallery variants from persisted profile data', () {
      const user = AppUser(
        uid: 'professional-1',
        email: 'professional@example.com',
        cadastroStatus: 'concluido',
        tipoPerfil: AppUserType.professional,
        nome: 'Professional',
        dadosProfissional: {
          'categorias': ['instrumentalist'],
          'instrumentos': ['Guitarra'],
          'generosMusicais': ['Rock'],
          'gallery': [
            {
              'id': 'photo-1',
              'url': 'https://cdn.example.com/full.webp',
              'thumbnailUrl': 'https://cdn.example.com/thumb.webp',
              'mediumUrl': 'https://cdn.example.com/medium.webp',
              'largeUrl': 'https://cdn.example.com/large.webp',
              'type': 'photo',
              'order': 0,
            },
          ],
        },
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          currentUserProfileProvider.overrideWithValue(
            const AsyncValue.data(user),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(editProfileControllerProvider(user.uid));
      final item = state.galleryItems.single;

      expect(item.type, MediaType.photo);
      expect(item.thumbnailUrl, 'https://cdn.example.com/thumb.webp');
      expect(item.mediumUrl, 'https://cdn.example.com/medium.webp');
      expect(item.largeUrl, 'https://cdn.example.com/large.webp');
      expect(item.previewUrl, 'https://cdn.example.com/thumb.webp');
      expect(item.viewerUrl, 'https://cdn.example.com/large.webp');
    });
  });

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
