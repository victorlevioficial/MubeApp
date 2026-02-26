import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Callable function to securely delete a user's account and data.
 * 
 * Flow:
 * 1. Ensure the user is authenticated.
 * 2. Fetch all user data from the `users` collection.
 * 3. Store the user data in a backup collection `deletedUsers`.
 * 4. Remove the user data from the `users` collection.
 * 5. Delete the user from Firebase Authentication.
 */
export const deleteAccount = onCall(
    { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
    async (request) => {
        // 1. Ensure user is authenticated
        const uid = request.auth?.uid;
        if (!uid) {
            throw new HttpsError(
                "unauthenticated",
                "The function must be called while authenticated."
            );
        }

        try {
            const userRef = db.collection("users").doc(uid);
            const userDoc = await userRef.get();

            // If user profile exists, back it up
            if (userDoc.exists) {
                const userData = userDoc.data() || {};

                // Add exact deletion timestamp metadata to the backup
                userData.deleted_at = admin.firestore.FieldValue.serverTimestamp();

                // 3. Keep a backup in "deletedUsers"
                await db.collection("deletedUsers").doc(uid).set(userData);

                // 4. Delete from Main Users collection
                await userRef.delete();
            }

            // 5. Delete from Firebase Authentication
            await admin.auth().deleteUser(uid);

            console.log(`User ${uid} successfully backed up and deleted.`);
            return { success: true };
        } catch (error) {
            console.error(`Error deleting user account with uid: ${uid}`, error);
            throw new HttpsError(
                "internal",
                "An error occurred while attempting to delete the account."
            );
        }
    }
);
