import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();
const messaging = admin.messaging();

export const onMatchFinished = functions.firestore
  .document("matches/{matchId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return null;
    if (after.status !== "finished") return null;

    const { matchId } = context.params;
    const homeTeam = after.homeTeamName;
    const awayTeam = after.awayTeamName;
    const score = after.score;

    await sendTopicNotification(
      `match_${matchId}`,
      "Full Time!",
      `${homeTeam} ${score.home} - ${score.away} ${awayTeam}`,
      { matchId, type: "match_finished" }
    );

    return null;
  });

export const onGoalScored = functions.firestore
  .document("matches/{matchId}/events/{eventId}")
  .onCreate(async (snap, context) => {
    const event = snap.data();
    if (event.type !== "goal") return null;

    const { matchId } = context.params;

    await sendTopicNotification(
      `match_${matchId}`,
      "GOAL!",
      `${event.description} (${event.minute}')`,
      { matchId, type: "goal", playerId: event.playerId ?? "" }
    );

    return null;
  });

async function sendTopicNotification(
  topic: string,
  title: string,
  body: string,
  data: Record<string, string>
) {
  try {
    await messaging.send({
      topic,
      notification: { title, body },
      data,
      apns: {
        payload: {
          aps: { sound: "default" },
        },
      },
      android: {
        priority: "high",
        notification: { sound: "default" },
      },
    });
  } catch (err) {
    functions.logger.error("sendTopicNotification error", err);
  }
}
