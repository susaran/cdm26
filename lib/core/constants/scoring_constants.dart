class FantasyPoints {
  // ─── Appearance ─────────────────────────────────────────────
  static const int starts = 2;
  static const int subAppearance = 1;
  static const int plays60Plus = 2; // bonus for playing 60+ minutes

  // ─── Goals (by position) ────────────────────────────────────
  static const int gkGoal = 10;
  static const int defGoal = 7;
  static const int midGoal = 6;
  static const int fwdGoal = 5;

  // ─── Assists & Chance Creation ──────────────────────────────
  static const int assist = 3;
  static const int keyPass = 1;           // pass leading directly to a shot
  static const double bigChanceCreated = 1.0; // clear goal-scoring opportunity created

  // ─── Clean Sheets (for 60+ min played) ─────────────────────
  static const int gkCleanSheet = 5;
  static const int defCleanSheet = 4;
  static const int midCleanSheet = 1;

  // ─── Goalkeeper ─────────────────────────────────────────────
  static const int penaltySave = 5;
  static const int savesPerPoint = 3;       // 1 pt per 3 saves
  static const int highClaimsPerPoint = 3;  // 1 pt per 3 high ball claims
  static const int gkGoalsConcededPer2 = -1; // -1 per 2 goals conceded

  // ─── Defensive (outfield) ───────────────────────────────────
  static const int tackleWon = 1;
  static const int interception = 1;
  static const int blockedShot = 1;
  static const int clearancesPerPoint = 4; // 1 pt per 4 clearances

  // ─── Ball Progression & Passing ─────────────────────────────
  static const double dribbleCompleted = 0.3;
  static const double pointsPerAccuratePass = 0.08; // per player, no cap (50 passes = 4 pts)
  static const int passAccuracyBonus = 2;            // +2 if ≥85% accuracy with ≥30 passes

  // ─── Shooting (non-goal) ────────────────────────────────────
  static const int shotOnTarget = 1;
  static const int bigChanceMissed = -2;

  // ─── Discipline ─────────────────────────────────────────────
  static const int yellowCard = -1;
  static const int redCard = -3;

  // ─── Negative events ────────────────────────────────────────
  static const int ownGoal = -2;
  static const int penaltyMiss = -2;

  // ─── Captain multipliers ────────────────────────────────────
  static const double captainMultiplier = 2.0;
  static const double viceCaptainMultiplier = 1.5;

  // ─── Human-readable labels (for Points Guide) ───────────────
  static const List<({String label, String pts, String note})> allRules = [
    (label: 'Starting XI', pts: '+2', note: 'Playing from kick-off'),
    (label: 'Substitute appearance', pts: '+1', note: 'Comes off the bench'),
    (label: '60+ minutes played', pts: '+2', note: 'Bonus for full involvement'),
    (label: 'Goal (FWD)', pts: '+5', note: 'Forward scores'),
    (label: 'Goal (MID)', pts: '+6', note: 'Midfielder scores'),
    (label: 'Goal (DEF)', pts: '+7', note: 'Defender scores'),
    (label: 'Goal (GK)', pts: '+10', note: 'Goalkeeper scores'),
    (label: 'Assist', pts: '+3', note: 'Final pass before a goal'),
    (label: 'Key pass', pts: '+1', note: 'Pass leading to a shot'),
    (label: 'Big chance created', pts: '+1', note: 'Clear goal-scoring chance created'),
    (label: 'Shot on target', pts: '+1', note: 'Non-goal shot on target'),
    (label: 'Dribble completed', pts: '+0.3', note: 'Successful take-on (~3 = 1 pt)'),
    (label: 'Tackle won', pts: '+1', note: 'Successful tackle'),
    (label: 'Interception', pts: '+1', note: 'Intercepts opponent pass'),
    (label: 'Shot blocked', pts: '+1', note: 'Blocks an opponent shot'),
    (label: 'Every 4 clearances', pts: '+1', note: 'Max +3/game'),
    (label: 'Accurate pass', pts: '+0.08', note: '1 pass = 0.08 pts · 50 passes = 4 pts · no cap'),
    (label: 'Pass accuracy ≥ 85%', pts: '+2', note: 'Bonus if ≥30 passes played'),
    (label: 'Clean sheet (GK)', pts: '+5', note: 'Must play 60+ min'),
    (label: 'Clean sheet (DEF)', pts: '+4', note: 'Must play 60+ min'),
    (label: 'Clean sheet (MID)', pts: '+1', note: 'Must play 60+ min'),
    (label: 'GK: every 3 saves', pts: '+1', note: ''),
    (label: 'GK: penalty saved', pts: '+5', note: ''),
    (label: 'GK: every 3 high claims', pts: '+1', note: ''),
    (label: 'GK: goals conceded (per 2)', pts: '-1', note: ''),
    (label: 'Yellow card', pts: '-1', note: ''),
    (label: 'Red card', pts: '-3', note: ''),
    (label: 'Own goal', pts: '-2', note: ''),
    (label: 'Penalty missed', pts: '-2', note: ''),
    (label: 'Big chance missed', pts: '-2', note: 'Clear chance wasted'),
    (label: 'Captain', pts: '×2', note: 'All points doubled'),
    (label: 'Vice-captain', pts: '×1.5', note: 'If captain does not play'),
  ];
}

// Team Defense (DST) — pick a national team, score like NFL fantasy defense
class TeamDefensePoints {
  // Match result
  static const int win = 4;
  static const int draw = 1;
  static const int loss = 0;

  // Goals (applies on a win only for goals scored)
  static const int goalScored = 1;   // +1 per team goal on a win
  static const int goalConceded = -1; // -1 per goal the team concedes regardless

  // Clean sheet (no goals conceded in 90 min)
  static const int cleanSheet = 5;

  // Team passing (capped — applies to TEAM slot, not individual players)
  static const int teamAccuratePassesPerPoint = 30; // +1 pt per 30 accurate team passes
  static const int teamPassCap = 3;                  // max +3/game from passes

  // GK saves (team-level, binned like NFL defense yards allowed)
  static const int teamSavesPerPoint = 3; // +1 per 3 GK saves

  // Defensive actions (team totals)
  static const int teamInterceptionsPerPoint = 5;  // +1 per 5 interceptions
  static const int teamTacklesPerPoint = 10;        // +1 per 10 tackles won

  static const List<({String label, String pts, String note})> dstRules = [
    (label: 'Win', pts: '+4', note: 'Team wins in 90 min or extra time'),
    (label: 'Draw', pts: '+1', note: 'Match ends level'),
    (label: 'Goal scored (win only)', pts: '+1', note: 'Each goal your team scores in a win'),
    (label: 'Goal conceded', pts: '-1', note: 'Each goal the team allows'),
    (label: 'Clean sheet', pts: '+5', note: 'No goals conceded in 90 min'),
    (label: 'Every 30 team passes', pts: '+1', note: 'Max +3/game from team passing'),
    (label: 'GK: every 3 saves', pts: '+1', note: 'Team goalkeeper saves'),
    (label: 'Every 5 interceptions', pts: '+1', note: 'Team total interceptions'),
    (label: 'Every 10 tackles won', pts: '+1', note: 'Team total tackles'),
  ];
}

class PredictionPoints {
  static const int exactScore = 10;
  static const int correctResult = 3;
  static const int correctGoalDifference = 5;
  static const int correctTotalGoals = 2;
  static const int correctOverUnder = 2;
  static const int firstScorer = 6;
}
