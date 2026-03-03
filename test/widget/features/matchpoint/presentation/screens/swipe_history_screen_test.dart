import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/swipe_history_entry.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/swipe_history_screen.dart';

import '../../matchpoint_test_fakes.dart';

void main() {
  late MockMatchpointRepository mockRepo;

  setUp(() {
    mockRepo = MockMatchpointRepository();
  });

  Widget createTestWidget({required List<SwipeHistoryEntry> history}) {
    return ProviderScope(
      overrides: [
        swipeHistoryProvider.overrideWithValue(history),
        matchpointRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(home: SwipeHistoryScreen()),
    );
  }

  testWidgets('opens match profile preview when tapping a history card', (
    tester,
  ) async {
    const previewUser = AppUser(
      uid: 'user-1',
      email: 'preview@test.com',
      nome: 'Joao Silva',
      tipoPerfil: AppUserType.professional,
      bio: 'Musico apaixonado por rock e blues',
      dadosProfissional: {
        'nomeArtistico': 'Joao Rock',
        'funcoes': ['Guitarrista', 'Vocalista'],
        'instrumentos': ['Guitarra'],
      },
      matchpointProfile: {
        'hashtags': ['rock_brasil'],
      },
    );

    when(
      mockRepo.fetchUserById('user-1'),
    ).thenAnswer((_) async => const Right<Failure, AppUser?>(previewUser));

    await tester.pumpWidget(
      createTestWidget(
        history: [
          SwipeHistoryEntry(
            targetUserId: 'user-1',
            targetUserName: 'Resumo do perfil',
            targetUserPhoto: null,
            action: 'like',
            timestamp: DateTime(2026, 3, 3, 14, 30),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Resumo do perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Joao Rock'), findsOneWidget);
    expect(find.text('Sobre'), findsOneWidget);
    expect(find.text('Musico apaixonado por rock e blues'), findsOneWidget);
    expect(find.text('#rock_brasil', skipOffstage: false), findsOneWidget);
  });
}
