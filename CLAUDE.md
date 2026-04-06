# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mube is a Flutter app that connects musicians, bands, studios, and contractors in Brazil. Built with Flutter 3.8+/Dart 3.8+, Riverpod 3, GoRouter, Firebase, and Freezed.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Code generation (after changing @riverpod, @freezed, or @JsonSerializable models)
flutter pub run build_runner build --delete-conflicting-outputs

# Static analysis
flutter analyze --fatal-infos lib test
# or use the project script:
./scripts/analyze_app.sh

# Format check
dart format --output=none --set-exit-if-changed lib test scripts

# Run all tests
flutter test

# Run a single test file
flutter test test/unit/auth/auth_repository_test.dart

# Run tests with coverage
flutter test --coverage

# Build release APK / App Bundle
flutter build apk --release
flutter build appbundle --release

# Deploy Firestore rules/indexes (PowerShell from project root)
.\deploy-firestore.ps1

# Deploy Cloud Functions
.\deploy-functions.ps1
# Single function:
.\deploy-functions.ps1 --only functions:manageBandInvite
```

## Architecture

### Source Layout

```
lib/
  main.dart              # Bootstrap: Firebase init, splash, error handlers, ProviderScope
  src/
    app.dart             # MaterialApp.router, theme, localization, push notification wiring
    core/                # App-wide infrastructure (providers, services, errors, config)
    design_system/       # Tokens (colors, spacing, typography, radius), theme, shared components
    features/            # Feature modules (auth, feed, chat, matchpoint, gigs, profile, etc.)
    routing/             # GoRouter tree, auth guard, route path constants
    shared/              # Cross-feature services (content moderation)
    utils/               # AppLogger, geohash, text helpers
```

### Feature Structure

Features live under `lib/src/features/` and typically follow `data/` → `domain/` → `presentation/`, though some use `providers/`, `controllers/`, `screens/`, `widgets/` variations. Follow the existing pattern of the feature you're modifying.

### State Management (Riverpod 3)

- `@riverpod` annotation for code-generated providers (preferred for new code)
- `StreamProvider` for auth state, Firestore live data
- `NotifierProvider` / `AsyncNotifierProvider` for screen controllers
- `ref.listenManual(...)` from stateful widget lifecycle methods for side effects (not `ref.listen` in `build`)
- `AsyncValue` is the standard loading/error contract

### Navigation (GoRouter)

- Route tree: `lib/src/routing/app_router.dart`
- Auth/onboarding redirects: `lib/src/routing/auth_guard.dart`
- Route constants: `lib/src/routing/route_paths.dart` — always use `RoutePaths` helpers, never hardcoded strings
- Main tabs use `StatefulShellRoute.indexedStack` (feed, search, matchpoint, chat, settings)

### Firebase Backend

- **Auth**: Email/password, Google, Apple sign-in
- **Firestore**: Primary data store. Field/collection names centralized in `lib/src/constants/firestore_constants.dart`
- **Storage**: Profile media, support attachments, video uploads
- **Cloud Functions**: `functions/src/` (TypeScript) — chat notifications, video transcoding, matchpoint, gigs, moderation
- **Messaging**: Push notifications via Cloud Functions + `push_notification_service.dart`

### Localization

- Template: `lib/l10n/app_pt.arb` (Portuguese Brazil, default)
- English: `lib/l10n/app_en.arb`
- Access: `AppLocalizations.of(context)`
- Generated output: `lib/l10n/generated/`

## Key Conventions

- **Language**: English for code, comments, commits. Portuguese for UI strings.
- **Logging**: Use `AppLogger`, never `print`.
- **Route references**: Use `RoutePaths` constants and helpers (`publicProfileById`, `conversationById`, `legalDetail`).
- **Firestore fields**: Use `FirestoreConstants`, not inline strings.
- **Design system**: Reuse existing tokens and components from `lib/src/design_system/` before creating feature-local UI.
- **Generated files**: Never hand-edit `*.g.dart` or `*.freezed.dart`. Run `build_runner` after changing annotated models.
- **Public identity**: Don't expose registration names for professional/band/studio profiles on public surfaces. Contractors may.
- **Theme**: Dark theme only (`AppTheme.darkTheme`), Material 3.
- **Versioning**: `pubspec.yaml` → `version: MAJOR.MINOR.PATCH+BUILD_NUMBER`. Must be updated before any release commit.

## Testing

```
test/
  helpers/       # pump_app.dart, test_fakes.dart, test_data.dart, firebase_mocks.dart
  unit/          # Repositories, controllers, providers, domain models
  widget/        # UI components and screens
  integration/   # Multi-layer flows (auth, profile, search)
  routing/       # Navigation contract tests
```

- Test fakes: `FakeAuthRepository`, `FakeFeedRepository`, `FakeChatRepository`, etc.
- Mocking: Mockito and Mocktail
- Integration UI tests: Patrol framework
- CI gate: `flutter analyze` and `flutter test` must pass before merging

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`):
- Runs `dart format` check, `flutter analyze`, and `flutter test` on push/PR to main/develop
- Generates APK on all builds, AAB on main
- Play Store publish only on `chore(release):` commits or manual `workflow_dispatch`
- Default Play Store track: `alpha`

Release scripts: `scripts/release_android.sh`, `scripts/release_ios.sh`, `scripts/upload_play_store_release.mjs`

### Release Process (IMPORTANT)

To trigger a build for the stores, the commit message on `main` **must** start with `chore(release):`. The CI checks `HEAD_COMMIT_MESSAGE` — merge commits from PRs use "Merge pull request #N..." which does NOT match.

**Correct workflow for releases:**

```bash
# 1. Develop and test on a feature branch, merge PR normally
# 2. After merge, bump version on main and commit with the right prefix:
git checkout main && git pull
# Edit pubspec.yaml: bump version (e.g. 1.6.11+147 → 1.6.12+148)
git add pubspec.yaml
git commit -m "chore(release): X.Y.Z+BUILD description"
git push origin main
# 3. CI detects chore(release): prefix → builds APK/AAB → publishes to Play Store alpha
```

**Alternative:** Trigger manually via GitHub Actions → Flutter CI → Run workflow → check "Publicar Android na Play Console".

**Common mistake:** Merging a PR with `--merge` (default) creates a merge commit that does NOT carry the `chore(release):` prefix. Always create a separate version bump commit on main after merging.
