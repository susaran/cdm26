import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

const db = admin.firestore();

const API_KEY = process.env.API_FOOTBALL_KEY ?? "";
const BASE_URL = "https://v3.football.api-sports.io";
const WC_LEAGUE_ID = 1; // Confirm with API-Football docs for WC 2026
const WC_SEASON = 2026;

const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { "x-apisports-key": API_KEY },
});

// Runs every 2 minutes during live matches to update scores and events
export const syncMatchData = functions.pubsub
  .schedule("every 2 minutes")
  .onRun(async () => {
    try {
      const liveMatches = await db
        .collection("matches")
        .where("status", "in", ["live", "halftime", "extra_time", "penalties"])
        .get();

      for (const matchDoc of liveMatches.docs) {
        const providerMatchId = matchDoc.data().providerMatchId;
        if (!providerMatchId) continue;

        await syncSingleMatch(matchDoc.id, providerMatchId);
      }
    } catch (err) {
      functions.logger.error("syncMatchData error", err);
    }
  });

// Runs every hour to pull all upcoming fixtures and update statuses
export const syncAllFixtures = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    try {
      const { data } = await apiClient.get("/fixtures", {
        params: { league: WC_LEAGUE_ID, season: WC_SEASON },
      });

      const fixtures = data.response ?? [];
      const batch = db.batch();

      for (const fixture of fixtures) {
        const f = fixture.fixture;
        const teams = fixture.teams;
        const goals = fixture.goals;
        const league = fixture.league;

        const matchId = `match_${f.id}`;
        const matchRef = db.collection("matches").doc(matchId);

        const statusMap: Record<string, string> = {
          NS: "scheduled",
          "1H": "live",
          HT: "halftime",
          "2H": "live",
          ET: "extra_time",
          P: "penalties",
          FT: "finished",
          AET: "finished",
          PEN: "finished",
          SUSP: "cancelled",
          INT: "cancelled",
          PST: "postponed",
          CANC: "cancelled",
          ABD: "abandoned",
          TBD: "scheduled",
        };

        batch.set(
          matchRef,
          {
            matchId,
            providerMatchId: String(f.id),
            tournamentId: "wc_2026",
            stage: mapStage(league.round),
            group: league.round?.includes("Group") ? league.round.split(" - ")[1] : null,
            homeTeamId: `team_${teams.home.id}`,
            awayTeamId: `team_${teams.away.id}`,
            homeTeamName: teams.home.name,
            awayTeamName: teams.away.name,
            scheduledKickoff: admin.firestore.Timestamp.fromDate(new Date(f.date)),
            status: statusMap[f.status.short] ?? "scheduled",
            minute: f.status.elapsed ?? 0,
            score: {
              home: goals.home ?? 0,
              away: goals.away ?? 0,
            },
            lastProviderSyncAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }

      await batch.commit();
      functions.logger.info(`Synced ${fixtures.length} fixtures`);
    } catch (err) {
      functions.logger.error("syncAllFixtures error", err);
    }
  });

async function syncSingleMatch(matchId: string, providerMatchId: string) {
  try {
    const [eventsRes, statsRes] = await Promise.all([
      apiClient.get("/fixtures/events", { params: { fixture: providerMatchId } }),
      apiClient.get("/fixtures/players", { params: { fixture: providerMatchId } }),
    ]);

    const events = eventsRes.data.response ?? [];
    const eventBatch = db.batch();

    for (const event of events) {
      const eventId = `event_${event.time.elapsed}_${event.team.id}_${event.player.id}`;
      const eventRef = db
        .collection("matches")
        .doc(matchId)
        .collection("events")
        .doc(eventId);

      const typeMap: Record<string, string> = {
        Goal: "goal",
        "Yellow Card": "yellow_card",
        "Red Card": "red_card",
        "Yellow Red Card": "second_yellow",
        subst: "substitution_on",
      };

      eventBatch.set(
        eventRef,
        {
          eventId,
          matchId,
          type: typeMap[event.type] ?? event.type.toLowerCase().replace(" ", "_"),
          teamId: `team_${event.team.id}`,
          playerId: event.player.id ? `player_${event.player.id}` : null,
          assistPlayerId: event.assist?.id ? `player_${event.assist.id}` : null,
          minute: event.time.elapsed ?? 0,
          description: `${event.type}: ${event.player.name}`,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    await eventBatch.commit();

    // Sync player stats
    const teams = statsRes.data.response ?? [];
    const statsBatch = db.batch();

    for (const team of teams) {
      for (const player of team.players ?? []) {
        const s = player.statistics[0];
        const playerId = `player_${player.player.id}`;
        const statRef = db
          .collection("matches")
          .doc(matchId)
          .collection("playerStats")
          .doc(playerId);

        statsBatch.set(
          statRef,
          {
            matchId,
            playerId,
            teamId: `team_${team.team.id}`,
            position: s.games.position?.substring(0, 3).toUpperCase() ?? "MID",
            started: s.games.lineupPosition != null,
            minutesPlayed: s.games.minutes ?? 0,
            goals: s.goals.total ?? 0,
            assists: s.goals.assists ?? 0,
            ownGoals: 0,
            yellowCards: s.cards.yellow ?? 0,
            redCards: s.cards.red ?? 0,
            penaltiesMissed: s.penalty.missed ?? 0,
            penaltiesSaved: s.penalty.saved ?? 0,
            saves: s.goals.saves ?? 0,
            goalsConceded: s.goals.conceded ?? 0,
            cleanSheet: false,
            providerRating: parseFloat(s.games.rating ?? "0"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    }

    await statsBatch.commit();
  } catch (err) {
    functions.logger.error(`syncSingleMatch error for ${matchId}`, err);
  }
}

function mapStage(round: string): string {
  if (!round) return "group";
  const r = round.toLowerCase();
  if (r.includes("group")) return "group";
  if (r.includes("round of 32")) return "roundOf32";
  if (r.includes("round of 16")) return "roundOf16";
  if (r.includes("quarter")) return "quarterfinal";
  if (r.includes("semi")) return "semifinal";
  if (r.includes("3rd")) return "thirdPlace";
  if (r.includes("final")) return "finalStage";
  return "group";
}
