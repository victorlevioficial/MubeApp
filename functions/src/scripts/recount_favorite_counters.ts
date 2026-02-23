import * as admin from "firebase-admin";
import {FieldPath, Timestamp} from "firebase-admin/firestore";

interface CliOptions {
  projectId: string;
  dryRun: boolean;
  batchSize: number;
  limitUsers?: number;
  help: boolean;
}

interface AggregationResult {
  countsByTargetUserId: Map<string, number>;
  totalFavoriteDocs: number;
  ignoredSelfLikes: number;
}

interface RecountSummary {
  usersScanned: number;
  divergencesFound: number;
  usersUpdated: number;
  writesCommitted: number;
}

const DEFAULT_PROJECT_ID = "mube-63a93";
const DEFAULT_BATCH_SIZE = 400;
const USERS_PAGE_SIZE = 1000;

/**
 * Prints usage instructions for this script.
 */
function printUsage(): void {
  console.log(`
Usage:
  node functions/lib/scripts/recount_favorite_counters.js [options]

Options:
  --project <id>       Firebase project id (default: ${DEFAULT_PROJECT_ID})
  --dry-run            No writes, only reports divergences
  --batch-size <n>     Firestore batch size
                       (default: ${DEFAULT_BATCH_SIZE})
  --limit-users <n>    Limit scanned users (for controlled testing)
  --help               Show this help
`);
}

/**
 * Parses a positive integer from CLI value.
 *
 * @param {string} rawValue Raw string value.
 * @param {string} flagName CLI flag name.
 * @return {number} Parsed positive integer.
 */
function parsePositiveInt(rawValue: string, flagName: string): number {
  const parsed = Number.parseInt(rawValue, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`${flagName} must be a positive integer`);
  }
  return parsed;
}

/**
 * Parses CLI options for recount script.
 *
 * @param {string[]} argv Process args excluding node and script path.
 * @return {CliOptions} Parsed options.
 */
function parseArgs(argv: string[]): CliOptions {
  const options: CliOptions = {
    projectId: DEFAULT_PROJECT_ID,
    dryRun: false,
    batchSize: DEFAULT_BATCH_SIZE,
    help: false,
  };

  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index];

    switch (arg) {
    case "--help":
    case "-h":
      options.help = true;
      break;
    case "--dry-run":
      options.dryRun = true;
      break;
    case "--project": {
      const value = argv[index + 1];
      if (!value) throw new Error("Missing value for --project");
      options.projectId = value;
      index++;
      break;
    }
    case "--batch-size": {
      const value = argv[index + 1];
      if (!value) throw new Error("Missing value for --batch-size");
      options.batchSize = parsePositiveInt(value, "--batch-size");
      index++;
      break;
    }
    case "--limit-users": {
      const value = argv[index + 1];
      if (!value) throw new Error("Missing value for --limit-users");
      options.limitUsers = parsePositiveInt(value, "--limit-users");
      index++;
      break;
    }
    default:
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (options.batchSize > 500) {
    throw new Error("--batch-size must be <= 500 (Firestore limit)");
  }

  return options;
}

/**
 * Converts unknown value to a non-negative integer.
 *
 * @param {unknown} value Raw value.
 * @return {number} Non-negative integer.
 */
function toNonNegativeInt(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return 0;
  }
  return Math.max(0, Math.floor(value));
}

/**
 * Aggregates favorites received by each target user.
 *
 * @param {admin.firestore.Firestore} db Firestore instance.
 * @return {Promise<AggregationResult>} Aggregation result.
 */
async function aggregateFavoritesByTarget(
  db: admin.firestore.Firestore
): Promise<AggregationResult> {
  const snapshot = await db.collectionGroup("favorites").get();
  const countsByTargetUserId = new Map<string, number>();

  let totalFavoriteDocs = 0;
  let ignoredSelfLikes = 0;

  for (const favoriteDoc of snapshot.docs) {
    totalFavoriteDocs++;

    const sourceUserId = favoriteDoc.ref.parent.parent?.id;
    const targetUserId = favoriteDoc.id;

    if (!sourceUserId) {
      continue;
    }

    if (sourceUserId === targetUserId) {
      ignoredSelfLikes++;
      continue;
    }

    const current = countsByTargetUserId.get(targetUserId) ?? 0;
    countsByTargetUserId.set(targetUserId, current + 1);
  }

  return {countsByTargetUserId, totalFavoriteDocs, ignoredSelfLikes};
}

