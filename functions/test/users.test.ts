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
  recursiveDelete: jest.fn(async (docRef: ReturnType<typeof createDocRef>) => {
    const prefix = `${docRef.path}/`;
    for (const path of [...store.keys()]) {
      if (path === docRef.path || path.startsWith(prefix)) {
        applyDelete(path);
      }
    }
  }),
};

const authMock = {
  deleteUser: jest.fn().mockResolvedValue(undefined),
};

const storageFileDeleteMock = jest.fn().mockResolvedValue(undefined);
const storageBucketMock = {
  deleteFiles: jest.fn().mockResolvedValue(undefined),
  file: jest.fn((path: string) => ({
    delete: (options?: unknown) => storageFileDeleteMock(path, options),
  })),
};

const cleanupUserFirestoreDataMock = jest.fn().mockResolvedValue({
  deletedDocuments: 0,
  recursivelyDeletedDocuments: 0,
  anonymizedDocuments: 0,
  detachedReferences: 0,
});

jest.mock("firebase-admin", () => ({
  initializeApp: jest.fn(),
  firestore: Object.assign(jest.fn(() => firestoreMock), {
    FieldValue: {
      serverTimestamp: jest.fn(() => "mock-timestamp"),
    },
  }),
  auth: jest.fn(() => authMock),
  storage: jest.fn(() => ({
    bucket: jest.fn(() => storageBucketMock),
  })),
}));

jest.mock("../src/account_deletion", () => ({
  cleanupUserFirestoreData: (...args: unknown[]) =>
    cleanupUserFirestoreDataMock(...args),
}));

import {deleteAccount, setPublicUsername} from "../src/users";

const testEnv = firebaseFunctionsTest();

