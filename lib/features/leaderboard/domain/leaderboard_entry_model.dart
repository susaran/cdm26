class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalPoints,
    this.photoUrl,
    this.rank,
    this.previousRank,
    this.fantasyPoints = 0,
    this.predictionPoints = 0,
    this.exactScores = 0,
    this.correctResults = 0,
    this.roundPoints = const {},
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final int? rank;
  final int? previousRank;
  final int totalPoints;
  final int fantasyPoints;
  final int predictionPoints;
  final int exactScores;
  final int correctResults;
  // Points earned in each scoring round, keyed by round number (1–9).
  final Map<int, int> roundPoints;

  int pointsForRound(int round) => roundPoints[round] ?? 0;

  int get rankChange {
    if (previousRank == null || rank == null) return 0;
    return previousRank! - rank!;
  }
}
