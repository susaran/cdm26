import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../domain/match_model.dart';
import '../domain/player_model.dart';

part 'match_repository.g.dart';

@riverpod
MatchRepository matchRepository(Ref ref) => MatchRepository();

class MatchRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<MatchModel>> watchUpcomingMatches() {
    return _db
        .collection('matches')
        .where('tournamentId', isEqualTo: 'wc_2026')
        .orderBy('scheduledKickoff')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MatchModel.fromFirestore(d)).toList());
  }

  Stream<MatchModel?> watchMatch(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchModel.fromFirestore(doc) : null);
  }

  Stream<List<MatchEvent>> watchMatchEvents(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .collection('events')
        .orderBy('minute')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MatchEvent.fromFirestore(d)).toList());
  }

  Future<List<PlayerModel>> getPlayersByTeam(String teamId) async {
    final snap = await _db
        .collection('players')
        .where('teamId', isEqualTo: teamId)
        .where('tournamentId', isEqualTo: 'wc_2026')
        .get();
    return snap.docs.map((d) => PlayerModel.fromFirestore(d)).toList();
  }

  Future<List<PlayerModel>> getAllPlayers() async {
    final snap = await _db
        .collection('players')
        .where('tournamentId', isEqualTo: 'wc_2026')
        .orderBy('fantasyPrice', descending: true)
        .get();
    return snap.docs.map((d) => PlayerModel.fromFirestore(d)).toList();
  }

  Stream<List<PlayerModel>> watchAllPlayers() {
    return _db
        .collection('players')
        .where('tournamentId', isEqualTo: 'wc_2026')
        .orderBy('fantasyPrice', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PlayerModel.fromFirestore(d)).toList());
  }

  Stream<List<NationalTeam>> watchNationalTeams() {
    return _db
        .collection('teams')
        .where('tournamentId', isEqualTo: 'wc_2026')
        .orderBy('name')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NationalTeam.fromFirestore(d)).toList());
  }
}

class NationalTeam {
  const NationalTeam({
    required this.teamId,
    required this.name,
    required this.countryCode,
    this.flagEmoji = '',
    this.group = '',
  });

  final String teamId;
  final String name;
  final String countryCode;
  final String flagEmoji;
  final String group;

  factory NationalTeam.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NationalTeam(
      teamId: doc.id,
      name: d['name'] ?? '',
      countryCode: d['countryCode'] ?? '',
      flagEmoji: d['flagEmoji'] ?? '',
      group: d['group'] ?? '',
    );
  }
}
