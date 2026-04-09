# MatchPoint Card Regression Fix

Date: 2026-04-09

## Context

This file did not exist in the repository when reviewed on 2026-04-08/09.
The active architectural reference remains `docs/plans/2026-04-08-matchpoint-ios-restructure-plan.md`.

That 2026-04-08 plan is still valid as background, but it is no longer the
right execution plan for the current MatchPoint card/deck regression because:

- the async swipe command pipeline already exists
- the projected explore feed already exists
- Firestore rules and backend triggers for the new path already exist
- the remaining issue is concentrated in UI state and deck lifecycle

## Validated Status

Already implemented in code:

- projected explore feed read path in
  `lib/src/features/matchpoint/data/matchpoint_feed_repository.dart`
- async swipe command documents plus fallback/outbox in
  `lib/src/features/matchpoint/data/matchpoint_swipe_command_repository.dart`
- backend command processor and feed refresh triggers in
  `functions/src/matchpoint.ts`
- client-side queue/drain orchestration in
  `lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart`

Still true from the older plan:

- the MatchPoint controller still carries too much orchestration
- the legacy callable path still exists as fallback
- the read path still hydrates user documents and can still fall back to the
  legacy query path

Not the right scope for this fix:

- backend file splitting
- quota repository extraction
- full removal of the legacy callable

## Current Problem

The active regression is not primarily a backend transport problem.
It is a deck identity and widget lifecycle problem in the MatchPoint explore UI.

Validated risks in the current app code:

1. Deck identity must not be coupled to transient UI state.
   Pending queue state and undo availability can change during a swipe session,
   but they must not reset the active deck.

2. Same-payload refreshes still need a fresh deck session.
   A provider refresh that returns the same candidate IDs should still produce
   a fresh deck instance when the previous deck state is no longer valid.

3. Coverage needs to pin this behavior down.
   The regression area is small enough that widget tests should carry the
   contract.

## Fix Strategy

Keep the backend and controller architecture as-is for this change.
Apply a narrow UI/state fix in the app layer.

### App changes

Target files:

- `lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart`
- `test/widget/matchpoint/matchpoint_explore_screen_test.dart`

Changes:

- keep deck identity tied to the emitted candidate payload/session, not
  `canUndo`
- treat a fresh provider payload as a fresh deck session even when candidate
  IDs are the same
- add widget coverage for:
  - queue state changes must not change deck identity
  - a fresh provider payload with the same candidate IDs must create a new deck

### Non-goals

- no visual redesign
- no backend schema changes
- no removal of the legacy callable fallback in this patch

## Acceptance Criteria

The fix is complete when:

- toggling pending swipe state updates undo availability without resetting the
  deck
- a refreshed candidate payload with the same candidate IDs produces a fresh
  deck instance
- focused MatchPoint widget tests pass in a healthy local Flutter environment

## Rollback

If this patch causes regressions, revert only the explore-screen deck identity
change and restore the previous widget behavior. Do not roll back the async
command/feed architecture for this issue.
