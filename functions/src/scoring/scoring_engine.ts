import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// Fantasy points constants — must stay in sync with scoring_constants.dart
const FANTASY = {
  // Appearance
  starts: 2,
  subAppearance: 1,
  plays60Plus: 2,

  // Goals
  gkGoal: 10,
  defGoal: 7,
  midGoal: 6,
  fwdGoal: 5,

  // Assists & chance creation
  assist: 3,
  keyPass: 1,
  bigChanceCreated: 1.0,   // reduced from 3 — one clear chance = 1 pt
  bigChanceMissed: -2,

  // Shooting
  shotOnTarget: 1,

  // Ball progression & passing
  dribbleCompleted: 0.3,         // ~3 dribbles = 1 pt
  pointsPerAccuratePass: 0.08,   // 1 pass = 0.08 pts; 50 passes = 4 pts
  passAccuracyBonus: 2,          // +2 if ≥85% accuracy with ≥30 passes

  // Defensive
  tackleWon: 1,
  interception: 1,
  blockedShot: 1,
  clearancesPerPoint: 4,         // 1 pt per 4 clearances

  // Clean sheets
  gkCleanSheet: 5,
  defCleanSheet: 4,
  midCleanSheet: 1,

  // GK specific
  penaltySave: 5,
  savesPerPoint: 3,              // 1 pt per 3 saves
  highClaimsPerPoint: 3,         // 1 pt per 3 high claims
  gkGoalsConcededPer2: -1,       // -1 per 2 goals conceded

  // Discipline
  yellowCard: -1,
  redCard: -3,

  // Errors
  ownGoal: -2,
  penaltyMiss: -2,

  // Captain
  captainMultiplier: 2.0,
  viceCaptainMultiplier: 1.5,
};

const PREDICTION = {
  exactScore: 10,
  correctResult: 3,
  correctGoalDifference: 5,
  correctTotalGoals: 2,
  correctOverUnder: 2,
  firstScorer: 6,
};

interface PlayerStat {
  playerId: string;
  teamId: string;
  position: string;
  started: boolean;
  minutesPlayed: number;
  goals: number;
  assists: number;
  keyPasses: number;
  bigChancesCreated: number;
  bigChancesMissed: number;
  shotsOnTarget: number;
  accuratePasses: number;
  passAccuracyPct: number;    // 0–100
  dribblesCompleted: number;
  tacklesWon: number;
  interceptions: number;
  blockedShots: number;
  clearances: number;
  ownGoals: number;
  yellowCards: number;
  redCards: number;
  penaltiesMissed: number;
  penaltiesSaved: number;
  saves: number;
  highClaims: number;
  goalsConceded: number;
  cleanSheet: boolean;
}

interface MatchScore {
  home: number;
  away: number;
}

function calcFantasyPoints(stat: PlayerStat): number {
  let pts = 0;

  // Appearance
  if (stat.started) {
    pts += FANTASY.starts;
  } else if (stat.minutesPlayed > 0) {
    pts += FANTASY.subAppearance;
  }
  if (stat.minutesPlayed >= 60) pts += FANTASY.plays60Plus;

  // Goals (position-weighted)
  const goalPts = { GK: FANTASY.gkGoal, DEF: FANTASY.defGoal, MID: FANTASY.midGoal, FWD: FANTASY.fwdGoal };
  pts += (goalPts[stat.position as keyof typeof goalPts] ?? FANTASY.fwdGoal) * stat.goals;

  // Assists & chance creation
  pts += FANTASY.assist * stat.assists;
  pts += FANTASY.keyPass * stat.keyPasses;
  pts += FANTASY.bigChanceCreated * stat.bigChancesCreated;
  pts += FANTASY.bigChanceMissed * stat.bigChancesMissed;

  // Shooting
  pts += FANTASY.shotOnTarget * stat.shotsOnTarget;

  // Passing — 0.08 pts per accurate pass, tracked continuously
  pts += FANTASY.pointsPerAccuratePass * stat.accuratePasses;
  if (stat.accuratePasses >= 30 && stat.passAccuracyPct >= 85) {
    pts += FANTASY.passAccuracyBonus;
  }

  // Ball progression
  pts += FANTASY.dribbleCompleted * stat.dribblesCompleted;

  // Defensive
  pts += FANTASY.tackleWon * stat.tacklesWon;
  pts += FANTASY.interception * stat.interceptions;
  pts += FANTASY.blockedShot * stat.blockedShots;
  pts += Math.floor(stat.clearances / FANTASY.clearancesPerPoint);

  // Clean sheet (must play 60+ min)
  if (stat.cleanSheet && stat.minutesPlayed >= 60) {
    if (stat.position === "GK") pts += FANTASY.gkCleanSheet;
    else if (stat.position === "DEF") pts += FANTASY.defCleanSheet;
    else if (stat.position === "MID") pts += FANTASY.midCleanSheet;
  }

  // GK specific
  if (stat.position === "GK") {
    pts += FANTASY.penaltySave * stat.penaltiesSaved;
    pts += Math.floor(stat.saves / FANTASY.savesPerPoint);
    pts += Math.floor(stat.highClaims / FANTASY.highClaimsPerPoint);
    pts += Math.floor(stat.goalsConceded / 2) * FANTASY.gkGoalsConcededPer2;
  }

  // Discipline
  pts += FANTASY.yellowCard * stat.yellowCards;
  pts += FANTASY.redCard * stat.redCards;

  // Errors
  pts += FANTASY.ownGoal * stat.ownGoals;
  pts += FANTASY.penaltyMiss * stat.penaltiesMissed;

  return Math.round(pts * 100) / 100; // 2 decimal places
}

