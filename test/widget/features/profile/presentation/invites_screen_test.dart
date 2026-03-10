import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/loading/app_skeleton.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/bands/data/invites_repository.dart';
import 'package:mube/src/features/profile/presentation/invites_screen.dart';

import '../../../../helpers/test_data.dart';

class _DelayedInvitesRepository extends Fake implements InvitesRepository {
  final Completer<String> completer = Completer<String>();
  int respondCalls = 0;

  @override
  Future<String> respondToInvite({
    required String inviteId,
    required bool accept,
  }) {
    respondCalls += 1;
    return completer.future;
  }
}

void main() {
  final user = TestData.user(uid: 'user-1');
  final invite = <String, dynamic>{
    'id': 'invite-1',
    'band_name': 'Banda Central',
    'created_at': Timestamp.fromDate(DateTime(2026, 3, 10)),
  };
  final band = <String, dynamic>{
    'id': 'band-1',
    'banda': {'nomeBanda': 'Banda Central'},
  };

  Widget createSubject({
    required Stream<List<Map<String, dynamic>>> invitesStream,
    required Stream<List<Map<String, dynamic>>> bandsStream,
    InvitesRepository? repository,
  }) {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        invitesStreamProvider(user.uid).overrideWith((ref) => invitesStream),
        userBandsProvider(user.uid).overrideWith((ref) => bandsStream),
        if (repository != null)
          invitesRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: InvitesScreen()),
    );
  }

  testWidgets('waits for invites and bands before releasing the screen', (
    tester,
  ) async {
    final invitesController =
        StreamController<List<Map<String, dynamic>>>.broadcast();
    final bandsController =
        StreamController<List<Map<String, dynamic>>>.broadcast();
    addTearDown(invitesController.close);
    addTearDown(bandsController.close);

    await tester.pumpWidget(
      createSubject(
        invitesStream: invitesController.stream,
        bandsStream: bandsController.stream,
      ),
    );
    await tester.pump();

    expect(find.byType(UserListSkeleton), findsOneWidget);
    expect(find.text('Convites Pendentes (1)'), findsNothing);
    expect(find.text('Minhas Bandas (1)'), findsNothing);

    invitesController.add([invite]);
    await tester.pump();

    expect(find.byType(UserListSkeleton), findsOneWidget);
    expect(find.text('Convites Pendentes (1)'), findsNothing);

    bandsController.add([band]);
    await tester.pump();
    await tester.pump();

    expect(find.byType(UserListSkeleton), findsNothing);
    expect(find.text('Convites Pendentes (1)'), findsOneWidget);
    expect(find.text('Minhas Bandas (1)'), findsOneWidget);
    expect(find.text('Convite para: Banda Central'), findsOneWidget);
  });

  testWidgets('disables double tap and shows loading while responding', (
    tester,
  ) async {
    final repository = _DelayedInvitesRepository();

    await tester.pumpWidget(
      createSubject(
        invitesStream: Stream.value([invite]),
        bandsStream: Stream.value(const []),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar'));
    await tester.pump();

    expect(repository.respondCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Aceitar'), warnIfMissed: false);
    await tester.pump();

    expect(repository.respondCalls, 1);

    repository.completer.complete('Convite aceito');
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
