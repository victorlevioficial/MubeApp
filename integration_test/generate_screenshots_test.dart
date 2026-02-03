import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mube/src/app.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:window_manager/window_manager.dart';

// --- MOCKS ---

class MockUser extends Fake implements User {
  @override
  String get uid => 'mock_user_123';
  @override
  String? get email => 'artista@mube.app';
  @override
  String? get displayName => 'Artista Demo';
  @override
  String? get photoURL => 'https://i.pravatar.cc/300';
}

final mockAuthStreamController = StreamController<User?>.broadcast();
final mockProfileStreamController = StreamController<AppUser?>.broadcast();

class MockAuthRepository extends Fake implements AuthRepository {
  @override
  Stream<User?> authStateChanges() => mockAuthStreamController.stream;

  @override
  Stream<AppUser?> watchUser(String uid) => mockProfileStreamController.stream;

  @override
  FutureResult<Unit> signOut() async {
    mockAuthStreamController.add(null);
    mockProfileStreamController.add(null);
    return const Right(unit);
  }
}

Future<void> takeScreenshot(WidgetTester tester, String name) async {
  try {
    // Force a frame
    await tester.pumpAndSettle();

    // Find the RepaintBoundary wrapping the app
    final finder = find.byKey(const Key('screenshot_boundary'));
    if (finder.evaluate().isEmpty) {
      debugPrint('Error: Could not find screenshot boundary');
      return;
    }

    final element = finder.evaluate().first;
    final renderObject = element.renderObject as RenderRepaintBoundary;

    // Capture
    final image = await renderObject.toImage(pixelRatio: 2.0); // Higher quality
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final file = File('screenshots/$name.png');
    await file.parent.create(recursive: true); // Ensure dir exists
    await file.writeAsBytes(buffer);
    debugPrint('✅ Saved screenshots/$name.png');
  } catch (e) {
    debugPrint('❌ Failed to save screenshot $name: $e');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Generate Store Screenshots', (tester) async {
    // 1. Setup Window
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();
      const WindowOptions windowOptions = WindowOptions(
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

    final resolutions = {
      'phone': const Size(411, 860),
      'tablet_7': const Size(600, 960),
      'tablet_10': const Size(800, 1280),
    };

    // 3. Start App (Wrapped in RepaintBoundary)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          authStateChangesProvider.overrideWith(
            (ref) => mockAuthStreamController.stream,
          ),
          currentUserProfileProvider.overrideWith(
            (ref) => mockProfileStreamController.stream,
          ),
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

      debugPrint('--- Processing $deviceName ---');

      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await windowManager.setSize(size);
        await Future.delayed(const Duration(seconds: 2));
      }
      await tester.pumpAndSettle();

      // --- LOGGED OUT ---
      mockAuthStreamController.add(null);
      mockProfileStreamController.add(null);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));

      await takeScreenshot(tester, '${deviceName}_1_login');

      // --- LOGGED IN (Feed) ---
      mockAuthStreamController.add(MockUser());
      mockProfileStreamController.add(dummyUser);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      await takeScreenshot(tester, '${deviceName}_2_feed');

      // --- SEARCH ---
      final searchTab = find.byIcon(Icons.search_outlined);
      if (searchTab.evaluate().isNotEmpty) {
        await tester.tap(searchTab);
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 1));
        await takeScreenshot(tester, '${deviceName}_3_search');
      }

      // --- MATCHPOINT ---
      final matchPointTab = find.byIcon(Icons.bolt_outlined);
      if (matchPointTab.evaluate().isNotEmpty) {
        await tester.tap(matchPointTab);
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 1));
        await takeScreenshot(tester, '${deviceName}_4_matchpoint');
      }
    }
  });
}
