import 'dart:async';

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
  const creatorUser = AppUser(
    uid: creatorId,
    email: 'creator@mube.com',
    cadastroStatus: 'concluido',
    tipoPerfil: AppUserType.contractor,
    dadosContratante: {'nomeExibicao': 'Casa Aurora'},
  );
  const candidateUser = AppUser(
    uid: candidateId,
    email: 'candidate@mube.com',
    cadastroStatus: 'concluido',
    tipoPerfil: AppUserType.professional,
    dadosProfissional: {'nomeArtistico': 'Lia Vox'},
  );

  Widget createSubject({
    required Stream<Gig?> gigStream,
    required Stream<List<GigApplication>> applicationsStream,
    required Stream<AppUser?> userStream,
    Future<AppConfig> Function()? appConfigLoader,
  }) {
    return ProviderScope(
      overrides: [
        gigDetailProvider(gigId).overrideWith((ref) => gigStream),
        myApplicationsProvider.overrideWith((ref) => applicationsStream),
        currentUserProfileProvider.overrideWith((ref) => userStream),
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
        applicationsStream: Stream.value(const []),
        userStream: Stream.value(candidateUser),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7 pessoas ja se candidataram.'), findsOneWidget);
    expect(find.text('Candidatar-se'), findsOneWidget);
  });

  testWidgets('shows dynamic applicants label for creators', (tester) async {
    await tester.pumpWidget(
      createSubject(
        gigStream: Stream.value(sampleGig),
        applicationsStream: Stream.value(const []),
        userStream: Stream.value(creatorUser),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver 7 candidaturas'), findsOneWidget);
    expect(find.text('Candidatar-se'), findsNothing);
  });

  testWidgets('shows skeleton while action dependencies are loading', (
    tester,
  ) async {
    final applicationsController = StreamController<List<GigApplication>>();
    addTearDown(applicationsController.close);

    await tester.pumpWidget(
      createSubject(
        gigStream: Stream.value(sampleGig),
        applicationsStream: applicationsController.stream,
        userStream: Stream.value(candidateUser),
      ),
    );
    await tester.pump();

    expect(find.byType(SkeletonShimmer), findsWidgets);
    expect(find.text('Candidatar-se'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
