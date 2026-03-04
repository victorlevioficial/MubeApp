# Architecture

## Overview

Mube is a Flutter app organized primarily by feature under `lib/src/features`, with shared infrastructure in `lib/src/core`, shared UI in `lib/src/design_system`, centralized routing in `lib/src/routing`, and a small cross-feature layer in `lib/src/shared`.

Main stack:

- Flutter + Dart 3.8+
- Riverpod 3
- GoRouter
- Firebase Auth, Firestore, Storage, Messaging, Analytics, Remote Config, App Check, Cloud Functions
- Freezed + JSON Serializable for immutable models and serialization

## Runtime Entry Flow

### `lib/main.dart`

Bootstraps the runtime:

- initializes Flutter bindings
- preserves native splash first
- initializes Firebase
- enables Firestore persistence and unlimited cache
- installs global Flutter and zone error handlers
- initializes logging
- schedules deferred services such as analytics, remote config, and font preload
- removes native splash only after bootstrap finishes or fails
- shows a real loading surface during bootstrap instead of a blank frame
- mounts `ProviderScope(child: MubeApp())`

### `lib/src/app.dart`

Owns the app shell:

- `MaterialApp.router`
- theme wiring through `AppTheme.darkTheme`
- localization delegates and supported locales
- offline indicator wrapper
- push notification tap handling and post-login push bootstrap
- router injection from Riverpod
- auth side effects subscribed with `ref.listenManual(...)` from widget lifecycle, not from `build`

## Source Layout

```text
lib/
  main.dart
  firebase_options.dart
  l10n/
  src/
    app.dart
    common_widgets/
    constants/
    core/
    design_system/
    features/
    routing/
    shared/
    utils/
```

Important notes:

- The project is feature-based, but not every feature strictly follows `data/domain/presentation`
- Some features also use `providers/`, `controllers/`, `screens/`, and `widgets/`
- Generated files (`*.g.dart`, `*.freezed.dart`) are part of the architecture but are not hand-edited

## Architectural Layers

### `lib/src/core/`

Shared infrastructure used across the app:

- `config/`: app-level config helpers
- `data/`: app-wide repositories and seed/config loading
- `domain/`: shared domain models such as `AppConfig`
- `errors/`: failures, mapping, and error abstractions
- `mixins/`: shared pagination utilities
- `providers/`: app-wide Riverpod providers
- `services/`: analytics, push notifications, image cache, remote config
- `utils/`: non-UI shared helpers such as rate limiting

### `lib/src/design_system/`

Shared UI primitives and theme system:

- `foundations/tokens/`: colors, spacing, typography, radius, motion, icons, effects
- `foundations/theme/`: theme and app scroll behavior
- `components/`: buttons, inputs, feedback, loading, navigation, patterns
- `showcase/`: internal gallery/demo surface

### `lib/src/features/`

Feature modules own most business behavior. Current feature set includes:

- `address`
- `admin`
- `auth`
- `bands`
- `chat`
- `developer`
- `favorites`
- `feed`
- `gallery`
- `legal`
- `matchpoint`
- `moderation`
- `notifications`
- `onboarding`
- `profile`
- `search`
- `settings`
- `splash`
- `storage`
- `support`

### `lib/src/routing/`

Navigation is centralized here:

- `app_router.dart`: main `GoRouter` tree
- `auth_guard.dart`: redirect logic
- `route_paths.dart`: route constants

### `lib/src/shared/`

Cross-feature services that do not fit cleanly in a single feature, currently including content moderation.

### `lib/src/utils/`

Global utilities such as `AppLogger`, text helpers, geohash helpers, distance utilities, and auth exception helpers.

## State Management

The app uses Riverpod 3 with a mixed but deliberate approach.

Common patterns:

- `Provider`
  - stateless dependencies and service wiring
- `StreamProvider`
  - auth, profile, and Firestore-backed live data
- `NotifierProvider` and `AsyncNotifierProvider`
  - screen controllers and async UI flows
- `@riverpod`
  - generator-backed providers used widely in newer code
- `ref.listenManual(...)`
  - preferred in stateful widgets when side effects must not be re-registered on rebuild

Representative files:

