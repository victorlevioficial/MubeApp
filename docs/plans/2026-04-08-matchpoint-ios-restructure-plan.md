# MatchPoint iOS Restructure Plan

Date: 2026-04-08

## Goal

Restructure MatchPoint to remove native Firebase pressure from the UI hot path on iOS.

This plan is based on:

- persistent Crashlytics issue `a37e597aefbf9996be2bca31f3a81ad9`
- same Swift Concurrency variant from `1.6.0` through `1.6.27`
- current app architecture in:
  - `lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart`
  - `lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart`
  - `functions/src/matchpoint.ts`
  - `firestore.rules`

## Problem Statement

The current MatchPoint flow mixes four concerns in the same runtime path:

1. UI deck lifecycle and gesture handling
2. candidate fetching and ranking
3. auth/App Check/session recovery
4. server-authoritative swipe processing

That coupling makes the feature fragile on iOS because a single user gesture or screen entry can trigger multiple native Firebase calls close together.

The recent fixes reduced specific triggers but did not eliminate the root issue. Crashlytics still reports the same native Swift Concurrency abort across releases, which strongly suggests the problem is not the visual structure of the screen itself.

## Current Architecture Risks

### 1. Controller owns too much orchestration

`matchpoint_controller.dart` currently owns:

- swipe queueing
- async command draining
- quota updates
- feedback emission
- candidate refresh after failure
- auth/session handling concerns

This creates a large blast radius for any change and makes testing UI behavior depend on backend timing.

### 2. Remote data source mixes reads, commands, and token recovery

`matchpoint_remote_data_source.dart` currently owns:

- candidate Firestore queries
- user batch fetches
- Cloud Functions calls
- Firebase Auth refresh behavior
- App Check refresh behavior

This is too much responsibility for one adapter and keeps native platform calls close to render-time behavior.

### 3. Callable function is on the swipe hot path

`functions/src/matchpoint.ts` exposes `submitMatchpointAction` as a callable and performs:

- auth validation
- existing interaction lookup
- mutual-like lookup
- quota enforcement
- interaction persistence
- match creation
- match notification

The callable is correct from a business-rules standpoint, but it is the wrong transport shape for a gesture-sensitive mobile flow on iOS.

### 4. Read path is still device-computed

The candidate ranking path still performs ranking/scoring on the client after Firestore reads. Even after simplifications, this keeps MatchPoint dependent on multiple native crossings before the deck is stable.

## Target Architecture

Split MatchPoint into three explicit layers.

### A. Read Model

Purpose: feed the UI with already-prepared data.

Target:

- `MatchpointReadRepository`
- `MatchpointFeedSnapshot`
- one stable read surface for the explore deck

Preferred shape:

- client reads one precomputed feed document or one narrow collection query
- ranking happens server-side or in a background pipeline
- UI receives a plain ordered list plus metadata

### B. Command Model

Purpose: process likes/dislikes outside the gesture frame.

Target:

- client writes a command document, not a callable
- backend processes command asynchronously
- client observes command result or eventual state projection

Preferred shape:

- new collection such as `matchpointCommands/{commandId}`
- command fields:
  - `user_id`
  - `target_user_id`
  - `action`
  - `client_created_at`
  - `status`
  - `result`
  - `idempotency_key`

Processing model:

- client appends command
- `onDocumentCreated` trigger validates and processes
- backend updates command result and writes interaction/match side effects

Why this is better:

- no callable on the swipe gesture
- no immediate Functions round-trip required to animate the card away
- retries and idempotency move to the backend

### C. Projection / Aggregates

Purpose: remove live recomputation from the app.

Target:

- materialized user-facing documents for:
  - remaining likes
  - matchpoint stats
  - candidate feed
  - swipe result state

Preferred sources:

- `users/{uid}` lightweight counters for quota
- `matchpointStats/{uid}` for analytics/debuggable state
- `matchpointFeeds/{uid}/items/{candidateId}` or equivalent feed snapshot

## Proposed Execution Plan

### Phase 0. Freeze the design target

Duration: same day

Deliverables:

- agree that the current MatchPoint UI stays visually intact
- treat this as transport/runtime refactor, not screen redesign
- stop incremental crash hotfixes in the current path unless they are rollback/safety-only

### Phase 1. Define new domain boundaries

Duration: 1 day

App work:

- introduce explicit interfaces:
  - `MatchpointFeedRepository`
  - `MatchpointSwipeCommandRepository`
  - `MatchpointQuotaRepository`
- move the current mixed adapter behind transitional wrappers

Backend work:

- define command document schema
- define feed/projection schema
- define idempotency rules for swipe commands

Acceptance:

