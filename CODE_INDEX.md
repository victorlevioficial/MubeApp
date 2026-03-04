# Code Index

Quick map of the current implementation. Use this file as an index, not as a replacement for reading the target feature.

## Root

- `lib/main.dart`
  - Runtime bootstrap: Firebase init, splash handling, error handling, deferred services, `ProviderScope`.
- `lib/firebase_options.dart`
  - Generated FlutterFire options.
- `ARCHITECTURE.md`
  - High-level system architecture and runtime boundaries.
- `README.md`
  - Project overview, setup, build, and test entry points.
- `AGENTS.md`
  - Short operational guide for AI-assisted work.
- `functions/`
  - Firebase Cloud Functions backend.

## `lib/l10n/`

- `app_pt.arb`
  - Portuguese strings.
- `app_en.arb`
  - English strings.
- `generated/`
  - Generated localization delegates.

## `lib/src/app.dart`

Root app widget:

- builds `MaterialApp.router`
- wires theme and localization
- wraps screens with offline indicator
- bootstraps push handling after login

## `lib/src/common_widgets/`

- `location_service.dart`
  - Shared location service helper used outside a single feature.
- `formatters/title_case_formatter.dart`
  - Shared input formatter.

## `lib/src/constants/`

- `app_constants.dart`
  - Global app constants.
- `firestore_constants.dart`
  - Firestore collection and field names used across the app.

## `lib/src/core/`

Shared infrastructure.

- `config/`
  - App/environment config helpers.
- `data/`
  - App-wide repositories and seed/config loading.
- `domain/`
  - Shared domain models such as `AppConfig`.
- `errors/`
  - Failures, mappers, and shared error abstractions.
- `mixins/`
  - Pagination and reusable logic mixins.
- `providers/`
  - App-level Riverpod providers.
- `services/`
  - Analytics, push notifications, image cache, remote config.
- `utils/`
  - Shared non-UI helpers such as rate limiter logic.

High-value files:

- `lib/src/core/providers/app_config_provider.dart`
- `lib/src/core/providers/connectivity_provider.dart`
- `lib/src/core/services/push_notification_service.dart`
- `lib/src/core/services/remote_config_service.dart`
- `lib/src/core/services/analytics/analytics_provider.dart`

## `lib/src/design_system/`

Shared UI foundation.

- `foundations/tokens/`
  - Colors, typography, spacing, radius, motion, icons, effects.
- `foundations/theme/`
  - App theme and scroll behavior.
- `components/`
  - Buttons, feedback, inputs, navigation, loading, patterns.
- `showcase/`
  - Internal design system gallery/demo sections.

Start here for UI work:

- `lib/src/design_system/foundations/theme/app_theme.dart`
- `lib/src/design_system/foundations/tokens/app_colors.dart`
- `lib/src/design_system/foundations/tokens/app_typography.dart`
- `lib/src/design_system/components/`

## `lib/src/routing/`

- `app_router.dart`
  - Main GoRouter tree and shell branches.
- `auth_guard.dart`
  - Redirect logic for splash, auth, onboarding, and profile recovery.
- `route_paths.dart`
  - Centralized route constants.

## `lib/src/shared/`

- `services/content_moderation_service.dart`
  - Shared moderation service used by upload/profile flows.

## `lib/src/utils/`

- `app_logger.dart`
  - Central logging abstraction.
- `auth_exception_handler.dart`
  - Auth-specific exception mapping helpers.
- `distance_calculator.dart`
  - Location distance helpers.
- `geohash_helper.dart`
  - Geohash utilities.
- `text_utils.dart`
  - Text normalization and string helpers.

## `lib/src/features/`

Feature-first modules. Confirm the local structure before editing because not all features use the same folder pattern.

### `address/`

- Address search and confirmation flow.

### `admin/`

- Maintenance and admin-only tools.

### `auth/`

- Sign-in, registration, password reset, email verification.
- Owns `auth_repository.dart` and `auth_remote_data_source.dart`.

Key files:

- `lib/src/features/auth/presentation/login_screen.dart`
- `lib/src/features/auth/presentation/register_screen.dart`
- `lib/src/features/auth/presentation/forgot_password_screen.dart`
- `lib/src/features/auth/presentation/email_verification_screen.dart`
- `lib/src/features/auth/presentation/register_controller.dart`
- `lib/src/features/auth/data/auth_repository.dart`
- `lib/src/features/auth/data/auth_remote_data_source.dart`

### `bands/`

- Band invite and member management flows.

### `chat/`

- Conversations, messages, unread state, and Firestore chat repository.

Key files:

