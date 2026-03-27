import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mube/src/design_system/components/navigation/app_app_bar.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_application.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/gigs/presentation/screens/gigs_hub_screen.dart';

import '../../../../helpers/test_data.dart';

void main() {
  Widget createSubject() {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(TestData.user()),
        ),
        gigsStreamProvider.overrideWith((ref) => Stream.value(const <Gig>[])),
        myApplicationsProvider.overrideWith(
          (ref) => Stream.value(const <GigApplication>[]),
        ),
        myGigsStreamProvider.overrideWith((ref) => Stream.value(const <Gig>[])),
      ],
      child: const MaterialApp(home: GigsHubScreen()),
    );
  }

  testWidgets('renders compact header and switches between tabs', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppAppBar), matching: find.text('Gigs')),
      findsOneWidget,
    );
    expect(find.text('Feature Hub'), findsNothing);
    expect(find.text('Tudo sobre gigs em um so lugar'), findsNothing);
    expect(find.text('Tudo sobre gigs'), findsOneWidget);
    expect(find.byType(GNav), findsOneWidget);
    expect(find.text('Abertas'), findsOneWidget);
    expect(find.text('Candidaturas'), findsOneWidget);
    expect(find.text('Minhas'), findsOneWidget);
    expect(find.byTooltip('Filtros'), findsOneWidget);

    final nav = tester.widget<GNav>(find.byType(GNav));
    nav.onTabChange?.call(1);
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma candidatura ainda'), findsOneWidget);

    nav.onTabChange?.call(2);
    await tester.pumpAndSettle();

    expect(find.textContaining('publicou gigs'), findsOneWidget);
  });

  testWidgets(
    'refreshes my applications provider when candidaturas tab opens',
    (tester) async {
      var myApplicationsBuildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) => Stream.value(TestData.user()),
            ),
            gigsStreamProvider.overrideWith(
              (ref) => Stream.value(const <Gig>[]),
            ),
            myApplicationsProvider.overrideWith((ref) {
              myApplicationsBuildCount += 1;
              return Stream.value(const <GigApplication>[]);
            }),
            myGigsStreamProvider.overrideWith(
              (ref) => Stream.value(const <Gig>[]),
            ),
          ],
          child: const MaterialApp(home: GigsHubScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(myApplicationsBuildCount, 1);

      final nav = tester.widget<GNav>(find.byType(GNav));
      nav.onTabChange?.call(1);
      await tester.pump();
      await tester.pump();

      expect(myApplicationsBuildCount, greaterThan(1));
    },
  );
}
