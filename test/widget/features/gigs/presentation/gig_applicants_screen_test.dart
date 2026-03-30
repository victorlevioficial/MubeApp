import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/loading/app_skeleton.dart';
import 'package:mube/src/design_system/foundations/tokens/app_spacing.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/gigs/domain/application_status.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_application.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/gigs/presentation/screens/gig_applicants_screen.dart';

import '../../../../helpers/test_fakes.dart';

void main() {
  const gigId = 'gig-1';
  const applicantId = 'user-1';
  const creatorId = 'creator-1';
  const application = GigApplication(
    id: applicantId,
    gigId: gigId,
    applicantId: applicantId,
    message: 'Tenho backline proprio.',
    status: ApplicationStatus.pending,
  );
  const applicant = AppUser(
    uid: applicantId,
    email: 'ana@mube.com',
    cadastroStatus: 'concluido',
    tipoPerfil: AppUserType.professional,
    dadosProfissional: {'nomeArtistico': 'Ana Guitar'},
  );
  final gig = Gig(
    id: gigId,
    title: 'Procuro baterista para festival',
    description: 'Show de 90 minutos com repertorio pop rock autoral.',
    gigType: GigType.liveShow,
    status: GigStatus.open,
    dateMode: GigDateMode.fixedDate,
    gigDate: DateTime(2026, 4, 12, 20),
    locationType: GigLocationType.onsite,
    location: const {'label': 'Sao Paulo, SP'},
    genres: const ['Pop Rock'],
    requiredInstruments: const ['Bateria'],
    requiredCrewRoles: const [],
    requiredStudioServices: const [],
    slotsTotal: 1,
    slotsFilled: 0,
    compensationType: CompensationType.fixed,
    compensationValue: 500,
    creatorId: creatorId,
    applicantCount: 1,
  );

  Widget createSubject({required dynamic overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: GigApplicantsScreen(gigId: gigId)),
    );
  }

  testWidgets('renders skeleton while applications are loading', (
    tester,
  ) async {
    final controller = StreamController<List<GigApplication>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      createSubject(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(FakeFirebaseUser(uid: creatorId)),
          ),
          gigDetailProvider(gigId).overrideWith((ref) => Stream.value(gig)),
          gigApplicationsProvider(
            gigId,
          ).overrideWith((ref) => controller.stream),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(SkeletonShimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders the applicants list when users are loaded', (
    tester,
  ) async {
    final usersKey = encodeGigUserIdsKey([applicantId]);

    await tester.pumpWidget(
      createSubject(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(FakeFirebaseUser(uid: creatorId)),
          ),
          gigDetailProvider(gigId).overrideWith((ref) => Stream.value(gig)),
          gigApplicationsProvider(
            gigId,
          ).overrideWith((ref) => Stream.value(const [application])),
          gigUsersByStableIdsProvider(
            usersKey,
          ).overrideWith((ref) => {applicantId: applicant}),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Guitar'), findsOneWidget);
    expect(find.text('Tenho backline proprio.'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding! as EdgeInsets;
    expect(padding.bottom, greaterThan(AppSpacing.s24));
  });

  testWidgets('shows friendly state when current user is not the gig creator', (
    tester,
  ) async {
    await tester.pumpWidget(
      createSubject(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(FakeFirebaseUser(uid: 'other-user')),
          ),
          gigDetailProvider(gigId).overrideWith((ref) => Stream.value(gig)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acesso indisponivel'), findsOneWidget);
    expect(
      find.text('Apenas o criador da gig pode ver as candidaturas.'),
      findsOneWidget,
    );
    expect(find.text('Voltar'), findsOneWidget);
  });
}