- `lib/src/features/chat/presentation/conversations_screen.dart`
- `lib/src/features/chat/presentation/chat_screen.dart`
- `lib/src/features/chat/data/chat_repository.dart`
- `lib/src/features/chat/data/chat_providers.dart`
- `lib/src/features/chat/data/chat_unread_provider.dart`

### `developer/`

- Developer tools screen.

### `favorites/`

- Favorite state and favorite list flows.

### `feed/`

- Main feed, feed sections, featured profiles, pagination, image precache.

Key files:

- `lib/src/features/feed/presentation/feed_screen.dart`
- `lib/src/features/feed/presentation/feed_list_screen.dart`
- `lib/src/features/feed/presentation/feed_controller.dart`
- `lib/src/features/feed/presentation/feed_view_controller.dart`
- `lib/src/features/feed/presentation/controllers/feed_main_controller.dart`
- `lib/src/features/feed/presentation/controllers/feed_sections_controller.dart`
- `lib/src/features/feed/presentation/controllers/featured_profiles_controller.dart`
- `lib/src/features/feed/data/feed_repository.dart`
- `lib/src/features/feed/data/feed_remote_data_source.dart`
- `lib/src/features/feed/data/featured_profiles_repository.dart`

### `gallery/`

- Design system gallery screen for internal previewing.

### `legal/`

- Legal content, legal detail screens, and PDF-related utilities.

### `matchpoint/`

- Match flow, quota, ranking, setup wizard, candidates, history.

### `moderation/`

- Blocking and moderation repository logic.

### `notifications/`

- Notification repository, providers, and notification list UI.

### `onboarding/`

- User type selection, onboarding forms, steps, and permission prompt flow.

Key files:

- `lib/src/features/onboarding/presentation/onboarding_type_screen.dart`
- `lib/src/features/onboarding/presentation/onboarding_form_screen.dart`
- `lib/src/features/onboarding/presentation/onboarding_controller.dart`
- `lib/src/features/onboarding/presentation/onboarding_form_provider.dart`
- `lib/src/features/onboarding/providers/notification_permission_prompt_provider.dart`

### `profile/`

- Current profile, public profile, edit profile, invites, media handling.

Key files:

- `lib/src/features/profile/presentation/profile_screen.dart`
- `lib/src/features/profile/presentation/edit_profile_screen.dart`
- `lib/src/features/profile/presentation/profile_controller.dart`
- `lib/src/features/profile/presentation/public_profile_screen.dart`
- `lib/src/features/profile/presentation/public_profile_controller.dart`
- `lib/src/features/profile/presentation/edit_profile/controllers/edit_profile_controller.dart`
- `lib/src/features/profile/presentation/services/media_picker_service.dart`

### `search/`

- Search repository, filters, and paginated search state/UI.

### `settings/`

- Settings hub, privacy, blocked users, saved addresses.

### `splash/`

- Splash UI and bootstrap state providers.

### `storage/`

- Upload repository, compression, validation.

Key files:

- `lib/src/features/storage/data/storage_repository.dart`
- `lib/src/features/storage/domain/image_compressor.dart`
- `lib/src/features/storage/domain/upload_validator.dart`

### `support/`

- Support screen, ticket creation, ticket list/detail, FAQ data.

Key files:

- `lib/src/features/support/presentation/support_screen.dart`
- `lib/src/features/support/presentation/create_ticket_screen.dart`
- `lib/src/features/support/presentation/ticket_list_screen.dart`
- `lib/src/features/support/presentation/ticket_detail_screen.dart`
- `lib/src/features/support/presentation/support_controller.dart`
- `lib/src/features/support/data/support_repository.dart`
- `lib/src/features/support/data/faq_data.dart`

## Backend

### `functions/`

Firebase Cloud Functions implementation.

Start here when the task crosses into backend automation:

- `functions/src/index.ts`

## Tests

```text
test/
  helpers/
  integration/
  routing/
  src/
  unit/
  widget/
```

Useful files:

- `test/README.md`
- `test/helpers/pump_app.dart`
- `test/helpers/test_utils.dart`

## Where To Start By Task

- Auth bug: `lib/src/features/auth/`
- Feed bug: `lib/src/features/feed/`
- Chat bug: `lib/src/features/chat/`
- Routing issue: `lib/src/routing/`
- Design/UI change: `lib/src/design_system/` and target feature
- Upload/media issue: `lib/src/features/storage/`, `lib/src/features/profile/`, `lib/src/shared/services/content_moderation_service.dart`
- Push/notification issue: `lib/src/core/services/push_notification_service.dart`, `lib/src/features/notifications/`, `functions/src/index.ts`

Last reviewed: 2026-03-04
