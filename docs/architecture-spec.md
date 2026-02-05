# Technical Specification Document

**Project**: Mube
**Platform**: Flutter (Mobile)
**Architecture Style**: Feature-First Clean Architecture

## 1. High-Level Architecture
The application follows a **Domain-Driven Design (DDD)** inspired structure, organized by Features. Layers are clearly separated to ensure testability and maintainability.

### 1.1 Folder Structure (`lib/src`)
*   **`features/`**: Functional modules (Auth, Profile, MatchPoint, etc.). Each feature contains:
    *   `domain/`: Entities, Models, Failure definitions (Pure Dart).
    *   `data/`: Repositories, DTOs, API Data Sources (Dart + Infrastructure).
    *   `presentation/`: Widgets, Controllers/Notifiers (Flutter + Riverpod).
*   **`core/`**: Shared singleton services (Analytics, Logger).
*   **`design_system/`**: Reusable UI components (Atoms, Molecules) and Tokens (Colors, Typography).
*   **`routing/`**: Navigation logic (`GoRouter` configuration).

## 2. Technology Stack

### 2.1 Core Frameworks
*   **Flutter**: UI Framework (SDK >=3.8.0).
*   **Dart**: Language (v3+ with Records, Patterns).

### 2.2 State Management
*   **Riverpod (v2.0+)**: Primary state management solution.
    *   Uses `@riverpod` annotations (Code Generation).
    *   AsyncValue for handling loading/error states.
    *   Provider Scoping for efficient rebuilds.

### 2.3 Navigation
*   **GoRouter**: Declarative routing.
    *   Deep linking support.
    *   Guard logic (`AuthGuard`) for protected routes.
    *   ShellRoute for Bottom Navigation preservation.

### 2.4 Data Layer & Backend
*   **Firebase**: Serverless Backend.
    *   **Authentication**: User identity management.
    *   **Firestore**: NoSQL Database for main data.
    *   **Storage**: Media file hosting (Images, Videos).
    *   **Cloud Functions** (Implied): Server-side logic for complex operations.

## 3. Key Technical Patterns

### 3.1 Error Handling
*   **Functional Approach**: Uses `fpdart` library.
*   **Either Pattern**: Repositories return `Future<Either<Failure, T>>` instead of throwing exceptions.
*   **Failure Class**: Custom exception wrapper for typed error handling (Network, Auth, Validation).

### 3.2 Dependency Injection
*   **Riverpod**: Acts as the Service Locator / DI container.
*   **RepositoryProvider**: Exposes data layer instances to controllers.

### 3.3 Form Handling
*   **Controllers**: standard `TextEditingController` with reactive validation via Riverpod.
*   **Formatters**: `mask_text_input_formatter` for specific inputs (Phone).

## 4. Third-Party Integrations
*   **Maps/Geolocation**: `geolocator` for device location.
*   **Media**: `image_picker`, `video_compress` for handling uploads.
*   **Audio**: `flutter_audio_capture`, `pitch_detector_dart` for Guitar Tuner feature.
*   **Payment/Subscription**: Likely configured but details pending deep dive.

## 5. Build & CI/CD
*   **Flavors**: Configuration for Dev/Prod environments.
*   **Code Generation**: `build_runner` used for:
    *   `freezed` (Immutable Models).
    *   `riverpod_generator`.
    *   `json_serializable`.
