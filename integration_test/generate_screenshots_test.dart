import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mube/firebase_options.dart';
import 'package:mube/src/app.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/services/analytics/meta_analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/splash/providers/app_bootstrap_provider.dart';
import 'package:window_manager/window_manager.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'mock_user_123';

  @override
  String? get email => 'artista@mube.app';

  @override
  String? get displayName => 'Artista Demo';

  @override
  String? get photoURL => 'https://i.pravatar.cc/300';

  @override
  bool get emailVerified => true;
}

final mockAuthStreamController = StreamController<User?>.broadcast();
final mockProfileStreamController = StreamController<AppUser?>.broadcast();

class MockAuthRepository extends Fake implements AuthRepository {
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  void emitAuth(User? user) {
    _currentUser = user;
    mockAuthStreamController.add(user);
  }

  @override
  Stream<User?> authStateChanges() => mockAuthStreamController.stream;

  @override
  Stream<AppUser?> watchUser(String uid) => mockProfileStreamController.stream;

  @override
  FutureResult<Unit> signOut() async {
    emitAuth(null);
    mockProfileStreamController.add(null);
    return const Right(unit);
  }

  @override
  bool get isCurrentUserEmailVerified => _currentUser?.emailVerified ?? false;

  @override
  FutureResult<Unit> ensureCurrentUserProfileExists() async {
    return const Right(unit);
  }

  @override
  FutureResult<Unit> refreshSecurityContext() async {
    return const Right(unit);
  }
}

Future<void> takeScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await binding.takeScreenshot(name);
    debugPrint('Saved device screenshot: $name');
    return;
  }

  final finder = find.byKey(const Key('screenshot_boundary'));
  if (finder.evaluate().isEmpty) {
    throw StateError('Could not find screenshot boundary');
  }

  final element = finder.evaluate().first;
  final renderObject = element.renderObject as RenderRepaintBoundary;
  final image = await renderObject.toImage(pixelRatio: 2);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();

  final file = File('screenshots/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(buffer);
  debugPrint('Saved screenshots/$name.png');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  });

  tearDownAll(() async {
    await mockAuthStreamController.close();
    await mockProfileStreamController.close();
  });

  testWidgets('generates representative store screenshots', (tester) async {
    if (!kIsWeb && Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1080, 1920),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    final resolutions = !kIsWeb && (Platform.isAndroid || Platform.isIOS)
        ? const {'phone': Size(411, 860)}
        : const {
            'phone': Size(411, 860),
            'tablet_7': Size(600, 960),
            'tablet_10': Size(800, 1280),
          };
    final authRepository = MockAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authStateChangesProvider.overrideWith(
            (ref) => mockAuthStreamController.stream,
          ),
          currentUserProfileProvider.overrideWith(
            (ref) => mockProfileStreamController.stream,
          ),
          analyticsServiceProvider.overrideWithValue(
            const NoopAnalyticsService(),
          ),
          metaAnalyticsServiceProvider.overrideWithValue(
            const NoopMetaAnalyticsService(),
          ),
          appCheckBootstrapperProvider.overrideWithValue(() async {}),
        ],
        child: const RepaintBoundary(
          key: Key('screenshot_boundary'),
          child: MubeApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dummyUser = AppUser(
      uid: 'mock_user_123',
      email: 'artista@mube.app',
      nome: 'Artista Demo',
      foto: null,
      tipoPerfil: AppUserType.professional,
      location: null,
      bio: 'Buscando banda para tocar covers e autorais.',
      createdAt: DateTime.now(),
      cadastroStatus: 'concluido',
    );

    for (final entry in resolutions.entries) {
      final deviceName = entry.key;
      final size = entry.value;

      debugPrint('Processing $deviceName');

      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await windowManager.setSize(size);
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      await tester.pumpAndSettle();

      authRepository.emitAuth(null);
      mockProfileStreamController.add(null);
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(seconds: 1));
      await takeScreenshot(binding, tester, '${deviceName}_1_login');

      authRepository.emitAuth(MockUser());
      mockProfileStreamController.add(dummyUser);
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(seconds: 2));
      await takeScreenshot(binding, tester, '${deviceName}_2_feed');

      final searchTab = find.byIcon(Icons.search_outlined);
      if (searchTab.evaluate().isNotEmpty) {
        await tester.tap(searchTab);
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(seconds: 1));
        await takeScreenshot(binding, tester, '${deviceName}_3_search');
      }

      final matchPointTab = find.byIcon(Icons.bolt_outlined);
      if (matchPointTab.evaluate().isNotEmpty) {
        await tester.tap(matchPointTab);
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(seconds: 1));
        await takeScreenshot(binding, tester, '${deviceName}_4_matchpoint');
      }
    }
  });
}
