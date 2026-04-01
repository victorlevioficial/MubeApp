import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/providers/app_config_provider.dart';
import 'package:mube/src/design_system/components/loading/app_skeleton.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_application.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/gigs/presentation/screens/gig_detail_screen.dart';

import '../../../../helpers/test_fakes.dart';

void main() {
  const gigId = 'gig-1';
  const creatorId = 'creator-1';
  const candidateId = 'candidate-1';
  const sampleGig = Gig(
    id: gigId,
    title: 'Procuro guitarrista',
    description: 'Show autoral em Sao Paulo.',
    gigType: GigType.liveShow,
    status: GigStatus.open,
    dateMode: GigDateMode.fixedDate,
    locationType: GigLocationType.onsite,
    slotsTotal: 2,
    compensationType: CompensationType.negotiable,
    creatorId: creatorId,
    applicantCount: 7,
  );
  final creatorAuthUser = FakeFirebaseUser(
    uid: creatorId,
    email: 'creator@mube.com',
  );
  final candidateAuthUser = FakeFirebaseUser(
    uid: candidateId,
    email: 'candidate@mube.com',
  );

  Widget createSubject({
    required Stream<Gig?> gigStream,
    required Stream<GigApplication?> myApplicationStream,
    required Stream<firebase_auth.User?> authUserStream,
    Future<AppConfig> Function()? appConfigLoader,
  }) {
    final creatorIdsKey = encodeGigUserIdsKey([creatorId]);
    final creatorsById = <String, AppUser>{
      creatorId: const AppUser(
        uid: creatorId,
        email: 'creator@mube.com',
        cadastroStatus: 'concluido',
        tipoPerfil: AppUserType.contractor,
        dadosContratante: {'nomeExibicao': 'Produtora Aurora'},
      ),
    };

    return ProviderScope(
      overrides: [
        gigDetailProvider(gigId).overrideWith((ref) => gigStream),
        myGigApplicationProvider(
          gigId,
        ).overrideWith((ref) => myApplicationStream),
        gigUsersByStableIdsProvider(
          creatorIdsKey,
        ).overrideWith((ref) => Future.value(creatorsById)),
        authStateChangesProvider.overrideWith((ref) => authUserStream),
        appConfigProvider.overrideWith(
          (ref) => appConfigLoader?.call() ?? Future.value(const AppConfig()),
        ),
      ],
      child: const MaterialApp(home: GigDetailScreen(gigId: gigId)),
    );
  }

  testWidgets('shows social proof for candidates', (tester) async {
    await tester.pumpWidget(
      createSubject(
        gigStream: Stream.value(sampleGig),
        myApplicationStream: Stream.value(null),
        authUserStream: Stream.value(candidateAuthUser),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Produtora Aurora'), findsOneWidget);
    expect(find.text('Contratante'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    await tester.scrollUntilVisible(find.text('Candidatar-se'), 300);
    await tester.pumpAndSettle();
    expect(find.text('7 pessoas ja se candidataram.'), findsOneWidget);
    expect(find.text('Candidatar-se'), findsOneWidget);
  });

  testWidgets('shows refreshed apply dialog UI', (tester) async {
    await tester.pumpWidget(
      createSubject(
        gigStream: Stream.value(sampleGig),
        myApplicationStream: Stream.value(null),
        authUserStream: Stream.value(candidateAuthUser),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Candidatar-se'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Candidatar-se'));
    await tester.pumpAndSettle();

    expect(find.text('Candidatura rápida'), findsOneWidget);
    expect(find.text('Vale incluir'), findsOneWidget);
    expect(find.text('Mensagem para o contratante'), findsOneWidget);
    expect(
      find.text(
        'Sua candidatura vai aparecer em Minhas candidaturas assim que for enviada.',
      ),
      findsOneWidget,
    );
    expect(find.text('Experiência'), findsOneWidget);
    expect(find.text('Disponibilidade'), findsOneWidget);
    expect(find.text('Repertório'), findsOneWidget);
  });

  testWidgets('shows dynamic applicants label for creators', (tester) async {
    await tester.pumpWidget(
      createSubject(
        gigStream: Stream.value(sampleGig),
        myApplicationStream: Stream.value(null),
        authUserStream: Stream.value(creatorAuthUser),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Ver 7 candidaturas'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Ver 7 candidaturas'), findsOneWidget);
    expect(find.text('Candidatar-se'), findsNothing);
  });

  testWidgets('shows skeleton while action dependencies are loading', (
    tester,
  ) async {
    final pendingApplication = Completer<GigApplication?>();

    await tester.pumpWidget(
      createSubject(
        gigStream: Stream.value(sampleGig),
        myApplicationStream: Stream.fromFuture(pendingApplication.future),
        authUserStream: Stream.value(candidateAuthUser),
      ),
    );
    await tester.pump();

    expect(find.byType(SkeletonShimmer), findsWidgets);
    expect(find.text('Candidatar-se'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'shows creator actions without waiting for my applications stream',
    (tester) async {
      final pendingApplication = Completer<GigApplication?>();

      await tester.pumpWidget(
        createSubject(
          gigStream: Stream.value(sampleGig),
          myApplicationStream: Stream.fromFuture(pendingApplication.future),
          authUserStream: Stream.value(creatorAuthUser),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(find.text('Ver 7 candidaturas'), 300);
      await tester.pumpAndSettle();
      expect(find.text('Ver 7 candidaturas'), findsOneWidget);
      expect(find.text('Editar descricao'), findsOneWidget);
      expect(find.text('Candidatar-se'), findsNothing);
    },
  );
}