// ─── Team DST Scoring ────────────────────────────────────────────────────────

interface TeamMatchStat {
  teamId: string;
  goalsScored: number;
  goalsConceded: number;
  won: boolean;
  drew: boolean;
  accuratePasses: number;    // total accurate passes by the whole team
  saves: number;
  interceptions: number;
  tacklesWon: number;
}

const DST = {
  win: 4,
  draw: 1,
  goalScored: 1,       // per goal on a WIN only
  goalConceded: -1,    // per goal conceded regardless
  cleanSheet: 5,
  teamPassesPerPoint: 30,
  teamPassCap: 3,
  savesPerPoint: 3,
  interceptionsPerPoint: 5,
  tacklesPerPoint: 10,
};

function calcTeamDSTPoints(stat: TeamMatchStat): number {
  let pts = 0;

  // Result
  if (stat.won) {
    pts += DST.win;
    pts += DST.goalScored * stat.goalsScored; // +1 per goal only on a win
  } else if (stat.drew) {
    pts += DST.draw;
  }

  // Goals conceded (always penalised)
  pts += DST.goalConceded * stat.goalsConceded;

  // Clean sheet
  if (stat.goalsConceded === 0) pts += DST.cleanSheet;

  // Team passing (capped at +3/game)
  const passPts = Math.min(
    Math.floor(stat.accuratePasses / DST.teamPassesPerPoint),
    DST.teamPassCap
  );
  pts += passPts;

  // GK saves
  pts += Math.floor(stat.saves / DST.savesPerPoint);

  // Defensive actions
  pts += Math.floor(stat.interceptions / DST.interceptionsPerPoint);
  pts += Math.floor(stat.tacklesWon / DST.tacklesPerPoint);

  return Math.round(pts * 100) / 100;
}

function calcPredictionPoints(
  prediction: { homeScore: number; awayScore: number; firstScorerPlayerId?: string },
  actual: MatchScore,
  firstScorerPlayerId?: string
): Record<string, number> {
  const pts = {
    exactScore: 0,
    correctResult: 0,
    goalDifference: 0,
    totalGoals: 0,
    overUnder: 0,
    firstScorer: 0,
    total: 0,
  };

  const predHome = prediction.homeScore;
  const predAway = prediction.awayScore;
  const actHome = actual.home;
  const actAway = actual.away;

  if (predHome === actHome && predAway === actAway) {
    pts.exactScore = PREDICTION.exactScore;
  } else {
    const predResult = Math.sign(predHome - predAway);
    const actResult = Math.sign(actHome - actAway);
    if (predResult === actResult) pts.correctResult = PREDICTION.correctResult;

    if (predHome - predAway === actHome - actAway) {
      pts.goalDifference = PREDICTION.correctGoalDifference;
    }
  }

  if (predHome + predAway === actHome + actAway) {
    pts.totalGoals = PREDICTION.correctTotalGoals;
  }

  const predOver = predHome + predAway > 2.5;
  const actOver = actHome + actAway > 2.5;
  if (predOver === actOver) pts.overUnder = PREDICTION.correctOverUnder;

  if (
    prediction.firstScorerPlayerId &&
    prediction.firstScorerPlayerId === firstScorerPlayerId
  ) {
    pts.firstScorer = PREDICTION.firstScorer;
  }

  pts.total =
    pts.exactScore +
    pts.correctResult +
    pts.goalDifference +
    pts.totalGoals +
    pts.overUnder +
    pts.firstScorer;

  return pts;
}

