import '../../../../utils/app_logger.dart';
import '../../../auth/data/auth_repository.dart';

/// Outcome of checking whether the current user may send chat messages.
enum ChatEmailSendCheck {
  /// The email is verified (and, for retries, the token claim is in sync).
  allowed,

  /// The user still has to verify their email.
  needsVerification,

  /// The email is verified but the ID token claim has not caught up yet.
  syncPending,

  /// The verification status could not be read.
  checkFailed,
}

/// Decides whether the current user may send chat messages based on email
/// verification, caching the answer so each send does not hit the network.
///
/// A verified answer is cached longer than an unverified one, so a user who
/// just verified their email is unblocked quickly.
class ChatEmailSendGate {
  static const verifiedCacheTtl = Duration(minutes: 5);
  static const unverifiedCacheTtl = Duration(seconds: 8);

  final AuthRepository _authRepository;
  final DateTime Function() _now;

  bool? _cachedAllowed;
  DateTime? _cachedAt;

  ChatEmailSendGate(this._authRepository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Checks before a send, using the cached answer while it is fresh.
  Future<ChatEmailSendCheck> check() async {
    final cachedAllowed = _cachedAllowed;
    final cachedAt = _cachedAt;
    if (cachedAllowed != null && cachedAt != null) {
      final ttl = cachedAllowed ? verifiedCacheTtl : unverifiedCacheTtl;
      if (_now().difference(cachedAt) < ttl) {
        return cachedAllowed
            ? ChatEmailSendCheck.allowed
            : ChatEmailSendCheck.needsVerification;
      }
    }

    if (_authRepository.isCurrentUserEmailVerified) {
      _remember(true);
      return ChatEmailSendCheck.allowed;
    }

    final bool verified;
    try {
      verified = await _authRepository.isEmailVerified();
    } catch (e) {
      AppLogger.error('Erro ao validar verificacao de email no chat', e);
      return ChatEmailSendCheck.checkFailed;
    }

    _remember(verified);
    return verified
        ? ChatEmailSendCheck.allowed
        : ChatEmailSendCheck.needsVerification;
  }

  /// After a `permission-denied` send, re-reads the email status and forces a
  /// token refresh so the retry carries the verified-email claim.
  ///
  /// Returns [ChatEmailSendCheck.allowed] only when a retry should succeed.
  Future<ChatEmailSendCheck> refreshForRetry() async {
    var verified = _authRepository.isCurrentUserEmailVerified;
    if (!verified) {
      try {
        verified = await _authRepository.isEmailVerified();
      } catch (e) {
        AppLogger.warning('Falha ao recarregar status de email para retry', e);
        return ChatEmailSendCheck.checkFailed;
      }
    }

    if (!verified) {
      _remember(false);
      return ChatEmailSendCheck.needsVerification;
    }

    try {
      final tokenSynced = await _authRepository.hasVerifiedEmailTokenClaim(
        forceRefresh: true,
      );
      _remember(tokenSynced);
      if (tokenSynced) return ChatEmailSendCheck.allowed;
    } catch (e) {
      AppLogger.warning('Falha ao atualizar token verificado para retry', e);
    }

    return ChatEmailSendCheck.syncPending;
  }

  /// Forgets the cached answer, e.g. after returning from the verification
  /// screen.
  void invalidate() {
    _cachedAllowed = null;
    _cachedAt = null;
  }

  void _remember(bool allowed) {
    _cachedAllowed = allowed;
    _cachedAt = _now();
  }
}

/// Whether a send failure came from Firestore rules rejecting the write.
bool isPermissionDeniedFailure(String message) {
  return message.toLowerCase().contains('permission-denied');
}
