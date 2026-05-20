import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole { owner, admin, member }
enum MemberStatus { invited, active, removed, left, banned }
enum PaidStatus { notApplicable, unpaid, pending, paid, refunded }

class LeagueMemberModel {
  const LeagueMemberModel({
    required this.userId,
    required this.leagueId,
    required this.displayName,
    required this.joinedAt,
    this.photoUrl,
    this.role = MemberRole.member,
    this.status = MemberStatus.active,
    this.paidStatus = PaidStatus.notApplicable,
    this.totalPoints = 0,
    this.fantasyPoints = 0,
    this.predictionPoints = 0,
    this.rank,
    this.previousRank,
    this.tiebreakers = const Tiebreakers(),
  });

  final String userId;
  final String leagueId;
  final String displayName;
  final String? photoUrl;
  final MemberRole role;
  final MemberStatus status;
  final PaidStatus paidStatus;
  final DateTime joinedAt;
  final int totalPoints;
  final int fantasyPoints;
  final int predictionPoints;
  final int? rank;
  final int? previousRank;
  final Tiebreakers tiebreakers;

  factory LeagueMemberModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LeagueMemberModel(
      userId: doc.id,
      leagueId: d['leagueId'] ?? '',
      displayName: d['displayName'] ?? '',
      photoUrl: d['photoUrl'],
      role: MemberRole.values.firstWhere(
          (e) => e.name == d['role'], orElse: () => MemberRole.member),
      status: MemberStatus.values.firstWhere(
          (e) => e.name == d['status'], orElse: () => MemberStatus.active),
      paidStatus: PaidStatus.values.firstWhere(
          (e) => e.name == d['paidStatus'],
          orElse: () => PaidStatus.notApplicable),
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalPoints: d['totalPoints'] ?? 0,
      fantasyPoints: d['fantasyPoints'] ?? 0,
      predictionPoints: d['predictionPoints'] ?? 0,
      rank: d['rank'],
      previousRank: d['previousRank'],
      tiebreakers: Tiebreakers.fromMap(d['tiebreakers'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'leagueId': leagueId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role.name,
        'status': status.name,
        'paidStatus': paidStatus.name,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'totalPoints': totalPoints,
        'fantasyPoints': fantasyPoints,
        'predictionPoints': predictionPoints,
        'rank': rank,
        'previousRank': previousRank,
        'tiebreakers': tiebreakers.toMap(),
      };
}

class Tiebreakers {
  const Tiebreakers({
    this.exactScores = 0,
    this.correctResults = 0,
    this.captainPoints = 0,
    this.transfersUsed = 0,
    this.teamSubmittedAt,
  });

  final int exactScores;
  final int correctResults;
  final int captainPoints;
  final int transfersUsed;
  final DateTime? teamSubmittedAt;

  factory Tiebreakers.fromMap(Map<String, dynamic> m) => Tiebreakers(
        exactScores: m['exactScores'] ?? 0,
        correctResults: m['correctResults'] ?? 0,
        captainPoints: m['captainPoints'] ?? 0,
        transfersUsed: m['transfersUsed'] ?? 0,
        teamSubmittedAt:
            (m['teamSubmittedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'exactScores': exactScores,
        'correctResults': correctResults,
        'captainPoints': captainPoints,
        'transfersUsed': transfersUsed,
        'teamSubmittedAt': teamSubmittedAt != null
            ? Timestamp.fromDate(teamSubmittedAt!)
            : null,
      };
}
