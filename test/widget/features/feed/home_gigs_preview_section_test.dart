import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/loading/app_skeleton.dart';
import 'package:mube/src/features/feed/presentation/widgets/home_gigs_preview_section.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';

void main() {
  const gig = Gig(
    id: 'gig-1',
    title: 'Guitarrista para sessao',
    description: 'Projeto com repertorio pop rock e ensaio na semana.',
    gigType: GigType.recording,
    status: GigStatus.open,
    dateMode: GigDateMode.toBeArranged,
    locationType: GigLocationType.remote,
    genres: ['Pop', 'Rock'],
    requiredInstruments: ['Guitarra'],
    requiredCrewRoles: [],
    requiredStudioServices: [],
    slotsTotal: 1,
    slotsFilled: 0,
    compensationType: CompensationType.negotiable,
    creatorId: 'creator-1',
    applicantCount: 0,
  );

  Widget createSubject({
    required AsyncValue<List<Gig>> gigsAsync,
    VoidCallback? onSeeAllTap,
    ValueChanged<Gig>? onGigTap,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeGigsPreviewSection(
              gigsAsync: gigsAsync,
              onSeeAllTap: onSeeAllTap ?? () {},
              onGigTap: onGigTap ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('HomeGigsPreviewSection', () {
    testWidgets('shows skeleton while loading', (tester) async {
      await tester.pumpWidget(
        createSubject(gigsAsync: const AsyncLoading<List<Gig>>()),
      );

      expect(find.text('Gigs em aberto'), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('renders gigs and triggers callbacks', (tester) async {
      var seeAllTapped = false;
      Gig? tappedGig;

      await tester.pumpWidget(
        createSubject(
          gigsAsync: const AsyncData<List<Gig>>([gig]),
          onSeeAllTap: () => seeAllTapped = true,
          onGigTap: (value) => tappedGig = value,
        ),
      );

      expect(find.text('Guitarrista para sessao'), findsOneWidget);
      expect(find.text('A combinar'), findsOneWidget);
      expect(find.text('Remoto'), findsOneWidget);

      await tester.tap(find.text('Ver todos'));
      await tester.pump();
      expect(seeAllTapped, isTrue);

      await tester.tap(find.text('Guitarrista para sessao'));
      await tester.pump();
      expect(tappedGig, gig);
    });

    testWidgets('does not overflow on narrow mobile width', (tester) async {
      FlutterErrorDetails? flutterError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        flutterError = details;
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    child: HomeGigsPreviewSection(
                      gigsAsync: const AsyncData<List<Gig>>([gig]),
                      onSeeAllTap: () {},
                      onGigTap: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;
      expect(flutterError, isNull);
    });

    testWidgets('hides itself when there are no gigs', (tester) async {
      await tester.pumpWidget(
        createSubject(gigsAsync: const AsyncData<List<Gig>>([])),
      );

      expect(find.text('Gigs em aberto'), findsNothing);
      expect(find.byType(HomeGigPreviewCard), findsNothing);
    });
  });
}
