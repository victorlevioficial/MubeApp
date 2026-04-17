import {Timestamp} from "firebase-admin/firestore";

import {
  buildUtcDayKey,
  incrementDailyCounter,
  isDailyLimitExceeded,
} from "../src/rate_limits";

describe("rate_limits", () => {
  test("buildUtcDayKey uses the UTC calendar day", () => {
    expect(
      buildUtcDayKey(new Date(Date.UTC(2026, 3, 10, 23, 59, 59)))
    ).toBe("2026-04-10");
  });

  test("incrementDailyCounter resets the count when the stored day changed", async () => {
    const setMock = jest.fn();
    const db = createFirestoreMock({
      snapshotData: {day_key: "2026-04-09", count: 9},
      setMock,
    });
    const now = Timestamp.fromDate(new Date(Date.UTC(2026, 3, 10, 12, 0, 0)));

    const result = await incrementDailyCounter({
      db: db as any,
      collectionName: "messageDailyCounters",
      subjectId: "user-1",
      limit: 200,
      now,
    });

    expect(result).toEqual({
      count: 1,
      dayKey: "2026-04-10",
      exceeded: false,
    });
    expect(setMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        subject_id: "user-1",
        day_key: "2026-04-10",
        count: 1,
        updated_at: now,
      }),
      {merge: true}
    );
  });

  test("incrementDailyCounter marks the write as exceeded only after the limit", async () => {
    const db = createFirestoreMock({
      snapshotData: {day_key: "2026-04-10", count: 200},
    });
    const now = Timestamp.fromDate(new Date(Date.UTC(2026, 3, 10, 18, 0, 0)));

    const result = await incrementDailyCounter({
      db: db as any,
      collectionName: "messageDailyCounters",
      subjectId: "user-1",
      limit: 200,
      now,
    });

    expect(result.count).toBe(201);
    expect(result.exceeded).toBe(true);
  });

  test("isDailyLimitExceeded is strict about crossing the limit", () => {
    expect(isDailyLimitExceeded(10, 10)).toBe(false);
    expect(isDailyLimitExceeded(11, 10)).toBe(true);
  });
});

function createFirestoreMock({
  snapshotData,
  setMock = jest.fn(),
}: {
  snapshotData: Record<string, unknown>;
  setMock?: jest.Mock;
}) {
  const docRef = {id: "user-1"};
  const getMock = jest.fn(async () => ({
    data: () => snapshotData,
  }));

  return {
    collection: jest.fn(() => ({
      doc: jest.fn(() => docRef),
    })),
    runTransaction: jest.fn(
      async (
        handler: (transaction: {
          get: typeof getMock;
          set: typeof setMock;
        }) => Promise<unknown>
      ) => handler({get: getMock, set: setMock})
    ),
  } as const;
}
