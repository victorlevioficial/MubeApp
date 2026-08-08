import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mube/firebase_options.dart';
import 'package:mube/main.dart' as app;
import 'package:mube/src/app.dart';
import 'package:mube/src/core/config/firebase_emulator_config.dart';
import 'package:mube/src/design_system/components/navigation/app_back_button.dart';
import 'package:mube/src/design_system/components/navigation/main_scaffold.dart';
import 'package:mube/src/features/chat/presentation/conversations_screen.dart';
import 'package:mube/src/features/gigs/data/gig_search_index.dart';
import 'package:mube/src/features/gigs/presentation/screens/gig_detail_screen.dart';
import 'package:mube/src/features/gigs/presentation/screens/gigs_hub_screen.dart';
import 'package:mube/src/features/onboarding/presentation/onboarding_type_screen.dart';
import 'package:mube/src/features/settings/presentation/settings_screen.dart';

final _password = base64UrlEncode(
  List<int>.generate(24, (_) => Random.secure().nextInt(256)),
);

Future<void> _deleteEmulatorResource(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.deleteUrl(uri);
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices) {
      throw HttpException(
        'Emulator reset failed with HTTP ${response.statusCode}.',
        uri: uri,
      );
    }
  } finally {
    client.close(force: true);
  }
}

Future<void> _resetEmulators() async {
  final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
  await _deleteEmulatorResource(
    Uri.http(
      '$firebaseEmulatorHost:9099',
      '/emulator/v1/projects/$projectId/accounts',
    ),
  );
  await _deleteEmulatorResource(
    Uri.http(
      '$firebaseEmulatorHost:8080',
      '/emulator/v1/projects/$projectId/databases/(default)/documents',
    ),
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsWidgets);
}

