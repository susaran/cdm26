import 'package:cloud_firestore/cloud_firestore.dart';

enum PredictionStatus { draft, submitted, locked }

class PredictionModel {
  const PredictionModel({
    required this.predictionId,
    required this.leagueId,
    required this.userId,
    required this.matchId,
    this.homeScore,
    this.awayScore,
    this.predictedWinnerTeamId,
    this.overUnder25,
    this.firstScorerPlayerId,
    this.status = PredictionStatus.draft,
    this.lockedAt,
    this.submittedAt,
    this.points = const PredictionPoints(),
  });

  final String predictionId;
  final String leagueId;
  final String userId;
  final String matchId;
  final int? homeScore;
  final int? awayScore;
  final String? predictedWinnerTeamId;
  final String? overUnder25;
  final String? firstScorerPlayerId;
  final PredictionStatus status;
  final DateTime? lockedAt;
  final DateTime? submittedAt;
  final PredictionPoints points;

  bool get isSubmitted =>
      homeScore != null && awayScore != null;

  factory PredictionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PredictionModel(
      predictionId: doc.id,
      leagueId: d['leagueId'] ?? '',
      userId: d['userId'] ?? '',
      matchId: d['matchId'] ?? '',
      homeScore: d['homeScore'],
      awayScore: d['awayScore'],
      predictedWinnerTeamId: d['predictedWinnerTeamId'],
      overUnder25: d['overUnder25'],
      firstScorerPlayerId: d['firstScorerPlayerId'],
      status: PredictionStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PredictionStatus.draft,
      ),
      lockedAt: (d['lockedAt'] as Timestamp?)?.toDate(),
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
      points: PredictionPoints.fromMap(d['points'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'predictionId': predictionId,
        'leagueId': leagueId,
        'userId': userId,
        'matchId': matchId,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'predictedWinnerTeamId': predictedWinnerTeamId,
        'overUnder25': overUnder25,
        'firstScorerPlayerId': firstScorerPlayerId,
        'status': status.name,
        'lockedAt': lockedAt != null ? Timestamp.fromDate(lockedAt!) : null,
        'submittedAt': submittedAt != null
            ? Timestamp.fromDate(submittedAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'points': points.toMap(),
      };
}

class PredictionPoints {
  const PredictionPoints({
    this.exactScore = 0,
    this.correctResult = 0,
    this.goalDifference = 0,
    this.totalGoals = 0,
    this.overUnder = 0,
    this.firstScorer = 0,
    this.total = 0,
  });

  final int exactScore;
  final int correctResult;
  final int goalDifference;
  final int totalGoals;
  final int overUnder;
  final int firstScorer;
  final int total;

  factory PredictionPoints.fromMap(Map<String, dynamic> m) => PredictionPoints(
        exactScore: m['exactScore'] ?? 0,
        correctResult: m['correctResult'] ?? 0,
        goalDifference: m['goalDifference'] ?? 0,
        totalGoals: m['totalGoals'] ?? 0,
        overUnder: m['overUnder'] ?? 0,
        firstScorer: m['firstScorer'] ?? 0,
        total: m['total'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'exactScore': exactScore,
        'correctResult': correctResult,
        'goalDifference': goalDifference,
        'totalGoals': totalGoals,
        'overUnder': overUnder,
        'firstScorer': firstScorer,
        'total': total,
      };
}
