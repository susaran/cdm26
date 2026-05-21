import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../team_builder/domain/team_model.dart';
import '../domain/trade_model.dart';

part 'trade_repository.g.dart';

@riverpod
TradeRepository tradeRepository(Ref ref) => TradeRepository();

class TradeRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference _tradesCol(String leagueId) =>
      _db.collection('leagues').doc(leagueId).collection('trades');

  DocumentReference _teamDoc(String leagueId, String userId) =>
      _db.collection('leagues').doc(leagueId).collection('teams').doc(userId);

  Stream<List<TradeModel>> watchLeagueTrades(String leagueId, String userId) {
    // Watch trades where the user is either proposer or target
    return _tradesCol(leagueId)
        .orderBy('proposedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TradeModel.fromFirestore(d))
            .where((t) => t.proposerId == userId || t.targetUserId == userId)
            .toList());
  }

  Future<void> proposeTrade({
    required String leagueId,
    required String proposerId,
    required String proposerDisplayName,
    required String targetUserId,
    required String targetDisplayName,
    required List<TradedPlayer> offeredPlayers,
    required List<TradedPlayer> requestedPlayers,
    String? message,
  }) async {
    await _tradesCol(leagueId).add({
      'leagueId': leagueId,
      'proposerId': proposerId,
      'proposerDisplayName': proposerDisplayName,
      'targetUserId': targetUserId,
      'targetDisplayName': targetDisplayName,
      'offeredPlayers': offeredPlayers.map((p) => p.toMap()).toList(),
      'requestedPlayers': requestedPlayers.map((p) => p.toMap()).toList(),
      'status': TradeStatus.pending.name,
      'proposedAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
      'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptTrade(String leagueId, TradeModel trade) async {
    final batch = _db.batch();

    // Fetch both teams
    final proposerTeamSnap = await _teamDoc(leagueId, trade.proposerId).get();
    final targetTeamSnap = await _teamDoc(leagueId, trade.targetUserId).get();

    if (!proposerTeamSnap.exists || !targetTeamSnap.exists) {
      throw Exception('One or both teams not found.');
    }

    final proposerTeam = TeamModel.fromFirestore(proposerTeamSnap);
    final targetTeam = TeamModel.fromFirestore(targetTeamSnap);

    // Build offered and requested playerIds sets
    final offeredIds = trade.offeredPlayers.map((p) => p.playerId).toSet();
    final requestedIds = trade.requestedPlayers.map((p) => p.playerId).toSet();

    // Remove offered players from proposer, add requested
    final newProposerPlayers = proposerTeam.players
        .where((p) => !offeredIds.contains(p.playerId))
        .toList();

    for (final tp in trade.requestedPlayers) {
      // Find the slot from target's team
      final slot = targetTeam.players.firstWhere(
        (p) => p.playerId == tp.playerId,
        orElse: () => TeamPlayerSlot(
          playerId: tp.playerId,
          position: tp.position,
          purchasePrice: 0,
          displayName: tp.displayName,
          teamName: tp.teamName,
        ),
      );
      newProposerPlayers.add(slot);
    }

    // Remove requested players from target, add offered
    final newTargetPlayers = targetTeam.players
        .where((p) => !requestedIds.contains(p.playerId))
        .toList();

    for (final tp in trade.offeredPlayers) {
      final slot = proposerTeam.players.firstWhere(
        (p) => p.playerId == tp.playerId,
        orElse: () => TeamPlayerSlot(
          playerId: tp.playerId,
          position: tp.position,
          purchasePrice: 0,
          displayName: tp.displayName,
          teamName: tp.teamName,
        ),
      );
      newTargetPlayers.add(slot);
    }

    // Update both teams
    batch.update(_teamDoc(leagueId, trade.proposerId), {
      'players': newProposerPlayers.map((p) => p.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_teamDoc(leagueId, trade.targetUserId), {
      'players': newTargetPlayers.map((p) => p.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Mark trade accepted
    batch.update(_tradesCol(leagueId).doc(trade.tradeId), {
      'status': TradeStatus.accepted.name,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Cancel any other pending trades involving these players
    await batch.commit();
  }

  Future<void> rejectTrade(String leagueId, String tradeId) async {
    await _tradesCol(leagueId).doc(tradeId).update({
      'status': TradeStatus.rejected.name,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelTrade(String leagueId, String tradeId) async {
    await _tradesCol(leagueId).doc(tradeId).update({
      'status': TradeStatus.cancelled.name,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
