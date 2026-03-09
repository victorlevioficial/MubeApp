import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/loading/app_skeleton.dart';
import 'package:mube/src/features/gigs/domain/application_status.dart';
import 'package:mube/src/features/gigs/domain/gig_application.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/gigs/presentation/screens/my_applications_screen.dart';

void main() {
  const application = GigApplication(
    id: 'application-1',
    gigId: 'gig-1',
    applicantId: 'user-1',
    message: 'Tenho disponibilidade completa.',
    status: ApplicationStatus.accepted,
    gigTitle: 'Festival Indie',
    gigType: GigType.liveShow,
    gigStatus: GigStatus.open,
    creatorId: 'creator-1',
  );

  Widget createSubject(Stream<List<GigApplication>> applicationsStream) {
    return ProviderScope(
      overrides: [
        myApplicationsProvider.overrideWith((ref) => applicationsStream),
      ],
      child: const MaterialApp(home: MyApplicationsScreen()),
    );
  }

  testWidgets('renders skeleton while applications are loading', (
    tester,
  ) async {
    final controller = StreamController<List<GigApplication>>();
    addTearDown(controller.close);

    await tester.pumpWidget(createSubject(controller.stream));
    await tester.pump();

    expect(find.byType(SkeletonShimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders the applications list when data is available', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject(Stream.value(const [application])));
    await tester.pumpAndSettle();

    expect(find.text('Festival Indie'), findsOneWidget);
    expect(find.text('Aceita'), findsOneWidget);
    expect(find.text('Tenho disponibilidade completa.'), findsOneWidget);
    expect(find.text('Ver gig'), findsOneWidget);
    expect(find.text('Mensagem'), findsOneWidget);
    expect(find.text('Desistir da gig'), findsOneWidget);
  });
}
