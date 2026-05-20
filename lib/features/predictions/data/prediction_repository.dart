import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../../core/errors/app_exception.dart';
import '../../matches/domain/match_model.dart';
import '../domain/prediction_model.dart';

part 'prediction_repository.g.dart';

@riverpod
PredictionRepository predictionRepository(Ref ref) => PredictionRepository();

class PredictionRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference _predictions(String leagueId) =>
      _db.collection('leagues').doc(leagueId).collection('predictions');

  Future<void> submitPrediction(PredictionModel prediction) async {
    await _predictions(prediction.leagueId)
        .doc(prediction.predictionId)
        .set(prediction.toMap(), SetOptions(merge: true));
  }

  Future<void> savePrediction({
    required String leagueId,
    required String userId,
    required String matchId,
    required MatchModel match,
    required int homeScore,
    required int awayScore,
    String? firstScorerPlayerId,
    String? overUnder25,
  }) async {
    // Server enforces lock: reject if match kickoff has passed
    final now = DateTime.now().toUtc();
    final kickoff = match.scheduledKickoff.toUtc();
    if (now.isAfter(kickoff)) {
      throw const PredictionException(
          'Predictions are locked for this match.');
    }

    final predictionId = '${userId}_$matchId';
    final winner = homeScore > awayScore
        ? match.homeTeamId
        : awayScore > homeScore
            ? match.awayTeamId
            : null;

    final prediction = PredictionModel(
      predictionId: predictionId,
      leagueId: leagueId,
      userId: userId,
      matchId: matchId,
      homeScore: homeScore,
      awayScore: awayScore,
      predictedWinnerTeamId: winner,
      overUnder25: overUnder25 ??
          ((homeScore + awayScore) > 2 ? 'over' : 'under'),
      firstScorerPlayerId: firstScorerPlayerId,
      status: PredictionStatus.submitted,
      submittedAt: DateTime.now(),
    );

    await _predictions(leagueId)
        .doc(predictionId)
        .set(prediction.toMap(), SetOptions(merge: true));
  }

  Stream<List<PredictionModel>> watchUserPredictions(
      String leagueId, String userId) {
    return _predictions(leagueId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PredictionModel.fromFirestore(d)).toList());
  }

  Future<PredictionModel?> getPrediction(
      String leagueId, String userId, String matchId) async {
    final doc = await _predictions(leagueId).doc('${userId}_$matchId').get();
    if (!doc.exists) return null;
    return PredictionModel.fromFirestore(doc);
  }
}
