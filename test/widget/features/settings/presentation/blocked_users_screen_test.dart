import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/loading/app_loading_indicator.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'package:mube/src/features/settings/presentation/blocked_users_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  final authUser = FakeFirebaseUser(uid: 'current-user');
  final currentUser = TestData.user(
    uid: 'current-user',
  ).copyWith(blockedUsers: const []);
  const blockedUser = AppUser(
    uid: 'blocked-user',
    email: 'blocked@example.com',
    cadastroStatus: 'concluido',
    tipoPerfil: AppUserType.professional,
    foto: null,
    dadosProfissional: {'nomeArtistico': 'Pessoa Bloqueada'},
  );

  Widget createSubject({
    required Stream<firebase_auth.User?> authStream,
    required Stream<AppUser?> profileStream,
    required Stream<List<String>> blockedIdsStream,
  }) {
    return ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => authStream),
        currentUserProfileProvider.overrideWith((ref) => profileStream),
        blockedUsersProvider.overrideWith((ref) => blockedIdsStream),
        blockedUsersDetailsByKeyProvider(
          'blocked-user',
        ).overrideWith((ref) => Future.value([blockedUser])),
      ],
      child: const MaterialApp(home: BlockedUsersScreen()),
    );
  }

  testWidgets('shows loading state instead of login message while pending', (
    tester,
  ) async {
    final authController = StreamController<firebase_auth.User?>.broadcast();
    final profileController = StreamController<AppUser?>.broadcast();
    final blockedIdsController = StreamController<List<String>>.broadcast();
    addTearDown(authController.close);
    addTearDown(profileController.close);
    addTearDown(blockedIdsController.close);

    await tester.pumpWidget(
      createSubject(
        authStream: authController.stream,
        profileStream: profileController.stream,
        blockedIdsStream: blockedIdsController.stream,
      ),
    );
    await tester.pump();

    expect(find.byType(AppLoadingIndicator), findsOneWidget);
    expect(find.text('Faça login novamente.'), findsNothing);
  });

  testWidgets('renders blocked users once all dependencies are ready', (
    tester,
  ) async {
    await tester.pumpWidget(
      createSubject(
        authStream: Stream.value(authUser),
        profileStream: Stream.value(currentUser),
        blockedIdsStream: Stream.value(const ['blocked-user']),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(AppLoadingIndicator), findsNothing);
    expect(find.text('Pessoa Bloqueada'), findsOneWidget);
    expect(find.text('Faça login novamente.'), findsNothing);
  });
}