- `lib/src/core/providers/app_config_provider.dart`
- `lib/src/features/auth/data/auth_repository.dart`
- `lib/src/features/feed/presentation/feed_controller.dart`
- `lib/src/features/support/presentation/support_controller.dart`
- `lib/src/features/profile/presentation/public_profile_controller.dart`

Working convention:

- screens and widgets mostly `watch` state
- controllers own mutations and async orchestration
- repositories isolate Firebase and backend access
- failures and exceptions are mapped through `lib/src/core/errors/` where useful
- long-lived UI listeners should be attached from lifecycle methods and disposed explicitly

## Navigation Architecture

Navigation uses GoRouter with guarded redirects and a shell-based main app structure.

Key points:

- initial location starts at splash
- auth and onboarding redirects are centralized in `auth_guard.dart`
- the main app tabs are implemented with `StatefulShellRoute.indexedStack`
- main shell branches currently cover feed, search, matchpoint, chat, and settings
- route strings should come from `route_paths.dart`, not inline literals
- public route checks include dynamic legal routes under `/legal/:type`
- feature code should use `RoutePaths` helpers such as `publicProfileById`, `conversationById`, and `legalDetail`

Core files:

- `lib/src/routing/app_router.dart`
- `lib/src/routing/auth_guard.dart`
- `lib/src/routing/route_paths.dart`

## Data Access and Backend Boundaries

Repository/data-source patterns are used in backend-heavy areas.

Representative repositories:

- Auth: `lib/src/features/auth/data/auth_repository.dart`
- Feed: `lib/src/features/feed/data/feed_repository.dart`
- Chat: `lib/src/features/chat/data/chat_repository.dart`
- Matchpoint: `lib/src/features/matchpoint/data/matchpoint_repository.dart`
- Storage: `lib/src/features/storage/data/storage_repository.dart`
- Support: `lib/src/features/support/data/support_repository.dart`

Representative remote/data access files:

- `lib/src/features/auth/data/auth_remote_data_source.dart`
- `lib/src/features/feed/data/feed_remote_data_source.dart`
- `lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart`
- `lib/src/features/notifications/data/notification_repository.dart`

Constants for Firestore field and collection names are centralized in:

- `lib/src/constants/firestore_constants.dart`

## Important Runtime Flows

### Authentication and Profile

- auth state and current user profile are exposed from `auth_repository.dart`
- auth screens trigger repository/controller actions for login, register, password reset, email verification, and social sign-in
- profile persistence flows also go back through auth/profile repositories
- login and register flows map Firebase auth errors to app-facing failures through shared handlers
- `currentUserProfileProvider` is driven by auth state, without waiting on splash/bootstrap providers

Key files:

- `lib/src/features/auth/presentation/login_screen.dart`
- `lib/src/features/auth/presentation/register_screen.dart`
- `lib/src/features/auth/presentation/email_verification_screen.dart`
- `lib/src/features/auth/presentation/forgot_password_screen.dart`
- `lib/src/features/auth/data/auth_repository.dart`
- `lib/src/features/auth/data/auth_remote_data_source.dart`

### Feed

- feed state is orchestrated by controller layers in `feed_controller.dart`, `feed_view_controller.dart`, and `presentation/controllers/`
- repositories and remote data sources query Firestore and transform documents into feed models
- blocked-user changes now refresh feed through provider observation instead of direct cross-feature calls from profile/settings

Key files:

- `lib/src/features/feed/presentation/feed_screen.dart`
- `lib/src/features/feed/presentation/feed_controller.dart`
- `lib/src/features/feed/presentation/feed_view_controller.dart`
- `lib/src/features/feed/data/feed_repository.dart`
- `lib/src/features/feed/data/feed_remote_data_source.dart`

### Chat

- Firestore-backed conversation and message streams are exposed through providers
- repository methods handle writes and metadata updates
- backend Cloud Functions react to message creation for notification flows
- chat UI subscriptions that drive local side effects use lifecycle-managed listeners instead of `ref.listen` in `build`

Key files:

- `lib/src/features/chat/presentation/conversations_screen.dart`
- `lib/src/features/chat/presentation/chat_screen.dart`
- `lib/src/features/chat/data/chat_repository.dart`
- `lib/src/features/chat/data/chat_providers.dart`
- `functions/src/index.ts`

