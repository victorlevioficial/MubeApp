import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/design_system/components/loading/app_loading_indicator.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/match_info.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/matchpoint_intro_screen.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/matchpoint_tabs_screen.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/matchpoint_wrapper_screen.dart';

import '../features/matchpoint/matchpoint_test_fakes.dart';

void main() {
  late MockMatchpointRepository mockRepo;

  setUp(() {
    mockRepo = MockMatchpointRepository();

    // Stub default behavior
    try {
      provideDummy<Either<Failure, LikesQuotaInfo>>(
        const Left(ServerFailure(message: 'dummy')),
      );
    } catch (_) {}

    when(mockRepo.getRemainingLikes()).thenAnswer(
      (_) async => Right<Failure, LikesQuotaInfo>(
        LikesQuotaInfo(remaining: 10, limit: 10, resetTime: DateTime.now()),
      ),
    );
    when(
      mockRepo.fetchCandidates(
        currentUserId: anyNamed('currentUserId'),
        genres: anyNamed('genres'),
        blockedUsers: anyNamed('blockedUsers'),
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => const Right<Failure, List<AppUser>>([]));

    when(
      mockRepo.fetchMatches(any),
    ).thenAnswer((_) async => const Right<Failure, List<MatchInfo>>([]));

    when(
      mockRepo.fetchHashtagRanking(limit: anyNamed('limit')),
    ).thenAnswer((_) async => const Right<Failure, List<HashtagRanking>>([]));
  });

  Widget createTestWidget(AsyncValue<AppUser?> userProfileState) {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWithValue(userProfileState),
        matchpointRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(home: MatchpointWrapperScreen()),
    );
  }

  testWidgets('renders AppLoadingIndicator when profile is loading', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AsyncLoading()));

    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('renders MatchpointIntroScreen when profile is active=false', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'user1',
      email: 'test@example.com',
      matchpointProfile: {'is_active': false},
    );

    await tester.pumpWidget(createTestWidget(const AsyncData(user)));
    await tester.pump(); // frame for widget switch

    expect(find.byType(MatchpointIntroScreen), findsOneWidget);
    expect(find.byType(MatchpointTabsScreen), findsNothing);
  });

  testWidgets('renders MatchpointIntroScreen when matchpointProfile is null', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'user1',
      email: 'test@example.com',
      matchpointProfile: null,
    );

    await tester.pumpWidget(createTestWidget(const AsyncData(user)));
    await tester.pump();

    expect(find.byType(MatchpointIntroScreen), findsOneWidget);
  });

  testWidgets('renders MatchpointTabsScreen when profile is active=true', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'user1',
      email: 'test@example.com',
      matchpointProfile: {'is_active': true},
    );

    await tester.pumpWidget(createTestWidget(const AsyncData(user)));
    await tester.pump();

    expect(find.byType(MatchpointTabsScreen), findsOneWidget);
    expect(find.byType(MatchpointIntroScreen), findsNothing);
  });

  testWidgets('renders Error message when profile loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(const AsyncError('Failed to load', StackTrace.empty)),
    );
    await tester.pump();

    expect(find.text('Erro: Failed to load'), findsOneWidget);
  });
}
