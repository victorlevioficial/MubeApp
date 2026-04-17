import {Timestamp} from "firebase-admin/firestore";

export const MESSAGE_DAILY_LIMIT = 200;
export const REPORT_DAILY_LIMIT = 10;

type FirestoreDocLike = unknown;

type FirestoreSnapshotLike = {
  data(): Record<string, unknown> | undefined;
};

type FirestoreTransactionLike = {
  get(ref: FirestoreDocLike): Promise<FirestoreSnapshotLike>;
  set(
    ref: FirestoreDocLike,
    data: Record<string, unknown>,
    options: {merge: boolean}
  ): unknown;
};

type FirestoreCollectionLike = {
  doc(id: string): FirestoreDocLike;
};

type FirestoreLike = {
  collection(name: string): FirestoreCollectionLike;
  runTransaction<T>(
    updateFn: (transaction: FirestoreTransactionLike) => Promise<T>
  ): Promise<T>;
};

type DailyCounterResult = {
  count: number;
  dayKey: string;
  exceeded: boolean;
};

function padTwoDigits(value: number): string {
  return value.toString().padStart(2, "0");
}

export function buildUtcDayKey(date: Date = new Date()): string {
  return [
    date.getUTCFullYear(),
    padTwoDigits(date.getUTCMonth() + 1),
    padTwoDigits(date.getUTCDate()),
  ].join("-");
}

export function startOfUtcDay(date: Date = new Date()): Date {
  return new Date(Date.UTC(
    date.getUTCFullYear(),
    date.getUTCMonth(),
    date.getUTCDate()
  ));
}

export function isDailyLimitExceeded(count: number, limit: number): boolean {
  return count > limit;
}

export async function incrementDailyCounter({
  db,
  collectionName,
  subjectId,
  limit,
  now = Timestamp.now(),
}: {
  db: FirestoreLike;
  collectionName: string;
  subjectId: string;
  limit: number;
  now?: Timestamp;
}): Promise<DailyCounterResult> {
  const dayKey = buildUtcDayKey(now.toDate());
  const counterRef = db.collection(collectionName).doc(subjectId);

  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(counterRef);
    const data = snapshot.data() || {};
    const storedDayKey = typeof data.day_key === "string" ? data.day_key : "";
    const storedCount = typeof data.count === "number" ? data.count : 0;
    const nextCount = storedDayKey === dayKey ? storedCount + 1 : 1;

    transaction.set(counterRef, {
      subject_id: subjectId,
      day_key: dayKey,
      count: nextCount,
      updated_at: now,
    }, {merge: true});

    return {
      count: nextCount,
      dayKey,
      exceeded: isDailyLimitExceeded(nextCount, limit),
    };
  });
}
