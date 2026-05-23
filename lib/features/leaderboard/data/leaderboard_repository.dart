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
        .map((snap) => _parseEntries(snap.docs));
  }

  List<LeaderboardEntry> _parseEntries(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final entries = docs.map((doc) {
      final d = doc.data();
      final tb = d['tiebreakers'] as Map<String, dynamic>? ?? {};
      final raw = d['roundPoints'] as Map<String, dynamic>? ?? {};
      final roundPoints = {
        for (final kv in raw.entries)
          int.tryParse(kv.key.replaceFirst('r', '')) ?? 0:
              (kv.value as num).toInt(),
      };
      return LeaderboardEntry(
        userId: doc.id,
        displayName: d['displayName'] ?? '',
        photoUrl: d['photoUrl'],
        teamName: d['teamName'],
        teamBadgeUrl: d['teamBadgeUrl'],
        previousRank: d['previousRank'],
        totalPoints: (d['totalPoints'] as num?)?.toInt() ?? 0,
        fantasyPoints: (d['fantasyPoints'] as num?)?.toInt() ?? 0,
        predictionPoints: (d['predictionPoints'] as num?)?.toInt() ?? 0,
        exactScores: (tb['exactScores'] as num?)?.toInt() ?? 0,
        correctResults: (tb['correctResults'] as num?)?.toInt() ?? 0,
        roundPoints: roundPoints,
      );
    }).toList();

    // Assign ranks by total points (already sorted by Firestore)
    return entries.asMap().entries.map((e) {
      return LeaderboardEntry(
        userId: e.value.userId,
        displayName: e.value.displayName,
        photoUrl: e.value.photoUrl,
        teamName: e.value.teamName,
        teamBadgeUrl: e.value.teamBadgeUrl,
        rank: e.key + 1,
        previousRank: e.value.previousRank,
        totalPoints: e.value.totalPoints,
        fantasyPoints: e.value.fantasyPoints,
        predictionPoints: e.value.predictionPoints,
        exactScores: e.value.exactScores,
        correctResults: e.value.correctResults,
        roundPoints: e.value.roundPoints,
      );
    }).toList();
  }
}
