import firebaseFunctionsTest from "firebase-functions-test";

// 1. Mock firebase-admin first - MUST matched expected structure precisely
const firestoreMock = {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    get: jest.fn(),
    set: jest.fn(),
    delete: jest.fn(),
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

// 2. Import dependencies
import { deleteAccount } from "../src/users";
import * as admin from "firebase-admin";

const testEnv = firebaseFunctionsTest();

describe("deleteAccount Cloud Function", () => {
    let mockFirestore: any;
    let mockAuth: any;

    beforeEach(() => {
        jest.clearAllMocks();
        mockFirestore = admin.firestore();
        mockAuth = admin.auth();

        // Default successful behavior
        mockFirestore.get.mockResolvedValue({
            exists: true,
            data: () => ({ nome: "Test User", email: "test@example.com" }),
        });
    });

    afterAll(() => {
        testEnv.cleanup();
    });

    test("should throw unauthenticated error if uid is missing", async () => {
        const wrapped = testEnv.wrap(deleteAccount);
        await expect(wrapped({ data: {}, auth: null } as any)).rejects.toThrow(
            /must be called while authenticated/
        );
    });

    test("should backup and delete data for an existing user", async () => {
        const wrapped = testEnv.wrap(deleteAccount);
        const auth = { uid: "user123" } as any;

        const result = await wrapped({ data: {}, auth } as any);

        expect(result).toEqual({ success: true });

        // Verify backup
        expect(mockFirestore.collection).toHaveBeenCalledWith("deletedUsers");
        expect(mockFirestore.set).toHaveBeenCalledWith(expect.objectContaining({
            nome: "Test User",
            deleted_at: "mock-timestamp"
        }));

        // Verify deletion
        expect(mockFirestore.delete).toHaveBeenCalled();
        expect(mockAuth.deleteUser).toHaveBeenCalledWith("user123");
    });

    test("should delete from Auth even if Firestore doc does not exist", async () => {
        mockFirestore.get.mockResolvedValue({ exists: false });

        const wrapped = testEnv.wrap(deleteAccount);
        const auth = { uid: "user456" } as any;

        const result = await wrapped({ data: {}, auth } as any);

        expect(result).toEqual({ success: true });
        expect(mockFirestore.delete).not.toHaveBeenCalled();
        expect(mockAuth.deleteUser).toHaveBeenCalledWith("user456");
    });

    test("should throw internal error on unexpected failures", async () => {
        mockAuth.deleteUser.mockRejectedValue(new Error("Firebase Auth error"));

        const wrapped = testEnv.wrap(deleteAccount);
        const auth = { uid: "user789" } as any;

        await expect(wrapped({ data: {}, auth } as any)).rejects.toThrow(
            /An error occurred while attempting to delete the account/
        );
    });
});
