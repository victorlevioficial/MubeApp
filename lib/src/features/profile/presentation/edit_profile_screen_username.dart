part of 'edit_profile_screen.dart';

extension _EditProfileScreenUsername on _EditProfileScreenState {
  void _primeUsernameValidationState(AppUser user) {
    final rawUsername = _usernameController.text.trim();
    final normalizedUsername = normalizedPublicUsernameOrNull(rawUsername);
    final currentUsername = normalizedPublicUsernameOrNull(user.publicUsername);
    final formatError = validatePublicUsername(rawUsername);

    if (normalizedUsername == null || formatError != null) {
      _usernameAvailabilityState = _UsernameAvailabilityState.idle;
      _usernameAvailabilityMessage = null;
      return;
    }

    if (normalizedUsername == currentUsername) {
      _usernameAvailabilityState = _UsernameAvailabilityState.current;
      _usernameAvailabilityMessage = 'Esse e o seu @usuario atual.';
      return;
    }

    _usernameAvailabilityState = _UsernameAvailabilityState.idle;
    _usernameAvailabilityMessage = null;
  }

  void _setUsernameAvailabilityState(
    _UsernameAvailabilityState nextState, {
    String? message,
  }) {
    if (_usernameAvailabilityState == nextState &&
        _usernameAvailabilityMessage == message) {
      return;
    }
    _usernameAvailabilityState = nextState;
    _usernameAvailabilityMessage = message;
    _usernameUiVersion.value++;
  }

  void _scheduleUsernameValidation(AppUser user) {
    _usernameValidationDebounce?.cancel();
    final rawUsername = _usernameController.text.trim();
    final normalizedUsername = normalizedPublicUsernameOrNull(rawUsername);
    final currentUsername = normalizedPublicUsernameOrNull(user.publicUsername);
    final formatError = validatePublicUsername(rawUsername);
    final requestId = ++_usernameValidationRequestId;

    if (normalizedUsername == null) {
      _setUsernameAvailabilityState(_UsernameAvailabilityState.idle);
      return;
    }

    if (formatError != null) {
      _setUsernameAvailabilityState(_UsernameAvailabilityState.idle);
      return;
    }

    if (normalizedUsername == currentUsername) {
      _setUsernameAvailabilityState(
        _UsernameAvailabilityState.current,
        message: 'Esse e o seu @usuario atual.',
      );
      return;
    }

    _setUsernameAvailabilityState(
      _UsernameAvailabilityState.checking,
      message: 'Verificando disponibilidade...',
    );

    _usernameValidationDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(
        _checkUsernameAvailability(
          user: user,
          normalizedUsername: normalizedUsername,
          requestId: requestId,
        ),
      );
    });
  }

  void _handleUsernameChanged(AppUser user, String _) {
    ref.read(editProfileControllerProvider(user.uid).notifier).markChanged();
    _scheduleUsernameValidation(user);
  }

  Future<void> _checkUsernameAvailability({
    required AppUser user,
    required String normalizedUsername,
    required int requestId,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .isPublicUsernameAvailable(normalizedUsername, excludingUid: user.uid);

    if (!mounted) return;

    final latestUsername = normalizedPublicUsernameOrNull(
      _usernameController.text.trim(),
    );
    if (requestId != _usernameValidationRequestId ||
        latestUsername != normalizedUsername) {
      return;
    }

    result.fold(
      (_) => _setUsernameAvailabilityState(
        _UsernameAvailabilityState.error,
        message: 'Nao foi possivel verificar esse @usuario agora.',
      ),
      (isAvailable) => _setUsernameAvailabilityState(
        isAvailable
            ? _UsernameAvailabilityState.available
            : _UsernameAvailabilityState.unavailable,
        message: isAvailable
            ? '@$normalizedUsername disponivel.'
            : 'Esse @usuario ja esta em uso. Escolha outro.',
      ),
    );
  }

  String? _usernameValidator(AppUser user, String? value) {
    final formatError = validatePublicUsername(value);
    if (formatError != null) {
      return formatError;
    }

    final normalizedUsername = normalizedPublicUsernameOrNull(value);
    final currentUsername = normalizedPublicUsernameOrNull(user.publicUsername);
    if (normalizedUsername == null || normalizedUsername == currentUsername) {
      return null;
    }

    switch (_usernameAvailabilityState) {
      case _UsernameAvailabilityState.available:
        return null;
      case _UsernameAvailabilityState.checking:
        return 'Aguarde a verificacao do @usuario.';
      case _UsernameAvailabilityState.unavailable:
      case _UsernameAvailabilityState.error:
        return _usernameAvailabilityMessage;
      case _UsernameAvailabilityState.idle:
        return 'Verifique a disponibilidade do @usuario.';
      case _UsernameAvailabilityState.current:
        return null;
    }
  }

  bool _canSaveWithUsername(AppUser user) {
    final rawUsername = _usernameController.text.trim();
    final formatError = validatePublicUsername(rawUsername);
    if (formatError != null) {
      return false;
    }

    final normalizedUsername = normalizedPublicUsernameOrNull(rawUsername);
    final currentUsername = normalizedPublicUsernameOrNull(user.publicUsername);
    if (normalizedUsername == null || normalizedUsername == currentUsername) {
      return true;
    }

    return _usernameAvailabilityState == _UsernameAvailabilityState.available;
  }

  Widget? _buildUsernameStatus(AppUser user) {
    final rawUsername = _usernameController.text.trim();
    if (rawUsername.isEmpty) return null;

    final formatError = validatePublicUsername(rawUsername);
    if (formatError != null) {
      return _buildUsernameStatusMessage(
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        message: formatError,
      );
    }

    final normalizedUsername = normalizedPublicUsernameOrNull(rawUsername);
    if (normalizedUsername == null) {
      return null;
    }

    IconData icon;
    Color color;
    String? message;

    switch (_usernameAvailabilityState) {
      case _UsernameAvailabilityState.checking:
        icon = Icons.hourglass_top_rounded;
        color = AppColors.textSecondary;
        message =
            _usernameAvailabilityMessage ?? 'Verificando disponibilidade...';
        break;
      case _UsernameAvailabilityState.available:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        message = _usernameAvailabilityMessage;
        break;
      case _UsernameAvailabilityState.unavailable:
        icon = Icons.highlight_off_rounded;
        color = AppColors.error;
        message = _usernameAvailabilityMessage;
        break;
      case _UsernameAvailabilityState.current:
        icon = Icons.verified_rounded;
        color = AppColors.success;
        message = _usernameAvailabilityMessage;
        break;
      case _UsernameAvailabilityState.error:
        icon = Icons.error_outline_rounded;
        color = AppColors.error;
        message =
            _usernameAvailabilityMessage ??
            'Nao foi possivel verificar esse @usuario agora.';
        break;
      case _UsernameAvailabilityState.idle:
        return null;
    }

    if (message == null || message.isEmpty) {
      return null;
    }

    return _buildUsernameStatusMessage(
      icon: icon,
      color: color,
      message: message,
    );
  }

  Widget _buildUsernameStatusMessage({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
