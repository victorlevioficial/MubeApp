import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/bands/domain/band_activation_rules.dart';
import 'package:mube/src/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mube/src/features/onboarding/presentation/onboarding_form_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeAuthRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeAuthRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('OnboardingController', () {
    test('initial state is AsyncData(null)', () {
      final controller = container.read(onboardingControllerProvider);
      expect(controller, const AsyncData<void>(null));
    });

    group('selectProfileType', () {
      test('updates user profile type and status to perfil_pendente', () async {
        final user = TestData.pendingUser(uid: 'user-1');
        // Setup initial user in repository
        fakeAuthRepository.appUser = user;

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );

        await controller.selectProfileType(
          selectedType: 'profissional',
          currentUser: user,
        );

        // Verify repository was updated
        final updatedUser = fakeAuthRepository.lastUpdatedUser;
        expect(updatedUser, isNotNull);
        expect(updatedUser!.tipoPerfil, AppUserType.professional);
        expect(updatedUser.cadastroStatus, 'perfil_pendente');

        // Verify state is AsyncData (success)
        expect(
          container.read(onboardingControllerProvider),
          const AsyncData<void>(null),
        );
      });

      test('sets state to AsyncError on failure', () async {
        final user = TestData.pendingUser(uid: 'user-1');
        fakeAuthRepository.shouldThrow = true;

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );

        await controller.selectProfileType(
          selectedType: 'profissional',
          currentUser: user,
        );

        // Verify state is AsyncError
        expect(container.read(onboardingControllerProvider), isA<AsyncError>());
      });
    });

    group('resetToTypeSelection', () {
      test('resets profile type and sets status to tipo_pendente', () async {
        final user = TestData.user(
          uid: 'user-1',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'perfil_pendente',
        );
        fakeAuthRepository.appUser = user;

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );

        await controller.resetToTypeSelection(currentUser: user);

        final updatedUser = fakeAuthRepository.lastUpdatedUser;
        expect(updatedUser, isNotNull);
        expect(updatedUser!.tipoPerfil, null);
        expect(updatedUser.cadastroStatus, 'tipo_pendente');
      });
    });

    group('submitProfileForm', () {
      test(
        'updates user with form data and sets status to concluido',
        () async {
          final user = TestData.user(
            uid: 'user-1',
            tipoPerfil: AppUserType.professional,
            cadastroStatus: 'perfil_pendente',
          );
          fakeAuthRepository.appUser = user;

          final controller = container.read(
            onboardingControllerProvider.notifier,
          );

          final location = {
            'cidade': 'Rio de Janeiro',
            'estado': 'RJ',
            'lat': -22.9068,
            'lng': -43.1729,
          };

          final professionalData = {
            'nomeArtistico': 'DJ Test',
            'funcoes': ['DJ'],
          };

          await controller.submitProfileForm(
            currentUser: user,
            location: location,
            nome: 'New Name',
            foto: 'http://new.photo',
            dadosProfissional: professionalData,
          );

          final updatedUser = fakeAuthRepository.lastUpdatedUser;
          expect(updatedUser, isNotNull);
          expect(updatedUser!.cadastroStatus, 'concluido');
          expect(updatedUser.status, profileActiveStatus);
          expect(
            fakeAuthRepository.lastCompletedOnboardingUser,
            same(updatedUser),
            reason:
                'submitProfileForm must go through completeOnboardingProfile '
                'so that the account status reaches Firestore.',
          );
          expect(updatedUser.nome, 'New Name');
          expect(updatedUser.foto, 'http://new.photo');
          expect(updatedUser.location, location);
          expect(updatedUser.addresses, hasLength(1));
          expect(updatedUser.addresses.first.isPrimary, isTrue);
          expect(updatedUser.addresses.first.cidade, 'Rio de Janeiro');
          expect(updatedUser.addresses.first.estado, 'RJ');
          expect(updatedUser.dadosProfissional, professionalData);
        },
      );

      test(
        'creates band profile as rascunho until enough members accept',
        () async {
          final user = TestData.user(
            uid: 'band-1',
            tipoPerfil: AppUserType.band,
            cadastroStatus: 'perfil_pendente',
          );
          fakeAuthRepository.appUser = user;

          final controller = container.read(
            onboardingControllerProvider.notifier,
          );

          await controller.submitProfileForm(
            currentUser: user,
            location: const {'lat': 0.0, 'lng': 0.0},
            nome: 'Minha Banda',
            dadosBanda: const {'nomeBanda': 'Minha Banda'},
          );

          final updatedUser = fakeAuthRepository.lastUpdatedUser;
          expect(updatedUser, isNotNull);
          expect(updatedUser!.cadastroStatus, 'concluido');
          expect(updatedUser.status, profileDraftStatus);
          expect(
            fakeAuthRepository.lastCompletedOnboardingUser,
            same(updatedUser),
            reason: 'band onboarding must use completeOnboardingProfile '
                'so the rascunho status survives the data-source layer.',
          );
        },
      );

      test('preserves existing photo when no new photo is provided', () async {
        final user = TestData.user(
          uid: 'user-1',
          tipoPerfil: AppUserType.professional,
          cadastroStatus: 'perfil_pendente',
          foto: 'https://example.com/social-avatar.jpg',
        );
        fakeAuthRepository.appUser = user;

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );

        await controller.submitProfileForm(
          currentUser: user,
          location: const {
            'cidade': 'Sao Paulo',
            'estado': 'SP',
            'lat': -23.5,
            'lng': -46.6,
          },
          nome: 'Nome Teste',
          dadosProfissional: const {'nomeArtistico': 'Teste'},
        );

        final updatedUser = fakeAuthRepository.lastUpdatedUser;
        expect(updatedUser, isNotNull);
        expect(updatedUser!.foto, 'https://example.com/social-avatar.jpg');
      });

      test(
        'clears persisted onboarding draft after successful submit',
        () async {
          final user = TestData.user(
            uid: 'user-1',
            tipoPerfil: AppUserType.professional,
            cadastroStatus: 'perfil_pendente',
          );
          fakeAuthRepository.emitUser(FakeFirebaseUser(uid: 'user-1'));
          fakeAuthRepository.appUser = user;

          final draftNotifier = container.read(onboardingFormProvider.notifier);
          draftNotifier
            ..updateNome('Draft Name')
            ..updateGenero('Masculino');
          await Future<void>.delayed(const Duration(milliseconds: 400));

          final controller = container.read(
            onboardingControllerProvider.notifier,
          );
          await controller.submitProfileForm(
            currentUser: user,
            location: const {
              'cidade': 'Rio de Janeiro',
              'estado': 'RJ',
              'lat': -22.9,
              'lng': -43.1,
            },
            nome: 'Nome Final',
            dadosProfissional: const {'nomeArtistico': 'Final'},
          );

          expect(
            container.read(onboardingFormProvider),
            const OnboardingFormState(),
          );
        },
      );

      test('sets state to AsyncError on failure', () async {
        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.shouldThrow = true;

        final controller = container.read(
          onboardingControllerProvider.notifier,
        );

        // Required params
        final location = {'lat': 0.0, 'lng': 0.0};

        await controller.submitProfileForm(
          currentUser: user,
          location: location,
          nome: 'Test',
        );

        expect(container.read(onboardingControllerProvider), isA<AsyncError>());
      });
    });
  });
}
