import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/constants/app_constants.dart' as app_constants;
import 'package:mube/src/core/domain/professional_roles.dart';
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

  group('EditProfileController.saveProfile - professional genre rules', () {
    late FakeAuthRepository fakeAuthRepository;
    late FakeAnalyticsService fakeAnalyticsService;
    late ProviderContainer container;

    const professionalUser = AppUser(
      uid: 'professional-genre-1',
      email: 'professional@example.com',
      cadastroStatus: 'concluido',
      tipoPerfil: AppUserType.professional,
      nome: 'Professional Genre User',
      matchpointProfile: {},
      privacySettings: {},
      blockedUsers: [],
      dadosProfissional: {},
    );

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      fakeAuthRepository.appUser = professionalUser;
      fakeAnalyticsService = FakeAnalyticsService();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          analyticsServiceProvider.overrideWithValue(fakeAnalyticsService),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(professionalUser),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeAuthRepository.dispose();
    });

    Future<void> saveProfile() {
      return container
          .read(editProfileControllerProvider(professionalUser.uid).notifier)
          .saveProfile(
            user: professionalUser,
            nome: 'Professional Genre User',
            bio: 'Bio nova',
            username: 'mube.oficial',
            nomeArtistico: 'Profissional',
            celular: '11999999999',
            dataNascimento: '1990-01-01',
            genero: 'Outro',
            instagram: '@profissional',
            musicLinks: const <String, String>{},
          );
    }

    test('drops genres for luthier-only profiles', () async {
      final controller = container.read(
        editProfileControllerProvider(professionalUser.uid).notifier,
      );

      controller.updateCategories(const ['luthier']);
      controller.updateRoles(['Ajuste e Regulagem']);
      controller.updateGenres(const ['rock']);

      await saveProfile();

      final updatedUser = fakeAuthRepository.lastUpdatedUser;
      expect(updatedUser, isNotNull);
      expect(updatedUser!.dadosProfissional?['categorias'], ['luthier']);
      expect(updatedUser.dadosProfissional?['generosMusicais'], isEmpty);
      expect(updatedUser.dadosProfissional?['funcoes'], isNotEmpty);
    });

    test('drops genres for audiovisual-only profiles', () async {
      final controller = container.read(
        editProfileControllerProvider(professionalUser.uid).notifier,
      );

      controller.updateCategories(const ['audiovisual']);
      controller.updateRoles(const ['audiovisual_direcao_de_video']);
      controller.updateGenres(const ['Rock']);

      await saveProfile();

      final updatedUser = fakeAuthRepository.lastUpdatedUser;
      expect(updatedUser, isNotNull);
      expect(updatedUser!.dadosProfissional?['categorias'], ['audiovisual']);
      expect(updatedUser.dadosProfissional?['generosMusicais'], isEmpty);
      expect(updatedUser.dadosProfissional?['funcoes'], isNotEmpty);
    });

    test('drops genres for education-only profiles', () async {
      final controller = container.read(
        editProfileControllerProvider(professionalUser.uid).notifier,
      );

      controller.updateCategories(const ['education']);
      controller.updateRoles(const ['education_coach_artistico']);
      controller.updateGenres(const ['Rock']);

      await saveProfile();

      final updatedUser = fakeAuthRepository.lastUpdatedUser;
      expect(updatedUser, isNotNull);
      expect(updatedUser!.dadosProfissional?['categorias'], ['education']);
      expect(updatedUser.dadosProfissional?['generosMusicais'], isEmpty);
      expect(updatedUser.dadosProfissional?['funcoes'], isNotEmpty);
    });

    test('keeps genres for performance profiles', () async {
      final controller = container.read(
        editProfileControllerProvider(professionalUser.uid).notifier,
      );

      controller.updateCategories(const ['performance']);
      controller.updateRoles([app_constants.performanceRoles.first]);
      controller.updateGenres(const ['rock']);

      await saveProfile();

      final updatedUser = fakeAuthRepository.lastUpdatedUser;
      expect(updatedUser, isNotNull);
      expect(updatedUser!.dadosProfissional?['categorias'], ['performance']);
      expect(updatedUser.dadosProfissional?['generosMusicais'], ['rock']);
      expect(updatedUser.dadosProfissional?['funcoes'], isNotEmpty);
    });

    test('keeps genres for mixed audiovisual + performance profiles', () async {
      final controller = container.read(
        editProfileControllerProvider(professionalUser.uid).notifier,
      );

      controller.updateCategories(const ['audiovisual', 'performance']);
      controller.updateRoles(const [
        'audiovisual_direcao_de_video',
        'performance_performer',
      ]);
      controller.updateGenres(const ['Rock']);

      await saveProfile();

      final updatedUser = fakeAuthRepository.lastUpdatedUser;
      expect(updatedUser, isNotNull);
      expect(updatedUser!.dadosProfissional?['categorias'], [
        'audiovisual',
        'performance',
      ]);
      expect(updatedUser.dadosProfissional?['generosMusicais'], ['Rock']);
      expect(updatedUser.dadosProfissional?['funcoes'], isNotEmpty);
    });
  });

  group('EditProfileController role management (API pública)', () {
    late FakeAuthRepository fakeAuthRepository;
    late FakeAnalyticsService fakeAnalyticsService;
    late ProviderContainer container;

    const professionalUser = AppUser(
      uid: 'professional-roles-1',
      email: 'professional@example.com',
      cadastroStatus: 'concluido',
      tipoPerfil: AppUserType.professional,
      nome: 'Professional Roles User',
      matchpointProfile: {},
      privacySettings: {},
      blockedUsers: [],
      dadosProfissional: {},
    );

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      fakeAuthRepository.appUser = professionalUser;
      fakeAnalyticsService = FakeAnalyticsService();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          analyticsServiceProvider.overrideWithValue(fakeAnalyticsService),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(professionalUser),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeAuthRepository.dispose();
    });

    test('updateCategories([]) prunes previously selected roles', () {
      final controller = container.read(
        editProfileControllerProvider(professionalUser.uid).notifier,
      );

      controller.updateCategories(const ['audiovisual']);
      controller.updateRoles(const [
        'audiovisual_direcao_de_video',
        'audiovisual_captacao_de_video',
      ]);

      expect(
        container
            .read(editProfileControllerProvider(professionalUser.uid))
            .selectedRoles,
        const ['audiovisual_direcao_de_video', 'audiovisual_captacao_de_video'],
      );

      controller.updateCategories(const <String>[]);

      final state = container.read(
        editProfileControllerProvider(professionalUser.uid),
      );
      expect(state.selectedCategories, isEmpty);
      expect(state.selectedRoles, isEmpty);
    });

    test('toggleRole normalizes a human label into a prefixed role id', () {
      final controller = container.read(
        editProfileControllerProvider(professionalUser.uid).notifier,
      );

      controller.toggleRole('Direção de Vídeo');

      final state = container.read(
        editProfileControllerProvider(professionalUser.uid),
      );
      expect(state.selectedRoles, contains('audiovisual_direcao_de_video'));
    });
  });

  group('EditProfileController.validate (AppUserType.professional)', () {
    late FakeAuthRepository fakeAuthRepository;
    late FakeAnalyticsService fakeAnalyticsService;
    late ProviderContainer container;

    const professionalUser = AppUser(
      uid: 'professional-validate-1',
      email: 'professional@example.com',
      cadastroStatus: 'concluido',
      tipoPerfil: AppUserType.professional,
      nome: 'Professional Validate User',
      matchpointProfile: {},
      privacySettings: {},
      blockedUsers: [],
      dadosProfissional: {},
    );

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      fakeAuthRepository.appUser = professionalUser;
      fakeAnalyticsService = FakeAnalyticsService();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          analyticsServiceProvider.overrideWithValue(fakeAnalyticsService),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(professionalUser),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeAuthRepository.dispose();
    });

    for (final categoryId in professionalRoleCategoriesWithSelectors) {
      test('fails when $categoryId is selected but no role is chosen', () {
        final controller = container.read(
          editProfileControllerProvider(professionalUser.uid).notifier,
        );

        controller.updateCategories(<String>[categoryId]);
        controller.updateRoles(const <String>[]);

        expect(controller.validate(AppUserType.professional), isFalse);
      });
    }

    test('passes when audiovisual category has a valid role and no genre', () {
      final controller = container.read(
        editProfileControllerProvider(professionalUser.uid).notifier,
      );

      controller.updateCategories(const ['audiovisual']);
      controller.updateRoles(const ['audiovisual_direcao_de_video']);
      controller.updateGenres(const <String>[]);

      expect(controller.validate(AppUserType.professional), isTrue);
    });
  });
}
