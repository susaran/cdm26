import 'package:cloud_firestore/cloud_firestore.dart';

enum DraftStatus { scheduled, active, completed, cancelled }

class DraftModel {
  const DraftModel({
    required this.leagueId,
    required this.status,
    required this.draftOrder,
    required this.currentPickIndex,
    required this.picksPerMember,
    this.scheduledAt,
    this.startedAt,
    this.currentPickStartedAt,
    this.pickDurationSeconds = 120,
    this.draftedPlayerIds = const [],
  });

  final String leagueId;
  final DraftStatus status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? currentPickStartedAt;
  final List<String> draftOrder;   // userId order, determined at draft start
  final int currentPickIndex;      // 0-based, across all rounds
  final int picksPerMember;        // 15 (squad size)
  final int pickDurationSeconds;
  final List<String> draftedPlayerIds;

  int get totalPicks => draftOrder.isEmpty ? 0 : draftOrder.length * picksPerMember;
  bool get isDone => currentPickIndex >= totalPicks;
  bool get isActive => status == DraftStatus.active && !isDone;

  String? get currentPickUserId {
    if (draftOrder.isEmpty || isDone) return null;
    final n = draftOrder.length;
    final round = currentPickIndex ~/ n;
    final posInRound = currentPickIndex % n;
    final idx = round.isEven ? posInRound : (n - 1 - posInRound);
    return draftOrder[idx];
  }

  int get currentRound => draftOrder.isEmpty ? 0 : currentPickIndex ~/ draftOrder.length + 1;
  int get pickInRound => draftOrder.isEmpty ? 0 : currentPickIndex % draftOrder.length + 1;

  factory DraftModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DraftModel(
      leagueId: doc.id,
      status: DraftStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => DraftStatus.scheduled,
      ),
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate(),
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      currentPickStartedAt: (d['currentPickStartedAt'] as Timestamp?)?.toDate(),
      draftOrder: List<String>.from(d['draftOrder'] ?? []),
      currentPickIndex: d['currentPickIndex'] ?? 0,
      picksPerMember: d['picksPerMember'] ?? 15,
      pickDurationSeconds: d['pickDurationSeconds'] ?? 120,
      draftedPlayerIds: List<String>.from(d['draftedPlayerIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'leagueId': leagueId,
        'status': status.name,
        'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
        'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
        'currentPickStartedAt': currentPickStartedAt != null
            ? Timestamp.fromDate(currentPickStartedAt!)
            : null,
        'draftOrder': draftOrder,
        'currentPickIndex': currentPickIndex,
        'picksPerMember': picksPerMember,
        'pickDurationSeconds': pickDurationSeconds,
        'draftedPlayerIds': draftedPlayerIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class DraftPick {
  const DraftPick({
    required this.pickId,
    required this.leagueId,
    required this.pickNumber,
    required this.userId,
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.teamName,
    required this.pickedAt,
  });

  final String pickId;
  final String leagueId;
  final int pickNumber;
  final String userId;
  final String playerId;
  final String playerName;
  final String position;
  final String teamName;
  final DateTime pickedAt;

  factory DraftPick.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DraftPick(
      pickId: doc.id,
      leagueId: d['leagueId'] ?? '',
      pickNumber: d['pickNumber'] ?? 0,
      userId: d['userId'] ?? '',
      playerId: d['playerId'] ?? '',
      playerName: d['playerName'] ?? '',
      position: d['position'] ?? '',
      teamName: d['teamName'] ?? '',
      pickedAt: (d['pickedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'leagueId': leagueId,
        'pickNumber': pickNumber,
        'userId': userId,
        'playerId': playerId,
        'playerName': playerName,
        'position': position,
        'teamName': teamName,
        'pickedAt': Timestamp.fromDate(pickedAt),
      };
}
