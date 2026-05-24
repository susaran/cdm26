import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { seedWC2026 } from "./scripts/seed_wc2026";

admin.initializeApp();

export { syncMatchData, syncAllFixtures } from "./data_sync/api_football_sync";
export { calculateMatchScores, recalculateMatch } from "./scoring/scoring_engine";
export { onMatchFinished, onGoalScored, onTradeProposed, onNewChatMessage } from "./notifications/notification_triggers";

// One-time admin seed — call via: curl -X POST <fn_url>?secret=cdm26seed
export const seedData = functions.https.onRequest(async (req, res) => {
  if (req.query.secret !== "cdm26seed") {
    res.status(403).send("Forbidden");
    return;
  }
  await seedWC2026();
  res.send("Seeded OK");
});
