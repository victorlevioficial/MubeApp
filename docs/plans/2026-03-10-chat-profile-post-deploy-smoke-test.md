# Chat + Profile Post-Deploy Smoke Test

## Goal
Validate the March 10, 2026 chat and public profile fixes in a real app session after the Cloud Functions deploy.

## Scope
- Lazy conversation creation
- Faster chat opening and inbox hydration
- Notification deep link directly into chat
- Faster public profile gallery and video thumbnail loading

## Prerequisites
1. Use a build generated after the March 10, 2026 deploy.
2. Prepare at least 2 regular user accounts:
   - `user_a`
   - `user_b`
3. Keep Firebase Console open for Firestore verification when needed.
4. Enable push notifications on at least one test device.
5. Prefer one warm-cache run and one cold-start run.

## Evidence to capture
- Device model and OS version
- Network type (`Wi-Fi` or `4G/5G`)
- Screen recording for failures
- `conversationId` when a chat-related check fails

## Flow 1: Direct chat from public profile
1. Ensure `user_a` and `user_b` do not already have a conversation.
2. With `user_a`, open the public profile of `user_b`.
3. Tap the CTA to open chat.
4. Before sending anything, check Firestore for `conversations/{sortedUidA_sortedUidB}`.
5. Send the first message.

Expected:
- The chat screen opens without waiting for a pre-created conversation.
- No `conversations/{id}` document exists before the first message.
- The conversation document is created only after the first message.
- The new chat appears in the inbox for both users after the first message.

## Flow 2: Gig acceptance should not auto-create chat
1. Create or reuse a gig where `user_b` applied and `user_a` can accept.
2. Accept the application as `user_a`.
3. Check Firestore and the inbox for both accounts before any message is sent.
4. Open chat from the gig flow.
5. Send the first message.

Expected:
- Accepting the application does not create a conversation by itself.
- No inbox preview appears before the first message.
- The chat opens as a draft and becomes real only after the first send.
- The resulting conversation behaves like a normal chat after creation.

## Flow 3: Matchpoint should reserve only the draft conversation
1. Generate a mutual match between `user_a` and `user_b`.
2. From the match success or matches screen, open the chat.
3. Check Firestore before sending a message.
4. Send the first message.

Expected:
- Match creation reserves the `conversationId`, but does not create the conversation document.
- The chat route opens correctly using the reserved ID.
- The conversation document is created on first message.
- The conversation remains reachable from the match flow after creation.

## Flow 4: Push notification deep link
1. Leave `user_a` with the app fully closed.
2. Send a new message from `user_b` to `user_a`.
3. Tap the push notification on the device.
4. Repeat once with the app in background instead of fully closed.

Expected:
- Tapping the notification opens the target conversation directly.
- The app does not stop in Home or Inbox first.
- The chat header can render with sender preview data before full stream hydration finishes.
- No duplicate chat route is pushed.

## Flow 5: Inbox warm-cache behavior
1. Open the inbox once and wait for the conversation list to load.
2. Leave and reopen the inbox in the same app session.
3. Close the app, reopen it, and open the inbox again.

Expected:
- Warm reopen shows previews faster than the first open.
- The inbox can render cached previews before the live refresh completes.
- There is no long blank loading state when conversations already exist.

## Flow 6: Public profile gallery performance
1. Open a public profile with mixed photo and video media.
2. Observe the first visible gallery row.
3. Scroll through at least 12 media items.
4. Return and reopen the same profile.

Expected:
- Profile content appears before rating metrics and band-member fetches finish.
- The first gallery items load progressively without blocking the whole screen.
- Video thumbnails and photos appear faster on the second open due to cache reuse.
- Scrolling does not pause while later thumbnails are fetched.

## Regression checks
1. Open an existing conversation that predates this change.
2. Send a second and third message in a freshly created conversation.
3. Open a chat from the in-app notifications list.

Expected:
- Existing chats still open normally.
- Sending follow-up messages remains stable.
- In-app notification navigation reaches the same conversation route correctly.

## Go / No-Go
Go if all are true:
1. No conversation is materialized before the first message in direct, gig, and matchpoint entry flows.
2. Notification taps land directly in the correct conversation.
3. Inbox warm open is visibly faster than the first open.
4. Public profile gallery starts rendering before non-critical profile data completes.

No-Go if any of these happen:
1. A chat document appears before the first message.
2. Notification tap lands outside the target chat.
3. Inbox stays blank for several seconds even with cached previews available.
4. Public profile media remains blocked behind metrics or band-member loading.
