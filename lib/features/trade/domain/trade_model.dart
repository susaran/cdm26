import 'package:cloud_firestore/cloud_firestore.dart';

enum TradeStatus { pending, accepted, rejected, cancelled, expired }

// Trades are open until the WC 2026 semifinals end (before the final)
final _tradeDeadline = DateTime.utc(2026, 7, 14);

bool get isTradeWindowOpen =>
    DateTime.now().toUtc().isBefore(_tradeDeadline);

class TradeModel {
  const TradeModel({
    required this.tradeId,
    required this.leagueId,
    required this.proposerId,
    required this.proposerDisplayName,
    required this.targetUserId,
    required this.targetDisplayName,
    required this.offeredPlayers,
    required this.requestedPlayers,
    required this.status,
    required this.proposedAt,
    this.resolvedAt,
    this.message,
  });

  final String tradeId;
  final String leagueId;
  final String proposerId;
  final String proposerDisplayName;
  final String targetUserId;
  final String targetDisplayName;
  final List<TradedPlayer> offeredPlayers;
  final List<TradedPlayer> requestedPlayers;
  final TradeStatus status;
  final DateTime proposedAt;
  final DateTime? resolvedAt;
  final String? message;

  bool get isPending => status == TradeStatus.pending;

  factory TradeModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TradeModel(
      tradeId: doc.id,
      leagueId: d['leagueId'] ?? '',
      proposerId: d['proposerId'] ?? '',
      proposerDisplayName: d['proposerDisplayName'] ?? '',
      targetUserId: d['targetUserId'] ?? '',
      targetDisplayName: d['targetDisplayName'] ?? '',
      offeredPlayers: (d['offeredPlayers'] as List<dynamic>? ?? [])
          .map((p) => TradedPlayer.fromMap(p as Map<String, dynamic>))
          .toList(),
      requestedPlayers: (d['requestedPlayers'] as List<dynamic>? ?? [])
          .map((p) => TradedPlayer.fromMap(p as Map<String, dynamic>))
          .toList(),
      status: TradeStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => TradeStatus.pending,
      ),
      proposedAt: (d['proposedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
      message: d['message'],
    );
  }

  Map<String, dynamic> toMap() => {
        'leagueId': leagueId,
        'proposerId': proposerId,
        'proposerDisplayName': proposerDisplayName,
        'targetUserId': targetUserId,
        'targetDisplayName': targetDisplayName,
        'offeredPlayers': offeredPlayers.map((p) => p.toMap()).toList(),
        'requestedPlayers': requestedPlayers.map((p) => p.toMap()).toList(),
        'status': status.name,
        'proposedAt': Timestamp.fromDate(proposedAt),
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'message': message,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class TradedPlayer {
  const TradedPlayer({
    required this.playerId,
    required this.displayName,
    required this.position,
    required this.teamName,
  });

  final String playerId;
  final String displayName;
  final String position;
  final String teamName;

  factory TradedPlayer.fromMap(Map<String, dynamic> m) => TradedPlayer(
        playerId: m['playerId'] ?? '',
        displayName: m['displayName'] ?? '',
        position: m['position'] ?? '',
        teamName: m['teamName'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'displayName': displayName,
        'position': position,
        'teamName': teamName,
      };
}
