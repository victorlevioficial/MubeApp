import firebaseFunctionsTest from "firebase-functions-test";

type StoredDoc = Record<string, unknown>;

const store = new Map<string, StoredDoc>();
const writeLog = {
  sets: [] as Array<{path: string; data: StoredDoc; options?: unknown}>,
  deletes: [] as string[],
};

function cloneData(data?: StoredDoc): StoredDoc | undefined {
  if (!data) return undefined;
  return JSON.parse(JSON.stringify(data));
}

function mergeData(current: StoredDoc | undefined, next: StoredDoc): StoredDoc {
  return {
    ...(current ?? {}),
    ...next,
  };
}

function createSnapshot(path: string, data?: StoredDoc) {
  return {
    exists: data !== undefined,
    id: path.split("/").pop(),
    data: () => cloneData(data),
  };
}

function applySet(path: string, data: StoredDoc, options?: unknown) {
  writeLog.sets.push({path, data: cloneData(data) ?? {}, options});
  const shouldMerge =
    options !== null &&
    typeof options === "object" &&
    (options as {merge?: boolean}).merge === true;
  const nextData = shouldMerge ? mergeData(store.get(path), data) : data;
  store.set(path, cloneData(nextData) ?? {});
}

function applyDelete(path: string) {
  writeLog.deletes.push(path);
  store.delete(path);
}

function createDocRef(path: string) {
  return {
    path,
    id: path.split("/").pop(),
    get: jest.fn(async () => createSnapshot(path, store.get(path))),
    set: jest.fn(async (data: StoredDoc, options?: unknown) => {
      applySet(path, data, options);
    }),
    delete: jest.fn(async () => {
      applyDelete(path);
    }),
  };
}

const firestoreMock = {
  collection: jest.fn((collectionName: string) => ({
    doc: jest.fn((docId: string) => createDocRef(`${collectionName}/${docId}`)),
  })),
  runTransaction: jest.fn(async (handler: (tx: unknown) => unknown) => {
    const transaction = {
      get: jest.fn(async (docRef: ReturnType<typeof createDocRef>) => docRef.get()),
      set: jest.fn(
        async (
          docRef: ReturnType<typeof createDocRef>,
          data: StoredDoc,
          options?: unknown
        ) => {
          applySet(docRef.path, data, options);
        }
      ),
      delete: jest.fn(async (docRef: ReturnType<typeof createDocRef>) => {
        applyDelete(docRef.path);
      }),
    };

    return handler(transaction);
  }),
};

const authMock = {
  deleteUser: jest.fn().mockResolvedValue(undefined),
};

jest.mock("firebase-admin", () => ({
  initializeApp: jest.fn(),
  firestore: Object.assign(jest.fn(() => firestoreMock), {
    FieldValue: {
      serverTimestamp: jest.fn(() => "mock-timestamp"),
    },
  }),
  auth: jest.fn(() => authMock),
}));

import {deleteAccount, setPublicUsername} from "../src/users";

const testEnv = firebaseFunctionsTest();

describe("users Cloud Functions", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    store.clear();
    writeLog.sets = [];
    writeLog.deletes = [];
  });

  afterAll(() => {
    testEnv.cleanup();
  });

  describe("setPublicUsername", () => {
    test("throws unauthenticated when uid is missing", async () => {
      const wrapped = testEnv.wrap(setPublicUsername);

      await expect(
        wrapped({data: {username: "mube.oficial"}, auth: null} as never)
      ).rejects.toThrow(/autenticado/);
    });

    test("claims a normalized public username and syncs the user doc", async () => {
      store.set("users/user123", {
        uid: "user123",
        email: "user@example.com",
      });

      const wrapped = testEnv.wrap(setPublicUsername);
      const result = await wrapped({
        data: {username: "@Mube.Oficial"},
        auth: {uid: "user123"},
      } as never);

      expect(result).toEqual({
        username: "mube.oficial",
        previousUsername: null,
        changed: true,
      });
      expect(store.get("users/user123")).toEqual({
        uid: "user123",
        email: "user@example.com",
        username: "mube.oficial",
      });
      expect(store.get("publicUsernames/mube.oficial")).toEqual({
        uid: "user123",
        username: "mube.oficial",
        createdAt: "mock-timestamp",
        updatedAt: "mock-timestamp",
      });
    });

    test("releases the previous username when the handle changes", async () => {
      store.set("users/user123", {
        uid: "user123",
        email: "user@example.com",
        username: "old.handle",
      });
      store.set("publicUsernames/old.handle", {
        uid: "user123",
        username: "old.handle",
      });

      const wrapped = testEnv.wrap(setPublicUsername);
      const result = await wrapped({
        data: {username: "novo.handle"},
        auth: {uid: "user123"},
      } as never);

      expect(result).toEqual({
        username: "novo.handle",
        previousUsername: "old.handle",
        changed: true,
      });
      expect(store.has("publicUsernames/old.handle")).toBe(false);
      expect(store.get("publicUsernames/novo.handle")).toEqual({
        uid: "user123",
        username: "novo.handle",
        createdAt: "mock-timestamp",
        updatedAt: "mock-timestamp",
      });
    });

    test("rejects usernames already reserved by another user", async () => {
      store.set("users/user123", {
        uid: "user123",
        email: "user@example.com",
      });
      store.set("publicUsernames/mube.oficial", {
        uid: "other-user",
        username: "mube.oficial",
      });

      const wrapped = testEnv.wrap(setPublicUsername);

      await expect(
        wrapped({
          data: {username: "mube.oficial"},
          auth: {uid: "user123"},
        } as never)
      ).rejects.toThrow(/ja esta em uso/);

      expect(store.get("users/user123")).toEqual({
        uid: "user123",
        email: "user@example.com",
      });
    });
  });

  describe("deleteAccount", () => {
    test("throws unauthenticated error if uid is missing", async () => {
      const wrapped = testEnv.wrap(deleteAccount);

      await expect(wrapped({data: {}, auth: null} as never)).rejects.toThrow(
        /must be called while authenticated/
      );
    });

    test("backs up, releases username, deletes firestore data and auth user", async () => {
      store.set("users/user123", {
        nome: "Test User",
        email: "test@example.com",
        username: "mube.oficial",
      });
      store.set("publicUsernames/mube.oficial", {
        uid: "user123",
        username: "mube.oficial",
      });

      const wrapped = testEnv.wrap(deleteAccount);
      const result = await wrapped({
        data: {},
        auth: {uid: "user123"},
      } as never);

      expect(result).toEqual({success: true});
      expect(store.get("deletedUsers/user123")).toEqual({
        nome: "Test User",
        email: "test@example.com",
        username: "mube.oficial",
        deleted_at: "mock-timestamp",
      });
      expect(store.has("users/user123")).toBe(false);
      expect(store.has("publicUsernames/mube.oficial")).toBe(false);
      expect(authMock.deleteUser).toHaveBeenCalledWith("user123");
    });

    test("still deletes auth user when firestore profile does not exist", async () => {
      const wrapped = testEnv.wrap(deleteAccount);
      const result = await wrapped({
        data: {},
        auth: {uid: "user456"},
      } as never);

      expect(result).toEqual({success: true});
      expect(authMock.deleteUser).toHaveBeenCalledWith("user456");
    });

    test("throws internal error on unexpected failures", async () => {
      authMock.deleteUser.mockRejectedValueOnce(new Error("Firebase Auth error"));

      const wrapped = testEnv.wrap(deleteAccount);

      await expect(
        wrapped({data: {}, auth: {uid: "user789"}} as never)
      ).rejects.toThrow(/An error occurred while attempting to delete the account/);
    });
  });
});
