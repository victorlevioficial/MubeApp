# MubeApp Code Style Guide

## Language Policy

| Context | Language |
|---------|----------|
| Code (classes, methods, variables) | English |
| Comments and documentation | English |
| User-facing strings (UI) | Portuguese (Brazil) |
| Commit messages | English |
| File names | English (snake_case) |

## Naming Conventions

### Classes & Types
```dart
// ✅ Good - PascalCase
class AuthRepository {}
class AppUserType {}
typedef UserCallback = void Function(AppUser);

// ❌ Bad
class auth_repository {}
class appUserType {}
```

### Variables & Parameters
```dart
// ✅ Good - camelCase
final userName = 'John';
void updateProfile({required String displayName}) {}

// ❌ Bad
final user_name = 'John';
final UserName = 'John';
```

### Constants
```dart
// ✅ Good - lowerCamelCase for const, static const
static const int maxRetries = 3;
static const Duration defaultTimeout = Duration(seconds: 30);

// Also acceptable for truly global constants
const kDefaultPadding = 16.0;
```

### Files
```dart
// ✅ Good - snake_case
auth_repository.dart
app_user.dart
login_screen.dart

// ❌ Bad
AuthRepository.dart
appUser.dart
loginScreen.dart
```

## Documentation (Dartdoc)

### Classes
```dart
/// Manages user authentication and session state.
///
/// This repository handles:
/// - Email/password authentication
/// - Social login (Google, Apple)
/// - Session persistence
/// - Account deletion
///
/// See also:
/// - [AppUser] for the user data model
/// - [AuthGuard] for route protection
class AuthRepository {
  // ...
}
```

### Methods
```dart
/// Signs in a user with email and password.
///
/// Returns the authenticated [User] on success.
///
/// Throws:
/// - [FirebaseAuthException] if credentials are invalid
/// - [NetworkException] if offline
///
/// Example:
/// ```dart
/// final user = await authRepository.signIn(
///   email: 'user@example.com',
///   password: 'secret123',
/// );
/// ```
Future<User> signIn({
  required String email,
  required String password,
}) async {
  // ...
}
```

### Properties
```dart
/// The currently authenticated user, or `null` if not signed in.
User? get currentUser => _auth.currentUser;
```

## Code Organization

### Import Order
```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:io';

// 2. Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. Local imports (relative)
import '../common_widgets/app_button.dart';
import 'auth_repository.dart';
```

### File Structure
```
lib/
├── src/
│   ├── common_widgets/     # Reusable UI components
│   ├── constants/          # App-wide constants
│   ├── design_system/      # Theme, colors, typography
│   ├── features/           # Feature modules
│   │   └── auth/
│   │       ├── data/       # Repositories, data sources
│   │       ├── domain/     # Models, entities
│   │       └── presentation/ # Screens, controllers
│   ├── routing/            # Navigation
│   └── utils/              # Helpers, extensions
└── main.dart
```

## Best Practices

### State Management
- Use Riverpod for all state management
- Prefer `@riverpod` annotation over manual providers
- Keep providers focused and small

### Error Handling
```dart
// ✅ Good - Specific error handling
try {
  await authRepository.signIn(email, password);
} on FirebaseAuthException catch (e) {
  AppSnackBar.error(context, e.message);
}

// ❌ Bad - Catching everything
try {
  await authRepository.signIn(email, password);
} catch (e) {
  print(e); // Never just print
}
```

### Null Safety
```dart
// ✅ Good - Null-aware operators
final name = user?.displayName ?? 'Anonymous';

// ❌ Bad - Force unwrapping
final name = user!.displayName!;
```

## Running Checks

```bash
# Analyze code
flutter analyze

# Format code
dart format lib test

# Run all tests
flutter test
```
