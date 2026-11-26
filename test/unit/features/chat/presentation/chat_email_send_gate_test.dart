import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/chat/presentation/controllers/chat_email_send_gate.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;
  late DateTime now;
  late ChatEmailSendGate gate;

  setUp(() {
    auth = _MockAuthRepository();
    now = DateTime(2026, 11, 18, 12);
    gate = ChatEmailSendGate(auth, now: () => now);
    when(() => auth.isCurrentUserEmailVerified).thenReturn(false);
  });

  group('check', () {
    test('allows a user whose session already says verified', () async {
      when(() => auth.isCurrentUserEmailVerified).thenReturn(true);

      expect(await gate.check(), ChatEmailSendCheck.allowed);
      verifyNever(() => auth.isEmailVerified());
    });

    test('reloads the status when the session is not verified', () async {
      when(() => auth.isEmailVerified()).thenAnswer((_) async => true);

      expect(await gate.check(), ChatEmailSendCheck.allowed);
    });

    test('asks for verification when the email is not verified', () async {
      when(() => auth.isEmailVerified()).thenAnswer((_) async => false);

      expect(await gate.check(), ChatEmailSendCheck.needsVerification);
    });

    test('reports a failed check when the status cannot be read', () async {
      when(() => auth.isEmailVerified()).thenThrow(Exception('offline'));

      expect(await gate.check(), ChatEmailSendCheck.checkFailed);
    });

    test('caches a verified answer for five minutes', () async {
      when(() => auth.isEmailVerified()).thenAnswer((_) async => true);
      await gate.check();

      now = now.add(const Duration(minutes: 4));
      expect(await gate.check(), ChatEmailSendCheck.allowed);
      verify(() => auth.isEmailVerified()).called(1);

      now = now.add(const Duration(minutes: 2));
      await gate.check();
      verify(() => auth.isEmailVerified()).called(1);
    });

    test('caches an unverified answer only briefly', () async {
      when(() => auth.isEmailVerified()).thenAnswer((_) async => false);
      await gate.check();

      now = now.add(const Duration(seconds: 5));
      expect(await gate.check(), ChatEmailSendCheck.needsVerification);
      verify(() => auth.isEmailVerified()).called(1);

      now = now.add(const Duration(seconds: 5));
      when(() => auth.isEmailVerified()).thenAnswer((_) async => true);
      expect(await gate.check(), ChatEmailSendCheck.allowed);
    });

    test('invalidate drops the cached answer', () async {
      when(() => auth.isEmailVerified()).thenAnswer((_) async => false);
      await gate.check();

      gate.invalidate();
      when(() => auth.isEmailVerified()).thenAnswer((_) async => true);

      expect(await gate.check(), ChatEmailSendCheck.allowed);
    });
  });

  group('refreshForRetry', () {
    test('allows a retry once the token claim is synced', () async {
      when(() => auth.isEmailVerified()).thenAnswer((_) async => true);
      when(
        () => auth.hasVerifiedEmailTokenClaim(forceRefresh: true),
      ).thenAnswer((_) async => true);

      expect(await gate.refreshForRetry(), ChatEmailSendCheck.allowed);
    });

    test('reports sync pending while the token claim lags', () async {
      when(() => auth.isCurrentUserEmailVerified).thenReturn(true);
      when(
        () => auth.hasVerifiedEmailTokenClaim(forceRefresh: true),
      ).thenAnswer((_) async => false);

      expect(await gate.refreshForRetry(), ChatEmailSendCheck.syncPending);
    });

    test('reports sync pending when the token refresh fails', () async {
      when(() => auth.isCurrentUserEmailVerified).thenReturn(true);
      when(
        () => auth.hasVerifiedEmailTokenClaim(forceRefresh: true),
      ).thenThrow(Exception('token'));

      expect(await gate.refreshForRetry(), ChatEmailSendCheck.syncPending);
    });

    test('asks for verification and caches it when unverified', () async {
      when(() => auth.isEmailVerified()).thenAnswer((_) async => false);

      expect(
        await gate.refreshForRetry(),
        ChatEmailSendCheck.needsVerification,
      );
      expect(await gate.check(), ChatEmailSendCheck.needsVerification);
      verify(() => auth.isEmailVerified()).called(1);
    });

    test('reports a failed check when the status cannot be read', () async {
      when(() => auth.isEmailVerified()).thenThrow(Exception('offline'));

      expect(await gate.refreshForRetry(), ChatEmailSendCheck.checkFailed);
    });
  });

  test('detects permission-denied send failures', () {
    expect(
      isPermissionDeniedFailure('[cloud_firestore/permission-denied] nope'),
      isTrue,
    );
    expect(isPermissionDeniedFailure('PERMISSION-DENIED'), isTrue);
    expect(isPermissionDeniedFailure('network error'), isFalse);
  });
}
