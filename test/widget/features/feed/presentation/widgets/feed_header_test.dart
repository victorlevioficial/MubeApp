import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/data_display/user_avatar.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/bands/data/invites_repository.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_header.dart';
import 'package:mube/src/features/notifications/data/notification_repository.dart';
import 'package:mube/src/features/settings/domain/saved_address.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../../../helpers/test_data.dart';
import '../../../../../helpers/test_fakes.dart';

class FakeInvitesRepository extends Fake implements InvitesRepository {
  List<Map<String, dynamic>> incomingInvites = [];

  @override
  Stream<List<Map<String, dynamic>>> getIncomingInvites(String uid) {
    return Stream.value(incomingInvites);
  }
}

void main() {
  late FakeNotificationRepository fakeNotificationRepository;
  late FakeInvitesRepository fakeInvitesRepository;

  setUp(() {
    fakeNotificationRepository = FakeNotificationRepository();
    fakeInvitesRepository = FakeInvitesRepository();
  });

  SavedAddress primaryAddress({
    String id = 'address-1',
    String street = 'Rua Augusta',
    String neighborhood = 'Consolacao',
  }) {
    return SavedAddress(
      id: id,
      logradouro: street,
      numero: '1500',
      bairro: neighborhood,
      cidade: 'Sao Paulo',
      estado: 'SP',
      cep: '01310-100',
      lat: -23.56,
      lng: -46.65,
      isPrimary: true,
    );
  }

  AppUser buildProfessionalUser({
    bool complete = false,
    List<SavedAddress> addresses = const [],
  }) {
    final location = {
      'logradouro': 'Rua Augusta',
      'bairro': 'Consolacao',
      'cidade': 'Sao Paulo',
      'estado': 'SP',
      'lat': -23.56,
      'lng': -46.65,
    };

    return TestData.user(
      tipoPerfil: AppUserType.professional,
      nome: 'Victor Silva',
      foto: complete ? 'https://example.com/avatar.jpg' : null,
      location: location,
      bio: 'Musico de estudio',
    ).copyWith(
      addresses: addresses,
      dadosProfissional: complete
          ? {
              'nomeArtistico': 'Victor Groove',
              'celular': '11999999999',
              'dataNascimento': '1990-01-01',
              'genero': 'masculino',
              'gallery': [
                {'type': 'photo'},
                {'type': 'video'},
              ],
            }
          : const {},
    );
  }

  AppUser buildBandUser({required List<String> members}) {
    return TestData.bandUser().copyWith(
      tipoPerfil: AppUserType.band,
      nome: 'Banda Saturno',
      foto: 'https://example.com/band.jpg',
      bio: 'Rock alternativo',
      members: members,
      location: {
        'logradouro': 'Rua Augusta',
        'bairro': 'Consolacao',
        'cidade': 'Sao Paulo',
        'estado': 'SP',
        'lat': -23.56,
        'lng': -46.65,
      },
      addresses: [primaryAddress()],
      dadosBanda: {
        'nomeBanda': 'Banda Saturno',
        'generosMusicais': ['Rock'],
        'gallery': [
          {'type': 'photo'},
          {'type': 'video'},
        ],
      },
    );
  }

  Widget createSubject(AppUser user) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        notificationRepositoryProvider.overrideWithValue(
          fakeNotificationRepository,
        ),
        invitesRepositoryProvider.overrideWithValue(fakeInvitesRepository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CustomScrollView(slivers: [FeedHeader(currentUser: user)]),
        ),
      ),
    );
  }

  group('FeedHeader', () {
    testWidgets(
      'shows the first three missing requirements and hides extra ones',
      (tester) async {
        final user = buildProfessionalUser(addresses: [primaryAddress()]);

        await tester.pumpWidget(createSubject(user));
        await tester.pumpAndSettle();

        expect(find.text('Perfil individual'), findsOneWidget);
        expect(find.text('Seu Perfil'), findsOneWidget);
        expect(find.text('Foto de perfil'), findsOneWidget);
        expect(find.text('Nome artistico'), findsOneWidget);
        expect(find.text('Celular'), findsOneWidget);
        expect(find.text('Data de nascimento'), findsNothing);
        expect(find.textContaining('+'), findsWidgets);
      },
    );

    testWidgets('renders the header avatar without border', (tester) async {
      final user = buildProfessionalUser(
        complete: true,
        addresses: [primaryAddress()],
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject(user));
        await tester.pumpAndSettle();
      });

      final avatar = tester.widget<UserAvatar>(find.byType(UserAvatar).first);
      expect(avatar.showBorder, isFalse);
    });

    testWidgets('hides the profile card when the profile is complete', (
      tester,
    ) async {
      final user = buildProfessionalUser(
        complete: true,
        addresses: [primaryAddress()],
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject(user));
        await tester.pumpAndSettle();
      });

      expect(find.byKey(const Key('feed_header_profile_card')), findsNothing);
      expect(find.text('Seu Perfil'), findsNothing);
    });

    testWidgets('shows the current street and neighborhood in the header', (
      tester,
    ) async {
      final user = buildProfessionalUser(addresses: [primaryAddress()]);

      await tester.pumpWidget(createSubject(user));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('feed_header_address_row')), findsOneWidget);
      expect(find.text('Rua Augusta, Consolacao'), findsOneWidget);
    });

    testWidgets('shows compact alerts and allows expanding and hiding', (
      tester,
    ) async {
      final user = buildBandUser(members: const ['member-1']);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject(user));
        await tester.pumpAndSettle();
      });

      expect(find.text('Banda'), findsOneWidget);
      expect(
        find.byKey(const Key('feed_header_alerts_compact')),
        findsOneWidget,
      );
      expect(find.text('1 de 2 integrantes confirmados'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('feed_header_alerts_expand_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('feed_header_alerts_expanded')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('feed_header_alerts_compact_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('feed_header_alerts_hide_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('feed_header_alerts_hidden')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('feed_header_alerts_restore_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('feed_header_alerts_compact')),
        findsOneWidget,
      );
    });

    testWidgets('shows invite alert and opens the alert sheet on tap', (
      tester,
    ) async {
      final user = buildProfessionalUser(
        complete: true,
        addresses: [primaryAddress()],
      );
      fakeInvitesRepository.incomingInvites = [
        {'id': 'invite-1', 'status': 'pendente'},
      ];

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createSubject(user));
        await tester.pumpAndSettle();
      });

      expect(
        find.byKey(const Key('feed_header_alerts_compact')),
        findsOneWidget,
      );
      expect(find.text('1 convite pendente para banda'), findsOneWidget);

      await tester.tap(find.byKey(const Key('feed_header_alerts_compact')));
      await tester.pumpAndSettle();

      expect(find.text('Alertas da home'), findsOneWidget);
      expect(find.text('Ver convites'), findsOneWidget);
    });
  });
}