/**
 * Recounts and optionally rewrites favorite counters on users collection.
 *
 * @param {admin.firestore.Firestore} db Firestore instance.
 * @param {CliOptions} options Script options.
 * @param {Map<string, number>} countsByTargetUserId Aggregated counts.
 * @return {Promise<RecountSummary>} Recount summary.
 */
async function recountCounters(
  db: admin.firestore.Firestore,
  options: CliOptions,
  countsByTargetUserId: Map<string, number>
): Promise<RecountSummary> {
  let usersScanned = 0;
  let divergencesFound = 0;
  let usersUpdated = 0;
  let writesCommitted = 0;
  let cursor: string | undefined;

  let batch = db.batch();
  let pendingWrites = 0;

  const commitBatch = async (): Promise<void> => {
    if (pendingWrites === 0) return;
    await batch.commit();
    writesCommitted += pendingWrites;
    batch = db.batch();
    pendingWrites = 0;
  };

  let hasMorePages = true;
  while (hasMorePages) {
    const remainingLimit = options.limitUsers === undefined ?
      USERS_PAGE_SIZE :
      Math.min(USERS_PAGE_SIZE, options.limitUsers - usersScanned);

    if (remainingLimit <= 0) {
      break;
    }

    const baseQuery = db
      .collection("users")
      .orderBy(FieldPath.documentId())
      .limit(remainingLimit);

    const query = cursor === undefined ?
      baseQuery :
      baseQuery.startAfter(cursor);

    const pageSnapshot = await query.get();
    if (pageSnapshot.empty) {
      break;
    }

    for (const userDoc of pageSnapshot.docs) {
      usersScanned++;
      const data = userDoc.data();

      const desiredCount = countsByTargetUserId.get(userDoc.id) ?? 0;
      const currentLikeCount = toNonNegativeInt(data.likeCount);
      const currentFavoritesCount = toNonNegativeInt(data.favorites_count);

      if (currentLikeCount === desiredCount &&
          currentFavoritesCount === desiredCount) {
        continue;
      }

      divergencesFound++;

      if (options.dryRun) {
        continue;
      }

      batch.update(userDoc.ref, {
        likeCount: desiredCount,
        favorites_count: desiredCount,
        updated_at: Timestamp.now(),
      });
      usersUpdated++;
      pendingWrites++;

      if (pendingWrites >= options.batchSize) {
        await commitBatch();
      }
    }

    cursor = pageSnapshot.docs[pageSnapshot.docs.length - 1].id;

    hasMorePages = pageSnapshot.docs.length >= remainingLimit;
  }

  if (!options.dryRun) {
    await commitBatch();
  }

  return {usersScanned, divergencesFound, usersUpdated, writesCommitted};
}

/**
 * Script entrypoint.
 */
async function run(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printUsage();
    return;
  }

  if (admin.apps.length === 0) {
    admin.initializeApp({projectId: options.projectId});
  }

  const db = admin.firestore();

  console.log("=== Favorite Counter Recount ===");
  console.log(`Project: ${options.projectId}`);
  console.log(`Dry run: ${options.dryRun ? "yes" : "no"}`);
  console.log(`Batch size: ${options.batchSize}`);
  if (options.limitUsers !== undefined) {
    console.log(`User scan limit: ${options.limitUsers}`);
  }
  console.log("");

  console.log("Step 1/2: Aggregating favorites collection group...");
  const aggregation = await aggregateFavoritesByTarget(db);
  console.log(`Favorites docs read: ${aggregation.totalFavoriteDocs}`);
  console.log(`Self-likes ignored: ${aggregation.ignoredSelfLikes}`);
  console.log(
    `Targets with at least one favorite: ${
      aggregation.countsByTargetUserId.size
    }`
  );
  console.log("");

  console.log("Step 2/2: Recounting users counters...");
  const summary = await recountCounters(
    db,
    options,
    aggregation.countsByTargetUserId
  );
  console.log("");

  console.log("=== Summary ===");
  console.log(`Users scanned: ${summary.usersScanned}`);
  console.log(`Divergences found: ${summary.divergencesFound}`);
  console.log(`Users updated: ${summary.usersUpdated}`);
  console.log(`Writes committed: ${summary.writesCommitted}`);
  console.log(
    options.dryRun ?
      "Dry run finished. No writes were performed." :
      "Recount finished with writes applied."
  );
}

void run().catch((error: unknown) => {
  console.error("Recount script failed:", error);
  process.exitCode = 1;
});
