import '../../auth/domain/app_user.dart';

/// Validation result with optional error message
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $errorMessage';
}

/// Abstract profile validator interface
/// Each profile type implements its own validation rules
abstract class ProfileValidator {
  /// Validate the profile data
  /// Returns a [ValidationResult] with success/failure and error message
  ValidationResult validate(Map<String, dynamic> data);

  /// Get all validation errors (for showing multiple at once)
  List<String> getAllErrors(Map<String, dynamic> data);

  /// Factory to get the right validator for a user type
  static ProfileValidator forUserType(AppUserType type) {
    return switch (type) {
      AppUserType.professional => ProfessionalProfileValidator(),
      AppUserType.band => BandProfileValidator(),
      AppUserType.studio => StudioProfileValidator(),
      AppUserType.contractor => ContractorProfileValidator(),
      _ => _NoOpValidator(),
    };
  }
}

/// Validator for Professional profiles
class ProfessionalProfileValidator extends ProfileValidator {
  @override
  ValidationResult validate(Map<String, dynamic> data) {
    final errors = getAllErrors(data);
    if (errors.isEmpty) return const ValidationResult.valid();
    return ValidationResult.invalid(errors.first);
  }

  @override
  List<String> getAllErrors(Map<String, dynamic> data) {
    final errors = <String>[];

    final categories = data['categories'] as List<String>? ?? [];
    final instruments = data['instruments'] as List<String>? ?? [];
    final genres = data['genres'] as List<String>? ?? [];
    final roles = data['roles'] as List<String>? ?? [];

    // Rule 1: Must have at least one category
    if (categories.isEmpty) {
      errors.add('Selecione pelo menos uma categoria.');
    }

    // Rule 2: Instrumentalist must have instruments
    if (categories.contains('instrumentalist') && instruments.isEmpty) {
      errors.add('Selecione pelo menos um instrumento para continuar.');
    }

    // Rule 3: Crew must have roles
    if (categories.contains('crew') && roles.isEmpty) {
      errors.add('Selecione pelo menos uma função técnica para continuar.');
    }

    // Rule 4: Must have genres
    if (genres.isEmpty) {
      errors.add('Selecione pelo menos um gênero musical.');
    }

    return errors;
  }
}

/// Validator for Band profiles
class BandProfileValidator extends ProfileValidator {
  @override
  ValidationResult validate(Map<String, dynamic> data) {
    final errors = getAllErrors(data);
    if (errors.isEmpty) return const ValidationResult.valid();
    return ValidationResult.invalid(errors.first);
  }

  @override
  List<String> getAllErrors(Map<String, dynamic> data) {
    final errors = <String>[];

    final genres = data['genres'] as List<String>? ?? [];

    // Rule 1: Must have genres
    if (genres.isEmpty) {
      errors.add('Selecione pelo menos um gênero musical.');
    }

    return errors;
  }
}

/// Validator for Studio profiles
class StudioProfileValidator extends ProfileValidator {
  @override
  ValidationResult validate(Map<String, dynamic> data) {
    final errors = getAllErrors(data);
    if (errors.isEmpty) return const ValidationResult.valid();
    return ValidationResult.invalid(errors.first);
  }

  @override
  List<String> getAllErrors(Map<String, dynamic> data) {
    final errors = <String>[];

    final services = data['services'] as List<String>? ?? [];

    // Rule 1: Must have at least one service
    if (services.isEmpty) {
      errors.add('Selecione pelo menos um serviço oferecido.');
    }

    return errors;
  }
}

/// Validator for Contractor profiles
class ContractorProfileValidator extends ProfileValidator {
  @override
  ValidationResult validate(Map<String, dynamic> data) {
    // Contractors have minimal validation requirements
    return const ValidationResult.valid();
  }

  @override
  List<String> getAllErrors(Map<String, dynamic> data) {
    return [];
  }
}

/// No-op validator for unknown types
class _NoOpValidator extends ProfileValidator {
  @override
  ValidationResult validate(Map<String, dynamic> data) {
    return const ValidationResult.valid();
  }

  @override
  List<String> getAllErrors(Map<String, dynamic> data) => [];
}