describe("users Cloud Functions", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    store.clear();
    writeLog.sets = [];
    writeLog.deletes = [];
    authMock.deleteUser.mockResolvedValue(undefined);
    storageBucketMock.deleteFiles.mockResolvedValue(undefined);
    storageFileDeleteMock.mockResolvedValue(undefined);
    cleanupUserFirestoreDataMock.mockResolvedValue({
      deletedDocuments: 0,
      recursivelyDeletedDocuments: 0,
      anonymizedDocuments: 0,
      detachedReferences: 0,
    });
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

    test("redacts personal data, releases username and deletes the auth user", async () => {
      store.set("users/user123", {
        nome: "Test User",
        email: "test@example.com",
        username: "mube.oficial",
      });
      store.set("publicUsernames/mube.oficial", {
        uid: "user123",
        username: "mube.oficial",
      });
      store.set("users/user123/favorites/favorite-1", {
        createdAt: "mock-timestamp",
      });

      const wrapped = testEnv.wrap(deleteAccount);
      const result = await wrapped({
        data: {},
        auth: {uid: "user123"},
      } as never);

      expect(result).toEqual({success: true});
      expect(store.get("deletedUsers/user123")).toEqual({
        deletion_status: "firestore_complete",
        policy_version: 2,
        deleted_at: "mock-timestamp",
      });
      expect(cleanupUserFirestoreDataMock).toHaveBeenCalledWith(
        firestoreMock,
        "user123"
      );
      expect(store.has("users/user123")).toBe(false);
      expect(store.has("users/user123/favorites/favorite-1")).toBe(false);
      expect(store.has("publicUsernames/mube.oficial")).toBe(false);
      expect(writeLog.deletes).toEqual([
        "users/user123",
        "users/user123/favorites/favorite-1",
        "publicUsernames/mube.oficial",
      ]);
      expect(firestoreMock.recursiveDelete).toHaveBeenCalledWith(
        expect.objectContaining({path: "users/user123"})
      );
      expect(
        storageBucketMock.deleteFiles.mock.calls.map(([options]) => options)
      ).toEqual([
        {prefix: "profile_photos/user123/", force: true},
        {prefix: "gallery_photos/user123/", force: true},
        {prefix: "gallery_videos/user123/", force: true},
        {prefix: "gallery_videos_transcoded/user123/", force: true},
        {prefix: "gallery_thumbnails/user123/", force: true},
        {prefix: "stories_images/user123/", force: true},
        {prefix: "stories_videos_source/user123/", force: true},
        {prefix: "stories_videos_master/user123/", force: true},
        {prefix: "stories_videos_thumbs/user123/", force: true},
        {prefix: "support_tickets/user123/", force: true},
      ]);
      expect(storageFileDeleteMock.mock.calls).toEqual([
        ["profile_photos/user123", {ignoreNotFound: true}],
        ["profile_photos/user123.webp", {ignoreNotFound: true}],
        ["profile_photos/user123.jpg", {ignoreNotFound: true}],
        ["profile_photos/user123.jpeg", {ignoreNotFound: true}],
        ["profile_photos/user123.png", {ignoreNotFound: true}],
      ]);
      expect(authMock.deleteUser).toHaveBeenCalledWith("user123");
    });

    test("still deletes auth user when firestore profile does not exist", async () => {
      const wrapped = testEnv.wrap(deleteAccount);
      const result = await wrapped({
        data: {},
        auth: {uid: "user456"},
      } as never);

      expect(result).toEqual({success: true});
      expect(firestoreMock.recursiveDelete).toHaveBeenCalledWith(
        expect.objectContaining({path: "users/user456"})
      );
      expect(authMock.deleteUser).toHaveBeenCalledWith("user456");
    });

    test("releases the backed-up username when a retry has no profile", async () => {
      store.set("deletedUsers/user-retry", {
        email: "retry@example.com",
        username: "retry.handle",
      });
      store.set("publicUsernames/retry.handle", {uid: "user-retry"});

      const wrapped = testEnv.wrap(deleteAccount);
      const result = await wrapped({
        data: {},
        auth: {uid: "user-retry"},
      } as never);

      expect(result).toEqual({success: true});
      expect(store.has("publicUsernames/retry.handle")).toBe(false);
      expect(store.get("deletedUsers/user-retry")).toEqual({
        deletion_status: "firestore_complete",
        policy_version: 2,
        deleted_at: "mock-timestamp",
      });
      expect(authMock.deleteUser).toHaveBeenCalledWith("user-retry");
    });

    test("keeps firestore and auth retryable when storage cleanup fails", async () => {
      store.set("users/user-storage-failure", {
        email: "retry@example.com",
        username: "retry.user",
      });
      store.set("publicUsernames/retry.user", {
        uid: "user-storage-failure",
      });
      storageBucketMock.deleteFiles.mockRejectedValueOnce(
        new Error("Storage unavailable")
      );

      const wrapped = testEnv.wrap(deleteAccount);

      await expect(
        wrapped({
          data: {},
          auth: {uid: "user-storage-failure"},
        } as never)
      ).rejects.toThrow(
        /An error occurred while attempting to delete the account/
      );

      expect(store.has("users/user-storage-failure")).toBe(true);
      expect(store.has("publicUsernames/retry.user")).toBe(true);
      expect(firestoreMock.recursiveDelete).not.toHaveBeenCalled();
      expect(authMock.deleteUser).not.toHaveBeenCalled();
    });

    test("keeps the public username reserved when firestore cleanup fails", async () => {
      store.set("users/user-firestore-failure", {
        email: "retry@example.com",
        username: "retry.firestore",
      });
      store.set("publicUsernames/retry.firestore", {
        uid: "user-firestore-failure",
      });
      firestoreMock.recursiveDelete.mockRejectedValueOnce(
        new Error("Firestore unavailable")
      );

      const wrapped = testEnv.wrap(deleteAccount);

      await expect(
        wrapped({
          data: {},
          auth: {uid: "user-firestore-failure"},
        } as never)
      ).rejects.toThrow(
        /An error occurred while attempting to delete the account/
      );

      expect(store.has("users/user-firestore-failure")).toBe(true);
      expect(store.has("publicUsernames/retry.firestore")).toBe(true);
      expect(authMock.deleteUser).not.toHaveBeenCalled();
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