### Media Upload and Moderation

- media can be selected from profile and onboarding flows
- uploads pass through validation and compression where needed
- some profile media flows use shared moderation before persistence
- Firebase Storage upload results are then persisted back to Firestore documents

Key files:

- `lib/src/features/storage/data/storage_repository.dart`
- `lib/src/features/storage/domain/image_compressor.dart`
- `lib/src/features/storage/domain/upload_validator.dart`
- `lib/src/features/profile/presentation/services/media_picker_service.dart`
- `lib/src/shared/services/content_moderation_service.dart`

## Testing Reality

The repository has active coverage across:

- unit tests for repositories, controllers, providers, domain models, and guards
- widget tests for auth, feed, search, favorites, chat, settings, support, onboarding, profile, and design system
- integration-style tests for auth, profile, and search flows
- route contract tests in both `test/routing/` and `test/unit/routing/`

Operational expectation:

- `flutter analyze` stays clean
- `flutter test` is treated as a required green gate before further feature work
- `lib/src/features/profile/presentation/edit_profile/controllers/edit_profile_controller.dart`
- `lib/src/features/support/presentation/support_controller.dart`

## Firebase Integration

### Firebase Core

- `lib/main.dart`
- `lib/firebase_options.dart`

### Firebase Auth

- `lib/src/features/auth/data/auth_remote_data_source.dart`
- `lib/src/features/auth/data/auth_repository.dart`

Used for:

- email/password auth
- Google sign-in
- Apple sign-in
- session refresh and recovery
- email verification
- account deletion flows

### Cloud Firestore

Used by auth, feed, chat, notifications, support, moderation, favorites, and matchpoint flows.

Representative files:

- `lib/src/features/feed/data/feed_remote_data_source.dart`
- `lib/src/features/chat/data/chat_repository.dart`
- `lib/src/features/notifications/data/notification_repository.dart`
- `lib/src/features/support/data/support_repository.dart`
- `lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart`

### Firebase Storage

Used for profile media, support attachments, and related upload flows.

Representative files:

- `lib/src/features/storage/data/storage_repository.dart`
- `functions/src/video_transcode.ts`

### Cloud Functions

Client-side callers exist in auth, bands, and matchpoint flows.
Backend implementation lives under `functions/src/`.

Representative files:

- `lib/src/features/auth/data/auth_remote_data_source.dart`
- `lib/src/features/bands/data/invites_repository.dart`
- `lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart`
- `functions/src/index.ts`

### Firebase Messaging

- `lib/src/core/services/push_notification_service.dart`
- `lib/src/core/services/push_notification_event_bus.dart`
- `lib/src/app.dart`
- `functions/src/index.ts`

### Firebase Analytics

- `lib/src/core/services/analytics_service.dart`
- `lib/src/core/services/analytics/analytics_provider.dart`
- `lib/src/core/services/analytics/analytics_service.dart`

### Firebase Remote Config

- `lib/src/core/services/remote_config_service.dart`

### Firebase App Check

- `lib/src/features/auth/data/auth_remote_data_source.dart`
- `lib/src/features/splash/providers/app_bootstrap_provider.dart`

## Theme and Localization

Theme:

- main theme comes from `lib/src/design_system/foundations/theme/app_theme.dart`
- current runtime wiring uses `AppTheme.darkTheme`

Localization:

- `lib/l10n/app_pt.arb`
- `lib/l10n/app_en.arb`
- generated delegates under `lib/l10n/generated/`
- `lib/src/app.dart` currently wires `pt` and `en`, with `pt` as the default locale

## Testing Shape

High-level test structure:

```text
test/
  helpers/
  integration/
  routing/
  src/
  unit/
  widget/
```

See also:

- `test/README.md`

## Practical Rules

- treat the codebase as feature-first, not layer-first
- check the local pattern of the feature before introducing a new abstraction
- prefer existing design system components and tokens over feature-local UI primitives
- prefer `RoutePaths` over hardcoded routes
- prefer Firestore constants over inline field and collection names
- do not hand-edit generated files

Last reviewed: 2026-03-04
