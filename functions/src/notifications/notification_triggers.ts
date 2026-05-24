import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const messaging = admin.messaging();
const db = admin.firestore();

// ── Match notifications ───────────────────────────────────────────────────────

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

// ── Trade notifications ───────────────────────────────────────────────────────

export const onTradeProposed = functions.firestore
  .document("leagues/{leagueId}/trades/{tradeId}")
  .onCreate(async (snap, context) => {
    const trade = snap.data();
    const { leagueId, tradeId } = context.params;

    const targetUserId: string = trade.targetUserId;
    const proposerName: string = trade.proposerDisplayName;

    const token = await getFcmToken(targetUserId);
    if (!token) return null;

    // Build a readable summary of what's being offered/requested
    const offered: string[] = (trade.offeredPlayers ?? []).map(
      (p: { displayName: string }) => p.displayName
    );
    const requested: string[] = (trade.requestedPlayers ?? []).map(
      (p: { displayName: string }) => p.displayName
    );
    const body =
      offered.length > 0 && requested.length > 0
        ? `Offers ${offered.slice(0, 2).join(", ")} for ${requested.slice(0, 2).join(", ")}`
        : "New trade proposal received";

    await sendTokenNotification(
      token,
      `Trade from ${proposerName} 🔄`,
      body,
      {
        type: "trade_proposed",
        leagueId,
        tradeId,
        threadId: `trade_${tradeId}`,
      }
    );

    return null;
  });

// ── Chat message notifications ────────────────────────────────────────────────

export const onNewChatMessage = functions.firestore
  .document("leagues/{leagueId}/chats/{threadId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { leagueId, threadId } = context.params;

    // Skip system-type messages (trade_proposal, etc.) — they were
    // already notified by the trade trigger above
    if (message.type !== "text") return null;

    const senderId: string = message.senderId;
    const senderName: string = message.senderName;
    const text: string = message.text ?? "";

    // Load thread to find other participant(s)
    const threadSnap = await db
      .collection("leagues")
      .doc(leagueId)
      .collection("chats")
      .doc(threadId)
      .get();

    if (!threadSnap.exists) return null;
    const thread = threadSnap.data()!;
    const participantIds: string[] = thread.participantIds ?? [];

    const others = participantIds.filter((uid) => uid !== senderId);
    if (others.length === 0) return null;

    // Send to each other participant
    await Promise.all(
      others.map(async (uid) => {
        const token = await getFcmToken(uid);
        if (!token) return;
        await sendTokenNotification(
          token,
          senderName,
          text.length > 100 ? `${text.substring(0, 100)}…` : text,
          {
            type: "chat_message",
            leagueId,
            threadId,
          }
        );
      })
    );

    return null;
  });

// ── Helpers ───────────────────────────────────────────────────────────────────

async function getFcmToken(userId: string): Promise<string | null> {
  const userDoc = await db.collection("users").doc(userId).get();
  return (userDoc.data()?.fcmToken as string | undefined) ?? null;
}

async function sendTokenNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>
) {
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data,
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
      android: {
        priority: "high",
        notification: { sound: "default" },
      },
    });
  } catch (err) {
    functions.logger.error("sendTokenNotification error", err);
  }
}

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
        payload: { aps: { sound: "default" } },
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
