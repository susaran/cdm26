import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export { syncMatchData, syncAllFixtures } from "./data_sync/api_football_sync";
export { calculateMatchScores, recalculateMatch } from "./scoring/scoring_engine";
export { onMatchFinished, onGoalScored } from "./notifications/notification_triggers";
