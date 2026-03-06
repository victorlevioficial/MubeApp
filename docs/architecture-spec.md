# Technical Specification Document

**Project**: Mube  
**Platform**: Flutter (mobile-first)  
**Architecture Style**: Feature-first app with Riverpod + GoRouter + Firebase

## 1. High-Level Architecture

The application is organized by feature under `lib/src/features`, with shared infrastructure in `core/`, UI primitives in `design_system/`, centralized navigation in `routing/`, and a small cross-feature area in `shared/`.

This is not a rigid clean-architecture template. Most features follow a variation of `data/`, `domain/`, and `presentation/`, but some also use `providers/`, `controllers/`, `screens/`, and `widgets/`.

### 1.1 Folder Structure (`lib/src`)

- `features/`
  - functional modules such as auth, profile, feed, search, chat, favorites, support and matchpoint
- `core/`
  - app-wide config, services, errors, shared providers and utilities
- `design_system/`
  - tokens, theme and reusable UI components
- `routing/`
  - centralized `GoRouter`, guards and route path constants
- `shared/`
  - cross-feature behavior that does not belong to a single feature
- `utils/`
  - global utility helpers such as logging and auth exception mapping

## 2. Technology Stack

### 2.1 Core Frameworks

- Flutter `3.8+`
- Dart `3.8+`
- Firebase Auth, Firestore, Storage, Messaging, Analytics, Remote Config and App Check

### 2.2 State Management

- Riverpod `3`
- wide use of `@riverpod`, `NotifierProvider`, `AsyncNotifierProvider`, `Provider` and `StreamProvider`
- `AsyncValue` is the default loading/error contract in many controllers
- stateful UI side effects should use `ref.listenManual(...)` from lifecycle methods when rebuild safety matters

### 2.3 Navigation

- GoRouter with centralized route tree in `lib/src/routing/app_router.dart`
- route constants and helpers in `lib/src/routing/route_paths.dart`
- `StatefulShellRoute.indexedStack` preserves the main shell branches
- `AuthGuard` centralizes auth and onboarding redirects
- public route logic includes dynamic legal routes under `/legal/:type`

### 2.4 Data Layer & Backend

- Firebase Auth for session identity
- Firestore as primary data store
- Firebase Storage for media uploads
- Cloud Functions for backend-triggered logic such as notifications

## 3. Key Technical Patterns

### 3.1 Error Handling

- repositories commonly return `Future<Either<Failure, T>>`
- failures live under `lib/src/core/errors/`
- auth-specific Firebase errors are mapped through shared handlers instead of leaking raw platform messages to the UI

### 3.2 Dependency Injection

- Riverpod is the DI container
- repositories, services and configuration are exposed through providers
- screens watch state; controllers and repositories own mutation boundaries

### 3.3 Runtime Bootstrap

- native splash is preserved at startup
- Firebase and app services initialize before splash removal
- a Flutter loading view is rendered during bootstrap instead of a blank frame
- the splash is removed only after bootstrap completion or failure handling

### 3.4 Public Identity Contract

Public surfaces should not expose registration names for profile types that require a public brand name.

Current contract:

- professional -> public artistic name or generic fallback
- band -> band name or generic fallback
- studio -> studio name or generic fallback
- contractor -> may expose registration name

This contract affects feed, search, favorites, matchpoint and related tests.

### 3.5 Cross-Feature Coordination

- prefer provider observation and invalidation over direct controller-to-controller calls
- feature code should not manually reload unrelated features when a domain event happens
- recent stabilization moved blocked-user refresh behavior toward provider-driven coordination

## 4. Third-Party Integrations

- geolocation: `geolocator`
- media picking and validation: `image_picker`, compression/validation helpers
- serialization and codegen: `freezed`, `json_serializable`, `riverpod_generator`

## 5. Testing and Quality Gates

Active test layers:

- unit tests
- widget tests
- integration-style flow tests
- route contract tests

Required quality gates:

- `./scripts/analyze_app.sh`
- `flutter test`

As of `2026-03-04`, both are expected to be green in the main workspace.