- no presentation-layer file imports `cloud_functions` or token/App Check helpers directly or indirectly through feature logic assumptions

### Phase 2. Replace callable swipe transport

Duration: 1 to 2 days

Backend:

- add `onDocumentCreated` processor for swipe commands
- move business rules from `submitMatchpointAction` into shared internal functions
- keep callable temporarily only for compatibility/fallback

App:

- write swipe commands to Firestore
- mark local card as consumed immediately
- listen for command result asynchronously

Acceptance:

- swipe gesture no longer depends on Cloud Functions callable completion
- MatchPoint controller does not perform auth preflight or session-retry orchestration

### Phase 3. Introduce read projection for explore

Duration: 2 to 3 days

Backend:

- create precomputed explore feed per user
- feed generation can be:
  - lazy on profile update / location update
  - scheduled refresh
  - trigger-based refresh after relevant changes

App:

- `MatchpointExploreScreen` reads only the projected feed
- remove client-side ranking/scoring path from the hot path

Acceptance:

- opening MatchPoint does not run multi-step ranking logic on device
- explore screen depends on one stable read surface

### Phase 4. Remove MatchPoint-specific auth/App Check recovery from feature code

Duration: 1 day

App:

- remove MatchPoint-only token refresh orchestration from the feature module
- let shared Firebase infrastructure handle session validity at app level

Acceptance:

- `matchpoint_controller.dart` no longer contains session recovery policy
- `matchpoint_remote_data_source.dart` no longer mixes candidate reads with security-token recovery logic

### Phase 5. Clean migration and cutover

Duration: 1 day

Tasks:

- enable new path behind feature flag
- add fallback kill switch per platform
- migrate old code paths gradually
- remove deprecated callable usage after validation window

Acceptance:

- iOS uses only the new command path
- old callable path is either deleted or retained only as controlled fallback

## Recommended File-Level Refactor

### App

Create:

- `lib/src/features/matchpoint/data/matchpoint_feed_repository.dart`
- `lib/src/features/matchpoint/data/matchpoint_swipe_command_repository.dart`
- `lib/src/features/matchpoint/domain/matchpoint_feed_snapshot.dart`
- `lib/src/features/matchpoint/domain/matchpoint_swipe_command.dart`
- `lib/src/features/matchpoint/domain/matchpoint_swipe_command_result.dart`

Reduce responsibility in:

- `lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart`
- `lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart`

Keep UI mostly intact in:

- `lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart`
- `lib/src/features/matchpoint/presentation/widgets/match_swipe_deck.dart`

### Backend

Refactor:

- `functions/src/matchpoint.ts`

Split into:

- command processor
- feed/projection builder
- quota/stat updater
- notification sender

Potential new files:

- `functions/src/matchpoint_commands.ts`
- `functions/src/matchpoint_feed.ts`
- `functions/src/matchpoint_stats.ts`
- `functions/src/matchpoint_notifications.ts`
- `functions/src/matchpoint_shared.ts`

### Security Rules

Update:

- `firestore.rules`

Add:

- client create permissions only for command documents under strict ownership rules
- continue denying direct client writes to `interactions` and `matches`

## Rollout Strategy

### Step 1

Land backend command path and projection schema without switching the app.

### Step 2

Add app support behind a feature flag:

- `matchpoint_v2_ios`

### Step 3

Switch iOS internal builds to command path first.

### Step 4

Compare:

- crash volume
- command completion rate
- swipe-to-result latency
- match creation correctness

### Step 5

Retire old path after validation.

## Instrumentation Plan

Do not rely on Crashlytics breadcrumbs in the hot path.

Track operational state through:

- Firestore command status fields
- backend structured logs
- analytics events emitted after command completion, not during gesture

Useful metrics:

- command create count
- command success count
- command failure count
- average command processing latency
- feed snapshot age
- swipe result reconciliation failures

## Success Criteria

The restructure is successful when:

- MatchPoint no longer crashes on iOS internal testing during entry or swipe
- the explore screen can render from one stable read model
- swipe processing is no longer coupled to immediate callable completion
- MatchPoint feature code no longer owns custom auth/App Check recovery rules
- backend rules remain server-authoritative for interactions and matches

## Non-Goals

This plan does not aim to:

- redesign MatchPoint visuals
- change matching rules right now
- optimize Android first
- rewrite the entire feature from scratch

## Recommendation

Do not rewrite MatchPoint UI from zero.

Restructure the technical boundary instead:

- keep presentation mostly intact
- replace callable swipe transport with command documents
- move feed preparation to a projection/read model
- remove MatchPoint-specific native Firebase churn from the iOS gesture and entry paths
