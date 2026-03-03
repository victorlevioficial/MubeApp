import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/bands/domain/band_activation_rules.dart';
import 'package:mube/src/features/profile/presentation/profile_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  Widget createSubject(AppUser user) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  testWidgets(
    'shows draft activation banner for band with less than 2 members',
    (tester) async {
      final user = TestData.bandUser().copyWith(
        tipoPerfil: AppUserType.band,
        status: profileDraftStatus,
        members: const ['member-1'],
      );
      fakeAuthRepository.appUser = user;

      await tester.pumpWidget(createSubject(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('rascunho'), findsOneWidget);
      expect(find.text('1 de 2 integrantes confirmados'), findsOneWidget);
      expect(find.text('Adicionar integrantes'), findsOneWidget);
    },
  );

  testWidgets(
    'does not show draft activation banner for active band with enough members',
    (tester) async {
      final user = TestData.bandUser().copyWith(
        tipoPerfil: AppUserType.band,
        status: profileActiveStatus,
        members: const ['member-1', 'member-2'],
      );
      fakeAuthRepository.appUser = user;

      await tester.pumpWidget(createSubject(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('rascunho'), findsNothing);
      expect(find.text('Adicionar integrantes'), findsNothing);
    },
  );

  testWidgets(
    'shows draft activation banner when active band falls below threshold',
    (tester) async {
      final user = TestData.bandUser().copyWith(
        tipoPerfil: AppUserType.band,
        status: profileActiveStatus,
        members: const ['member-1'],
      );
      fakeAuthRepository.appUser = user;

      await tester.pumpWidget(createSubject(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('rascunho'), findsOneWidget);
      expect(find.text('1 de 2 integrantes confirmados'), findsOneWidget);
    },
  );

  testWidgets('does not show draft activation banner for active professional', (
    tester,
  ) async {
    final user = TestData.user(
      tipoPerfil: AppUserType.professional,
      status: profileActiveStatus,
    );
    fakeAuthRepository.appUser = user;

    await tester.pumpWidget(createSubject(user));
    await tester.pumpAndSettle();

    expect(find.textContaining('rascunho'), findsNothing);
    expect(find.text('Adicionar integrantes'), findsNothing);
  });
}
