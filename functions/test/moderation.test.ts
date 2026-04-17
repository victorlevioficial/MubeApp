jest.mock("firebase-admin", () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      where: jest.fn().mockReturnThis(),
      count: jest.fn(() => ({
        get: jest.fn(async () => ({
          data: () => ({count: 0}),
        })),
      })),
    })),
  })),
}));

import {isValidReport, shouldRateLimitReportCount} from "../src/moderation";

describe("moderation report guards", () => {
  test("accepts a valid user report", () => {
    expect(
      isValidReport({
        reporter_user_id: "user-1",
        reported_item_id: "user-2",
        reported_item_type: "user",
        reason: "Comportamento abusivo recorrente",
      })
    ).toBe(true);
  });

  test("rejects unsupported report types", () => {
    expect(
      isValidReport({
        reporter_user_id: "user-1",
        reported_item_id: "story-1",
        reported_item_type: "story",
        reason: "Conteudo inadequado",
      })
    ).toBe(false);
  });

  test("rejects message reports without conversation context", () => {
    expect(
      isValidReport({
        reporter_user_id: "user-1",
        reported_item_id: "message-1",
        reported_item_type: "message",
        reason: "Spam por mensagem",
      })
    ).toBe(false);
  });

  test("only rate limits after the daily report limit is exceeded", () => {
    expect(shouldRateLimitReportCount(10)).toBe(false);
    expect(shouldRateLimitReportCount(11)).toBe(true);
  });
});
