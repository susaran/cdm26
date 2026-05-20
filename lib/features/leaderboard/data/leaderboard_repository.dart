import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../domain/leaderboard_entry_model.dart';

part 'leaderboard_repository.g.dart';

@riverpod
LeaderboardRepository leaderboardRepository(Ref ref) =>
    LeaderboardRepository();

class LeaderboardRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<LeaderboardEntry>> watchLeaderboard(String leagueId) {
    return _db
        .collection('leagues')
        .doc(leagueId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final d = entry.value.data();
        final tb = d['tiebreakers'] as Map<String, dynamic>? ?? {};
        return LeaderboardEntry(
          userId: entry.value.id,
          displayName: d['displayName'] ?? '',
          photoUrl: d['photoUrl'],
          rank: rank,
          previousRank: d['previousRank'],
          totalPoints: d['totalPoints'] ?? 0,
          fantasyPoints: d['fantasyPoints'] ?? 0,
          predictionPoints: d['predictionPoints'] ?? 0,
          exactScores: tb['exactScores'] ?? 0,
          correctResults: tb['correctResults'] ?? 0,
        );
      }).toList();
    });
  }
}
