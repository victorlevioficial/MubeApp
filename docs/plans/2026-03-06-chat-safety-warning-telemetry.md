# Chat Safety Warning + Telemetry Plan

## Goal
Warn users when they try to share contact or off-platform paths in chat, and log those attempts on the backend for product analysis.

## Non-goals
- No account strikes or suspensions in this phase.
- No message mutation or deletion in this phase.
- No second Firestore trigger for `conversations/{conversationId}/messages/{messageId}`.

## Current constraints
- Chat send from Flutter writes message + conversation metadata + both previews in one batch in `ChatRepository.sendMessage()`.
- Existing trigger `onMessageCreated` already runs on `conversations/{conversationId}/messages/{messageId}` and updates conversation metadata + push notifications.
- `initiateContact` can also create an `initialMessage` server-side.

Because of that, a new post-write moderation trigger would not be authoritative. The first robust phase should be warning + telemetry, not server-side message replacement.

## Phase 1 scope

### 1. Client-side analyzer
Create a pure Dart analyzer in `lib/src/features/chat/domain/chat_content_analyzer.dart`.

Responsibilities:
- detect direct contact patterns: phone, email, URL, `@handle`
- detect off-platform channels: WhatsApp, Instagram, Telegram, Discord, Linktree
- reduce false positives by combining channel keywords with contact-intent phrases
- return a structured result:
  - `isSuspicious`
  - `patterns`
  - `channels`
  - `severity`
  - `warningMessage`

Initial rule:
- direct contact patterns always warn
- social-channel keywords warn only when paired with contact intent or identifier patterns

### 2. Warning UX in chat
Integrate the analyzer in `lib/src/features/chat/presentation/chat_screen.dart`.

Behavior:
- analyze the trimmed text before send
- if suspicious:
  - show a modal warning dialog
  - keep the draft in the input
  - do not send on that attempt
  - log the attempt to the backend in fire-and-forget mode

Reuse:
- `AppConfirmationDialog`

### 3. Input hardening
Extend `AppTextField` to support:
- `enableSuggestions`
- `autocorrect`

Use both as `false` in the chat composer.

### 4. Backend shared safety module
Create `functions/src/chat_safety.ts`.

Responsibilities:
- `analyzeChatText(text)`
- `maskChatText(text)`
- `normalizeChatText(text)`
- `hashNormalizedChatText(text)`
- `buildChatSafetyEventId(...)`
- `logChatSafetyEvent(...)`

This module must be reused by:
- a new callable function for pre-send warnings
- the existing `onMessageCreated` trigger
- `initiateContact` when `initialMessage` is provided

### 5. Callable for pre-send warnings
Add a new callable function:
- `logChatPreSendWarning`

Behavior:
- requires authenticated user
- re-analyzes the submitted text on the server
- logs only if the server also considers the text suspicious
- uses deterministic event IDs with a short time bucket to deduplicate repeated taps

### 6. Server-side telemetry for messages that bypass the client warning
Extend the existing `onMessageCreated` trigger.

Behavior:
- analyze `messageData.text`
- if suspicious, log a `post_send_detected` event
- do not modify the message, previews, or notifications in this phase

Also extend `initiateContact` to log an `initial_message_detected` event when needed.

## Data model
Collection: `chatSafetyEvents`

Fields:
- `user_id`
- `conversation_id`
- `message_id` nullable
- `source`: `pre_send_warning` | `post_send_detected` | `initial_message_detected`
- `patterns`
- `channels`
- `severity`
- `masked_text`
- `normalized_hash`
- `message_length`
- `attempt_count`
- `client_patterns`
- `client_channels`
- `platform`
- `created_at`
- `last_seen_at`

Privacy rule for phase 1:
- store masked text, not raw text

## Verification

### Flutter
```bash
flutter test test/unit/features/chat/domain/chat_content_analyzer_test.dart
flutter test test/widget/features/chat/presentation/chat_screen_test.dart
```

### Functions
```bash
cd functions
npm test -- chat_safety.test.ts
npm run build
```

## Follow-up phase
If telemetry quality is good and false positives are acceptable, phase 2 can add:
- server-authoritative send flow
- stricter blocking for obvious contact sharing
- admin reporting dashboard over `chatSafetyEvents`
