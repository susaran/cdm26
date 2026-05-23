import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../matches/domain/player_model.dart';
import '../../team_builder/domain/team_model.dart';
import '../domain/draft_model.dart';

part 'draft_repository.g.dart';

@riverpod
DraftRepository draftRepository(Ref ref) => DraftRepository();

class DraftRepository {
  final _db = FirebaseFirestore.instance;

  DocumentReference _draftDoc(String leagueId) =>
      _db.collection('leagues').doc(leagueId).collection('draft').doc(leagueId);

  CollectionReference _picksCol(String leagueId) =>
      _db.collection('leagues').doc(leagueId).collection('draftPicks');

  DocumentReference _teamDoc(String leagueId, String userId) =>
      _db.collection('leagues').doc(leagueId).collection('teams').doc(userId);

  // ── Watch ──────────────────────────────────────────────────────────────────

  Stream<DraftModel?> watchDraft(String leagueId) {
    return _draftDoc(leagueId).snapshots().map(
          (doc) => doc.exists ? DraftModel.fromFirestore(doc) : null,
        );
  }

  Stream<List<DraftPick>> watchDraftPicks(String leagueId) {
    return _picksCol(leagueId)
        .orderBy('pickNumber')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DraftPick.fromFirestore(d)).toList());
  }

  Stream<List<PlayerModel>> watchAvailablePlayers(
      String leagueId, List<String> draftedIds) {
    // Firestore 'not-in' limit is 10 — for larger lists, we filter client-side
    return _db
        .collection('players')
        .where('tournamentId', isEqualTo: 'wc_2026')
        .orderBy('fantasyPrice', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PlayerModel.fromFirestore(d))
            .where((p) => !draftedIds.contains(p.playerId))
            .toList());
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> scheduleDraft(String leagueId, DateTime scheduledAt) async {
    await _draftDoc(leagueId).set({
      'leagueId': leagueId,
      'status': DraftStatus.scheduled.name,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'draftOrder': [],
      'currentPickIndex': 0,
      'picksPerMember': kSquadTotal + 1, // 15 players + 1 national team (DST)
      'pickDurationSeconds': 600,
      'draftedPlayerIds': [],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> startDraft(String leagueId, List<String> memberUserIds) async {
    final order = List<String>.from(memberUserIds)..shuffle(Random());
    await _draftDoc(leagueId).set({
      'leagueId': leagueId,
      'status': DraftStatus.active.name,
      'draftOrder': order,
      'startedAt': FieldValue.serverTimestamp(),
      'currentPickStartedAt': FieldValue.serverTimestamp(),
      'currentPickIndex': 0,
      'picksPerMember': kSquadTotal + 1, // 15 players + 1 national team (DST)
      'pickDurationSeconds': 600,
      'draftedPlayerIds': [],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSchedule(String leagueId, DateTime scheduledAt) =>
      scheduleDraft(leagueId, scheduledAt);

  Future<void> makePick(
    String leagueId,
    String userId,
    PlayerModel player,
    int pickIndex,
  ) async {
    final batch = _db.batch();
    final pickNumber = pickIndex + 1;
    final isDST = player.position == PlayerPosition.dst;

    // 1. Record the pick in the picks log
    final pickRef = _picksCol(leagueId).doc();
    batch.set(pickRef, {
      'leagueId': leagueId,
      'pickNumber': pickNumber,
      'userId': userId,
      'playerId': player.playerId,
      'playerName': player.displayName,
      'position': player.positionLabel,
      'teamName': player.teamName,
      'pickedAt': FieldValue.serverTimestamp(),
    });

    if (isDST) {
      // 2a. DST/country pick — set the national team slot on the team doc
      batch.set(
        _teamDoc(leagueId, userId),
        {
          'leagueId': leagueId,
          'userId': userId,
          'teamPickId': player.playerId,
          'teamPickName': player.displayName,
          'teamPickCountryCode': player.countryCode,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      // 2b. Regular player pick — add to the players array
      final slot = TeamPlayerSlot(
        playerId: player.playerId,
        position: player.positionLabel,
        purchasePrice: 0,
        displayName: player.displayName,
        teamName: player.teamName,
        countryCode: player.countryCode,
        photoUrl: player.photoUrl,
        slot: 'starter',
      );
      batch.set(
        _teamDoc(leagueId, userId),
        {
          'leagueId': leagueId,
          'userId': userId,
          'players': FieldValue.arrayUnion([slot.toMap()]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // 3. Advance the draft state
    batch.update(_draftDoc(leagueId), {
      'currentPickIndex': FieldValue.increment(1),
      'currentPickStartedAt': FieldValue.serverTimestamp(),
      'draftedPlayerIds': FieldValue.arrayUnion([player.playerId]),
    });

    await batch.commit();
  }

  Future<void> completeDraft(String leagueId) async {
    await _draftDoc(leagueId).update({
      'status': DraftStatus.completed.name,
    });
  }

  Future<void> cancelDraft(String leagueId) async {
    await _draftDoc(leagueId).update({
      'status': DraftStatus.cancelled.name,
    });
  }

  Future<void> resetDraft(String leagueId) async {
    await _draftDoc(leagueId).delete();
  }
}
