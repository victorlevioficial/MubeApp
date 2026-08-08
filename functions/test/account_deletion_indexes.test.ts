import {readFileSync} from "node:fs";
import {resolve} from "node:path";

type FieldIndex = {
  order?: string;
  queryScope?: string;
};

type FieldOverride = {
  collectionGroup?: string;
  fieldPath?: string;
  indexes?: FieldIndex[];
};

describe("account deletion indexes", () => {
  test("every filtered collection-group cleanup query has an index", () => {
    const indexPath = resolve(__dirname, "../../firestore.indexes.json");
    const indexConfig = JSON.parse(readFileSync(indexPath, "utf8")) as {
      fieldOverrides?: FieldOverride[];
    };
    const indexedFields = new Set(
      (indexConfig.fieldOverrides ?? [])
        .filter((override) =>
          override.indexes?.some(
            (index) =>
              index.queryScope === "COLLECTION_GROUP" &&
              index.order === "ASCENDING"
          )
        )
        .map((override) => `${override.collectionGroup}.${override.fieldPath}`)
    );

    const requiredIndexes = [
      "views.viewer_uid",
      "favorites.target_user_id",
      "blocked.blockedUserId",
      "notifications.senderId",
      "story_seen_authors.owner_uid",
      "messages.senderId",
      "messages.replyToSenderId",
      "conversationPreviews.otherUserId",
      "gig_applications.applicant_id",
    ];
    for (const requiredIndex of requiredIndexes) {
      expect(indexedFields).toContain(requiredIndex);
    }
  });
});