// Triggered when a match document's status changes to 'finished'
export const calculateMatchScores = functions.firestore
  .document("matches/{matchId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return null;
    if (after.status !== "finished") return null;

    return runScoringForMatch(context.params.matchId, after);
  });

// HTTP callable for admin recalculation
export const recalculateMatch = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");

  const { matchId } = data;
  if (!matchId) throw new functions.https.HttpsError("invalid-argument", "matchId required.");

  const matchDoc = await db.collection("matches").doc(matchId).get();
  if (!matchDoc.exists) throw new functions.https.HttpsError("not-found", "Match not found.");

  await runScoringForMatch(matchId, matchDoc.data()!);
  return { success: true };
});

// Maps stage string + matchday to a global scoring round number (1–9).
// Must stay in sync with api_football_sync.ts and match_model.dart comments.
function matchScoringRound(matchData: admin.firestore.DocumentData): number {
  const stage: string = matchData.stage ?? "group";
  const matchday: number | null = matchData.matchday ?? null;
  if (stage === "group") return matchday ?? 1;
  const map: Record<string, number> = {
    roundOf32: 4, roundOf16: 5, quarterfinal: 6,
    semifinal: 7, thirdPlace: 8, finalStage: 9,
  };
  return map[stage] ?? 1;
}

async function runScoringForMatch(matchId: string, matchData: admin.firestore.DocumentData) {
  const score: MatchScore = {
    home: matchData.score?.home ?? 0,
    away: matchData.score?.away ?? 0,
  };
  const scoringRound = matchScoringRound(matchData);
  const roundKey = `roundPoints.r${scoringRound}`;

  // ── 1. Calculate player fantasy points ──────────────────────────────────────
  const playerStatsSnap = await db
    .collection("matches")
    .doc(matchId)
    .collection("playerStats")
    .get();

  const playerPoints: Record<string, number> = {};
  const statsBatch = db.batch();

  for (const statDoc of playerStatsSnap.docs) {
    const stat = statDoc.data() as PlayerStat;
    const pts = calcFantasyPoints(stat);
    playerPoints[stat.playerId] = pts;
    statsBatch.update(statDoc.ref, {
      fantasyPointsRaw: pts,
      fantasyPointsFinal: pts,
      scoringRound,
      lastCalculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // First scorer for prediction scoring
  const eventsSnap = await db
    .collection("matches")
    .doc(matchId)
    .collection("events")
    .where("type", "==", "goal")
    .orderBy("minute")
    .limit(1)
    .get();
  const firstScorerPlayerId = eventsSnap.docs[0]?.data()?.playerId;

  // ── 2. Update aggregate player career stats ─────────────────────────────────
  for (const [playerId, pts] of Object.entries(playerPoints)) {
    const playerRef = db.collection("players").doc(playerId);
    statsBatch.update(playerRef, {
      "statsSummary.totalFantasyPoints": admin.firestore.FieldValue.increment(pts),
      "statsSummary.appearances": admin.firestore.FieldValue.increment(1),
    });
  }
  await statsBatch.commit();

  // ── 3. Build DST points for both teams in this match ────────────────────────
  const homeTeamStat: TeamMatchStat = {
    teamId: matchData.homeTeamId,
    goalsScored: score.home,
    goalsConceded: score.away,
    won: score.home > score.away,
    drew: score.home === score.away,
    accuratePasses: matchData.homeAccuratePasses ?? 0,
    saves: matchData.homeGkSaves ?? 0,
    interceptions: matchData.homeInterceptions ?? 0,
    tacklesWon: matchData.homeTacklesWon ?? 0,
  };
  const awayTeamStat: TeamMatchStat = {
    teamId: matchData.awayTeamId,
    goalsScored: score.away,
    goalsConceded: score.home,
    won: score.away > score.home,
    drew: score.home === score.away,
    accuratePasses: matchData.awayAccuratePasses ?? 0,
    saves: matchData.awayGkSaves ?? 0,
    interceptions: matchData.awayInterceptions ?? 0,
    tacklesWon: matchData.awayTacklesWon ?? 0,
  };
  const teamDSTPoints: Record<string, number> = {
    [homeTeamStat.teamId]: calcTeamDSTPoints(homeTeamStat),
    [awayTeamStat.teamId]: calcTeamDSTPoints(awayTeamStat),
  };

  // ── 4. Apply points to every league ─────────────────────────────────────────
  const leaguesSnap = await db.collection("leagues").get();

  for (const leagueDoc of leaguesSnap.docs) {
    const leagueId = leagueDoc.id;
    const memberBatch = db.batch();

    // ── 4a. Predictions ───────────────────────────────────────────────────────
    const predictionsSnap = await db
      .collection("leagues")
      .doc(leagueId)
      .collection("predictions")
      .where("matchId", "==", matchId)
      .where("status", "==", "submitted")
      .get();

    for (const predDoc of predictionsSnap.docs) {
      const pred = predDoc.data();
      const pts = calcPredictionPoints(
        { homeScore: pred.homeScore, awayScore: pred.awayScore, firstScorerPlayerId: pred.firstScorerPlayerId },
        score,
        firstScorerPlayerId
      );
      memberBatch.update(predDoc.ref, {
        points: pts,
        status: "locked",
        lockedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const memberRef = db.collection("leagues").doc(leagueId).collection("members").doc(pred.userId);
      memberBatch.update(memberRef, {
        predictionPoints: admin.firestore.FieldValue.increment(pts.total),
        totalPoints: admin.firestore.FieldValue.increment(pts.total),
        [roundKey]: admin.firestore.FieldValue.increment(pts.total),
        "tiebreakers.exactScores": admin.firestore.FieldValue.increment(pts.exactScore > 0 ? 1 : 0),
        "tiebreakers.correctResults": admin.firestore.FieldValue.increment(pts.correctResult > 0 ? 1 : 0),
      });
    }

    // ── 4b. Fantasy squad points (with idempotency guard) ─────────────────────
    const teamsSnap = await db.collection("leagues").doc(leagueId).collection("teams").get();

    for (const teamDoc of teamsSnap.docs) {
      const team = teamDoc.data();
      const userId: string = team.userId;
      const memberRef = db.collection("leagues").doc(leagueId).collection("members").doc(userId);

      // Idempotency: skip if this match was already scored for this member.
      // This prevents double-counting when the Firestore trigger fires more
      // than once or when recalculateMatch is called on an already-scored match.
      const memberSnap = await memberRef.get();
      const alreadyScored: string[] = memberSnap.data()?.scoredMatchIds ?? [];
      if (alreadyScored.includes(matchId)) continue;

      const players: Array<{ playerId: string }> = team.players ?? [];
      const captainId: string = team.captainPlayerId;
      const viceCaptainId: string = team.viceCaptainPlayerId;

      // Only count each player's points from THIS match — no cross-match
      // double-dipping because each player appears in exactly one game per
      // scoring round (a national team plays once per group matchday).
      let fantasyTotal = 0;
      for (const slot of players) {
        const pts = playerPoints[slot.playerId] ?? 0;
        if (slot.playerId === captainId) {
          fantasyTotal += pts * FANTASY.captainMultiplier;
        } else if (slot.playerId === viceCaptainId) {
          fantasyTotal += pts * FANTASY.viceCaptainMultiplier;
        } else {
          fantasyTotal += pts;
        }
      }

      const dstPts = team.teamPickId ? (teamDSTPoints[team.teamPickId] ?? 0) : 0;
      const matchTotal = Math.round((fantasyTotal + dstPts) * 100) / 100;

      memberBatch.update(memberRef, {
        fantasyPoints: admin.firestore.FieldValue.increment(matchTotal),
        totalPoints: admin.firestore.FieldValue.increment(matchTotal),
        // Per-round bucket — used by leaderboard round view and deduplication
        [roundKey]: admin.firestore.FieldValue.increment(matchTotal),
        // Record this matchId so re-triggers are skipped
        scoredMatchIds: admin.firestore.FieldValue.arrayUnion(matchId),
      });
    }

    await memberBatch.commit();
  }

  functions.logger.info(`Scoring complete for match ${matchId} (round ${scoringRound})`);
}