Future<String> _latestVerificationCode(String email) async {
  final client = HttpClient();
  try {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    final uri = Uri.parse(
      'http://$firebaseEmulatorHost:9099/emulator/v1/projects/'
      '$projectId/oobCodes',
    );
    for (var attempt = 0; attempt < 20; attempt++) {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.ok) {
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final codes = (payload['oobCodes'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .where((entry) => entry['email'] == email)
            .toList(growable: false);
        if (codes.isNotEmpty) {
          final link = Uri.parse(codes.last['oobLink'] as String);
          final code = link.queryParameters['oobCode'];
          if (code != null && code.isNotEmpty) return code;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('Verification code was not emitted for $email.');
  } finally {
    client.close(force: true);
  }
}

Future<User> _createVerifiedUser(String email) async {
  final auth = FirebaseAuth.instance;
  final credential = await auth.createUserWithEmailAndPassword(
    email: email,
    password: _password,
  );
  await credential.user!.sendEmailVerification();
  final code = await _latestVerificationCode(email);
  await auth.applyActionCode(code);
  await credential.user!.reload();
  return auth.currentUser!;
}

Future<void> _seedProfile(User user, {required bool complete}) async {
  final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
  await ref.set({
    'uid': user.uid,
    'email': user.email,
    'cadastro_status': 'tipo_pendente',
    'nome': user.email!.split('@').first,
  });
  if (!complete) return;

  await ref.update({
    'cadastro_status': 'perfil_pendente',
    'tipo_perfil': 'profissional',
  });
  await ref.update({
    'cadastro_status': 'concluido',
    'status': 'ativo',
    'nome': 'Artista E2E',
    'bio': 'Perfil autenticado criado pelo teste de integração.',
    'profissional': {
      'categoria': 'musico',
      'categorias': ['musico'],
      'instrumentos': ['guitarra'],
      'generosMusicais': ['rock'],
    },
  });
}

Future<void> _seedGig(String creatorId) async {
  const title = 'Saxofonista para festival E2E';
  const description =
      'Oportunidade autenticada para validar listagem, detalhe e navegação.';
  await FirebaseFirestore.instance.collection('gigs').doc('gig-e2e').set({
    'title': title,
    'description': description,
    'gig_type': 'show_ao_vivo',
    'status': 'open',
    'date_mode': 'unspecified',
    'gig_date': null,
    'location_type': 'remoto',
    'location': null,
    'geohash': null,
    'genres': ['rock'],
    'required_instruments': ['saxofone'],
    'required_crew_roles': <String>[],
    'required_studio_services': <String>[],
    'slots_total': 1,
    'slots_filled': 0,
    'compensation_type': 'negotiable',
    'compensation_value': null,
    'creator_id': creatorId,
    'applicant_count': 0,
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': FieldValue.serverTimestamp(),
    'expires_at': null,
    'search_grams': buildGigSearchGrams(title: title, description: description),
    'search_schema_version': gigSearchSchemaVersion,
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'authenticated onboarding guard, tabs, gig detail and offline lifecycle',
    (tester) async {
      final originalFlutterErrorHandler = FlutterError.onError;
      final originalPlatformErrorHandler = PlatformDispatcher.instance.onError;
      final originalErrorWidgetBuilder = ErrorWidget.builder;

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await configureFirebaseEmulatorsIfEnabled();
      final auth = FirebaseAuth.instance;
      await auth.signOut();
      await _resetEmulators();

      debugPrint('E2E_STAGE: seed users');
      final primary = await _createVerifiedUser('primary-e2e@mube.test');
      await _seedProfile(primary, complete: true);

      final creator = await _createVerifiedUser('creator-e2e@mube.test');
      await _seedProfile(creator, complete: true);
      await _seedGig(creator.uid);

      final pending = await _createVerifiedUser('pending-e2e@mube.test');
      await _seedProfile(pending, complete: false);

      try {
        debugPrint('E2E_STAGE: onboarding guard');
        app.main();
        await tester.pump();
        await _pumpUntil(tester, find.byType(OnboardingTypeScreen));

        debugPrint('E2E_STAGE: authenticated shell');
        await auth.signInWithEmailAndPassword(
          email: 'primary-e2e@mube.test',
          password: _password,
        );
        await _pumpUntil(tester, find.byType(MainScaffold));
        expect(find.byType(MubeApp), findsOneWidget);

        debugPrint('E2E_STAGE: gig list and detail');
        await tester.tap(find.text('Gigs').last);
        await _pumpUntil(tester, find.byType(GigsHubScreen));
        await _pumpUntil(tester, find.text('Saxofonista para festival E2E'));

        await tester.tap(find.text('Saxofonista para festival E2E').first);
        await _pumpUntil(tester, find.byType(GigDetailScreen));
        expect(find.text('Saxofonista para festival E2E'), findsWidgets);
        await tester.tap(find.byType(AppBackButton));
        await _pumpUntil(tester, find.byType(GigsHubScreen));

        debugPrint('E2E_STAGE: offline lifecycle');
        await FirebaseFirestore.instance.disableNetwork().timeout(
          const Duration(seconds: 10),
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(milliseconds: 300));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(MubeApp), findsOneWidget);

        debugPrint('E2E_STAGE: chat and account tabs');
        await tester.tap(find.text('Chat').last);
        await _pumpUntil(tester, find.byType(ConversationsScreen));
        await tester.tap(find.text('Conta').last);
        await _pumpUntil(tester, find.byType(SettingsScreen));
        expect(tester.takeException(), isNull);
        debugPrint('E2E_STAGE: complete');
      } finally {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await FirebaseFirestore.instance.enableNetwork().timeout(
            const Duration(seconds: 10),
          );
          await auth.signOut();
          await FirebaseFirestore.instance.terminate().timeout(
            const Duration(seconds: 10),
          );
        } finally {
          FlutterError.onError = originalFlutterErrorHandler;
          PlatformDispatcher.instance.onError = originalPlatformErrorHandler;
          ErrorWidget.builder = originalErrorWidgetBuilder;
        }
      }
    },
    skip: !firebaseEmulatorsEnabled,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
