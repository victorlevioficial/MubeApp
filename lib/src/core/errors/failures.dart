/// Base class for all application failures.
///
/// Failures represent expected error conditions that the app can handle
/// gracefully with user-friendly messages.
abstract class Failure {
  /// User-friendly message to display.
  final String message;

  /// Optional technical details for debugging.
  final String? debugMessage;

  /// Original exception if any.
  final Object? originalError;

  const Failure({required this.message, this.debugMessage, this.originalError});

  @override
  String toString() =>
      'Failure: $message${debugMessage != null ? ' ($debugMessage)' : ''}';
}

// ============================================================================
// AUTHENTICATION FAILURES
// ============================================================================

/// Represents authentication-related failures.
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.debugMessage,
    super.originalError,
  });

  /// User not found.
  factory AuthFailure.userNotFound() => const AuthFailure(
    message: 'Usuário não encontrado.',
    debugMessage: 'user-not-found',
  );

  /// Wrong password.
  factory AuthFailure.wrongPassword() => const AuthFailure(
    message: 'Senha incorreta.',
    debugMessage: 'wrong-password',
  );

  /// Email already in use.
  factory AuthFailure.emailAlreadyInUse() => const AuthFailure(
    message: 'Este e-mail já está cadastrado.',
    debugMessage: 'email-already-in-use',
  );

  /// Invalid email format.
  factory AuthFailure.invalidEmail() => const AuthFailure(
    message: 'E-mail inválido.',
    debugMessage: 'invalid-email',
  );

  /// Weak password.
  factory AuthFailure.weakPassword() => const AuthFailure(
    message: 'Senha muito fraca. Use pelo menos 6 caracteres.',
    debugMessage: 'weak-password',
  );

  /// User disabled.
  factory AuthFailure.userDisabled() => const AuthFailure(
    message: 'Esta conta foi desativada.',
    debugMessage: 'user-disabled',
  );

  /// Too many requests.
  factory AuthFailure.tooManyRequests() => const AuthFailure(
    message: 'Muitas tentativas. Tente novamente mais tarde.',
    debugMessage: 'too-many-requests',
  );

  /// Session expired.
  factory AuthFailure.sessionExpired() => const AuthFailure(
    message: 'Sua sessão expirou. Faça login novamente.',
    debugMessage: 'session-expired',
  );
}

// ============================================================================
// NETWORK FAILURES
// ============================================================================

/// Represents network-related failures.
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.debugMessage,
    super.originalError,
  });

  /// No internet connection.
  factory NetworkFailure.noConnection() => const NetworkFailure(
    message: 'Sem conexão com a internet.',
    debugMessage: 'no-connection',
  );

  /// Request timeout.
  factory NetworkFailure.timeout() => const NetworkFailure(
    message: 'A conexão demorou muito. Tente novamente.',
    debugMessage: 'timeout',
  );

  /// Server error.
  factory NetworkFailure.serverError() => const NetworkFailure(
    message: 'Erro no servidor. Tente novamente mais tarde.',
    debugMessage: 'server-error',
  );
}

// ============================================================================
// STORAGE FAILURES
// ============================================================================

/// Represents storage/upload-related failures.
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.debugMessage,
    super.originalError,
  });

  /// File too large.
  factory StorageFailure.fileTooLarge({int? maxSizeMB}) => StorageFailure(
    message: maxSizeMB != null
        ? 'Arquivo muito grande. Máximo: ${maxSizeMB}MB.'
        : 'Arquivo muito grande.',
    debugMessage: 'file-too-large',
  );

  /// Invalid file type.
  factory StorageFailure.invalidFileType() => const StorageFailure(
    message: 'Tipo de arquivo não suportado.',
    debugMessage: 'invalid-file-type',
  );

  /// Upload failed.
  factory StorageFailure.uploadFailed() => const StorageFailure(
    message: 'Erro ao enviar arquivo. Tente novamente.',
    debugMessage: 'upload-failed',
  );

  /// Storage quota exceeded.
  factory StorageFailure.quotaExceeded() => const StorageFailure(
    message: 'Limite de armazenamento atingido.',
    debugMessage: 'quota-exceeded',
  );
}

// ============================================================================
// VALIDATION FAILURES
// ============================================================================

/// Represents validation-related failures.
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.debugMessage,
    super.originalError,
  });

  /// Required field is empty.
  factory ValidationFailure.requiredField(String fieldName) =>
      ValidationFailure(
        message: '$fieldName é obrigatório.',
        debugMessage: 'required-field: $fieldName',
      );

  /// Invalid format.
  factory ValidationFailure.invalidFormat(String fieldName) =>
      ValidationFailure(
        message: 'Formato de $fieldName inválido.',
        debugMessage: 'invalid-format: $fieldName',
      );
}

// ============================================================================
// PERMISSION FAILURES
// ============================================================================

/// Represents permission-related failures.
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.debugMessage,
    super.originalError,
  });

  /// Camera permission denied.
  factory PermissionFailure.camera() => const PermissionFailure(
    message: 'Permissão de câmera negada. Habilite nas configurações.',
    debugMessage: 'camera-denied',
  );

  /// Gallery permission denied.
  factory PermissionFailure.gallery() => const PermissionFailure(
    message: 'Permissão de galeria negada. Habilite nas configurações.',
    debugMessage: 'gallery-denied',
  );

  /// Location permission denied.
  factory PermissionFailure.location() => const PermissionFailure(
    message: 'Permissão de localização negada. Habilite nas configurações.',
    debugMessage: 'location-denied',
  );

  /// Firestore permission denied.
  factory PermissionFailure.firestore() => const PermissionFailure(
    message: 'Você não tem permissão para acessar este recurso.',
    debugMessage: 'permission-denied',
  );
}

// ============================================================================
// SERVER & CACHE FAILURES
// ============================================================================

/// Represents a server-side failure.
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.debugMessage,
    super.originalError,
  });
}

/// Represents a cache-related failure.
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.debugMessage,
    super.originalError,
  });
}

// ============================================================================
// GENERIC FAILURE
// ============================================================================

/// Represents an unexpected/unknown failure.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Algo deu errado. Tente novamente.',
    super.debugMessage,
    super.originalError,
  });
}
