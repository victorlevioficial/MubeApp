import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/loading/app_skeleton.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/gigs/domain/application_status.dart';
import 'package:mube/src/features/gigs/domain/gig_application.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/gigs/presentation/screens/gig_applicants_screen.dart';

void main() {
  const gigId = 'gig-1';
  const applicantId = 'user-1';
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
  });
}
