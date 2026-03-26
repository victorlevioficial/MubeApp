import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/profile/presentation/public_profile_controller.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  ProviderContainer buildContainer({required AppUser? currentUser}) {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(currentUser),
        ),
      ],
    );
  }

  AppUser buildContractor({
    required String uid,
    required bool isPublic,
    String? foto,
  }) {
    return TestData.user(
      uid: uid,
      nome: 'Event Organizer',
      tipoPerfil: AppUserType.contractor,
      foto: foto,
    ).copyWith(
      dadosContratante: {
        'nomeExibicao': 'Casa Azul',
        'bio': 'Espaco para shows e eventos.',
        'gallery': [
          {
            'id': 'media-1',
            'url': 'https://example.com/gallery.jpg',
            'type': 'photo',
            'order': 0,
          },
        ],
        'isPublic': isPublic,
        'venueType': 'bar',
        'comodidades': ['stage', 'sound_system'],
      },
    );
  }

  group('PublicProfileController', () {
    test('allows third-party access to a public contractor profile', () async {
      final contractor = buildContractor(
        uid: 'contractor-public',
        isPublic: true,
        foto: 'https://example.com/avatar.jpg',
      );
      final viewer = TestData.user(uid: 'viewer-1');
      fakeAuthRepository.appUser = contractor;
      final container = buildContainer(currentUser: viewer);
      addTearDown(container.dispose);

      await primeCurrentUser(container);
      final state = await container.read(
        publicProfileControllerProvider(contractor.uid).future,
      );

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.user?.uid, contractor.uid);
      expect(state.galleryItems, hasLength(1));
      expect(state.galleryItems.first.id, 'media-1');
    });

    test('blocks third-party access to a private contractor profile', () async {
      final contractor = buildContractor(
        uid: 'contractor-private',
        isPublic: false,
        foto: 'https://example.com/avatar.jpg',
      );
      final viewer = TestData.user(uid: 'viewer-1');
      fakeAuthRepository.appUser = contractor;
      final container = buildContainer(currentUser: viewer);
      addTearDown(container.dispose);

      await primeCurrentUser(container);
      final state = await container.read(
        publicProfileControllerProvider(contractor.uid).future,
      );

      expect(state.isLoading, isFalse);
      expect(state.user, isNull);
      expect(state.error, contains('Perfil n\u00E3o encontrado'));
    });

    test('allows the owner to open a private contractor profile', () async {
      final contractor = buildContractor(
        uid: 'contractor-owner',
        isPublic: false,
        foto: 'https://example.com/avatar.jpg',
      );
      fakeAuthRepository.appUser = contractor;
      final container = buildContainer(currentUser: contractor);
      addTearDown(container.dispose);

      await primeCurrentUser(container);
      final state = await container.read(
        publicProfileControllerProvider(contractor.uid).future,
      );

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.user?.uid, contractor.uid);
    });
  });
}

Future<void> primeCurrentUser(ProviderContainer container) async {
  final completer = Completer<void>();
  final subscription = container.listen(currentUserProfileProvider, (
    previous,
    next,
  ) {
    if (next.hasValue && next.value != null && !completer.isCompleted) {
      completer.complete();
    }
  }, fireImmediately: true);

  await completer.future.timeout(const Duration(seconds: 1));
  subscription.close();
}
