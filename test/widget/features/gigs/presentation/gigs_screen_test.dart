import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mube/src/design_system/components/loading/app_skeleton.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/gigs/presentation/screens/gigs_screen.dart';

import '../../../../helpers/test_data.dart';

void main() {
  const sampleGig = Gig(
    id: 'gig-1',
    title: 'Procuro baterista',
    description: 'Show de pop rock no sabado a noite em Sao Paulo.',
    gigType: GigType.liveShow,
    status: GigStatus.open,
    dateMode: GigDateMode.fixedDate,
    gigDate: null,
    locationType: GigLocationType.onsite,
    slotsTotal: 2,
    compensationType: CompensationType.negotiable,
    creatorId: 'creator-1',
  );

  Widget createSubject(Stream<List<Gig>> gigsStream) {
    return ProviderScope(
      overrides: [
        gigsStreamProvider.overrideWith((ref) => gigsStream),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(TestData.user()),
        ),
      ],
      child: const MaterialApp(home: GigsScreen()),
    );
  }

  testWidgets('renders skeleton while gigs are loading', (tester) async {
    final controller = StreamController<List<Gig>>();
    addTearDown(controller.close);

    await tester.pumpWidget(createSubject(controller.stream));
    await tester.pump();

    expect(find.byType(SkeletonShimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders empty state when there are no gigs', (tester) async {
    await tester.pumpWidget(createSubject(Stream.value(const [])));
    await tester.pump();

    expect(find.text('Nenhuma gig encontrada'), findsOneWidget);
    expect(find.text('Criar gig'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('renders extended fab when gigs are available', (tester) async {
    await tester.pumpWidget(createSubject(Stream.value(const [sampleGig])));
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Nova gig'), findsOneWidget);
  });
}
