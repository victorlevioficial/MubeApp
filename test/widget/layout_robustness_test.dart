import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/l10n/generated/app_localizations.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/login_screen.dart';
import 'package:mube/src/features/auth/presentation/register_screen.dart';
import 'package:mube/src/features/legal/presentation/legal_detail_screen.dart';

import '../helpers/test_data.dart';
import '../helpers/test_fakes.dart';

/// Renders key screens under the smallest phone size and the largest font
/// scale Android/iOS accessibility settings allow, and fails on any layout
/// overflow. Regular widget tests always run at 800x600 with scale 1.0, so
/// these breakages only show up on real users' devices.
void main() {
  const surfaces = <String, Size>{
    'phone_small_320x568': Size(320, 568),
    'phone_regular_411x891': Size(411, 891),
    'tablet_768x1024': Size(768, 1024),
  };

  const textScales = <double>[1.0, 1.3, 1.6];

  late FakeAuthRepository fakeAuthRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
  });

  Widget wrap(Widget screen, {double textScale = 1.0}) {
    final user = TestData.user(uid: 'user-1');
    fakeAuthRepo.appUser = user;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => screen),
        GoRoute(
          path: '/:any',
          builder: (context, state) => const Scaffold(body: Text('stub')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
  }

  Future<List<String>> renderAndCollectOverflows(
    WidgetTester tester,
    Widget screen, {
    required Size surface,
    required double textScale,
  }) async {
    final overflows = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exception.toString();
      if (message.contains('overflowed')) {
        // Keep the offending widget's description: the bare message says how
        // many pixels overflowed but never which Row caused it.
        final culprit = details.context?.toDescription() ?? '';
        overflows.add(
          '${message.split('\n').first}${culprit.isEmpty ? '' : ' [$culprit]'}',
        );
      } else {
        previousOnError?.call(details);
      }
    };

    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    try {
      await tester.pumpWidget(wrap(screen, textScale: textScale));
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = previousOnError;
    }

    return overflows;
  }

  final screens = <String, Widget Function()>{
    'RegisterScreen': RegisterScreen.new,
    'LoginScreen': LoginScreen.new,
    'LegalDetailScreen': () =>
        const LegalDetailScreen(type: LegalDocumentType.termsOfUse),
  };

  for (final screenEntry in screens.entries) {
    group('${screenEntry.key} layout', () {
      for (final surfaceEntry in surfaces.entries) {
        for (final textScale in textScales) {
          testWidgets('fits ${surfaceEntry.key} at text scale $textScale', (
            tester,
          ) async {
            final overflows = await renderAndCollectOverflows(
              tester,
              screenEntry.value(),
              surface: surfaceEntry.value,
              textScale: textScale,
            );

            expect(
              overflows,
              isEmpty,
              reason:
                  '${screenEntry.key} overflows on ${surfaceEntry.key} '
                  'at text scale $textScale: $overflows',
            );
          });
        }
      }
    });
  }
}
