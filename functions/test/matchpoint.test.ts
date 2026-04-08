jest.mock("firebase-admin", () => ({
  firestore: Object.assign(jest.fn(() => ({})), {
    FieldValue: {
      serverTimestamp: jest.fn(() => "mock-timestamp"),
    },
  }),
  messaging: jest.fn(() => ({send: jest.fn()})),
}));

import {
  buildMatchpointCommandResult,
  readMatchpointCommandRequest,
  readMatchpointSwipeAction,
} from "../src/matchpoint";

describe("matchpoint command helpers", () => {
  test("normalizes valid swipe actions", () => {
    expect(readMatchpointSwipeAction("like")).toBe("like");
    expect(readMatchpointSwipeAction("DISLIKE")).toBe("dislike");
  });

  test("rejects invalid swipe actions", () => {
    expect(() => readMatchpointSwipeAction("superlike")).toThrow(
      /action deve ser 'like' ou 'dislike'/
    );
  });

  test("reads command payload and applies commandId as fallback idempotency key", () => {
    expect(
      readMatchpointCommandRequest(
        {
          user_id: "user-1",
          target_user_id: "target-1",
          action: "like",
        },
        "cmd-1"
      )
    ).toEqual({
      userId: "user-1",
      targetUserId: "target-1",
      action: "like",
      idempotencyKey: "cmd-1",
    });
  });

  test("builds command result payload from action response", () => {
    expect(
      buildMatchpointCommandResult(
        {
          userId: "user-1",
          targetUserId: "target-1",
          action: "like",
          idempotencyKey: "cmd-2",
        },
        {
          success: true,
          isMatch: true,
          matchId: "match-1",
          conversationId: "conversation-1",
          remainingLikes: 42,
          message: "Match criado",
        }
      )
    ).toEqual({
      targetUserId: "target-1",
      action: "like",
      isMatch: true,
      matchId: "match-1",
      conversationId: "conversation-1",
      remainingLikes: 42,
      message: "Match criado",
    });
  });
});
