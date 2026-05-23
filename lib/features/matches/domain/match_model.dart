import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus {
  scheduled,
  lineupsAvailable,
  live,
  halftime,
  extraTime,
  penalties,
  finished,
  postponed,
  cancelled,
  abandoned,
}

enum MatchStage {
  group,
  roundOf32,
  roundOf16,
  quarterfinal,
  semifinal,
  thirdPlace,
  finalStage,
}

// WC 2026 scoring rounds:
//   1 = Group Stage MD1   4 = Round of 32   7 = Semi-Finals
//   2 = Group Stage MD2   5 = Round of 16   8 = Third Place
//   3 = Group Stage MD3   6 = Quarter-Finals 9 = Final
class MatchModel {
  const MatchModel({
    required this.matchId,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.scheduledKickoff,
    this.providerMatchId,
    this.stage = MatchStage.group,
    this.group,
    this.matchday,
    this.scoringRound,
    this.scoringRoundLabel,
    this.homeScore = 0,
    this.awayScore = 0,
    this.status = MatchStatus.scheduled,
    this.minute = 0,
    this.homeFlag,
    this.awayFlag,
    this.lineupsAvailable = false,
    this.actualKickoff,
    this.winnerTeamId,
  });

  final String matchId;
  final String? providerMatchId;
  final String tournamentId;
  final MatchStage stage;
  final String? group;
  // 1–3 within group stage; null for knockout rounds
  final int? matchday;
  // 1–9 global scoring round (see comment above)
  final int? scoringRound;
  final String? scoringRoundLabel;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeFlag;
  final String? awayFlag;
  final DateTime scheduledKickoff;
  final DateTime? actualKickoff;
  final MatchStatus status;
  final int minute;
  final int homeScore;
  final int awayScore;
  final String? winnerTeamId;
  final bool lineupsAvailable;

  bool get isLive =>
      status == MatchStatus.live ||
      status == MatchStatus.halftime ||
      status == MatchStatus.extraTime ||
      status == MatchStatus.penalties;

  bool get isFinished => status == MatchStatus.finished;

  bool get isUpcoming =>
      status == MatchStatus.scheduled ||
      status == MatchStatus.lineupsAvailable;

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final score = d['score'] as Map<String, dynamic>? ?? {};
    return MatchModel(
      matchId: doc.id,
      providerMatchId: d['providerMatchId'],
      tournamentId: d['tournamentId'] ?? 'wc_2026',
      stage: MatchStage.values.firstWhere(
        (e) => e.name == d['stage'],
        orElse: () => MatchStage.group,
      ),
      group: d['group'],
      matchday: d['matchday'] as int?,
      scoringRound: d['scoringRound'] as int?,
      scoringRoundLabel: d['scoringRoundLabel'] as String?,
      homeTeamId: d['homeTeamId'] ?? '',
      awayTeamId: d['awayTeamId'] ?? '',
      homeTeamName: d['homeTeamName'] ?? '',
      awayTeamName: d['awayTeamName'] ?? '',
      homeFlag: d['homeFlag'],
      awayFlag: d['awayFlag'],
      scheduledKickoff:
          (d['scheduledKickoff'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actualKickoff: (d['actualKickoff'] as Timestamp?)?.toDate(),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      minute: d['minute'] ?? 0,
      homeScore: score['home'] ?? 0,
      awayScore: score['away'] ?? 0,
      winnerTeamId: d['winnerTeamId'],
      lineupsAvailable: d['lineupsAvailable'] ?? false,
    );
  }
}

class MatchEvent {
  const MatchEvent({
    required this.eventId,
    required this.matchId,
    required this.type,
    required this.minute,
    this.teamId,
    this.playerId,
    this.assistPlayerId,
    this.description,
  });

  final String eventId;
  final String matchId;
  final String type;
  final String? teamId;
  final String? playerId;
  final String? assistPlayerId;
  final int minute;
  final String? description;

  factory MatchEvent.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MatchEvent(
      eventId: doc.id,
      matchId: d['matchId'] ?? '',
      type: d['type'] ?? '',
      teamId: d['teamId'],
      playerId: d['playerId'],
      assistPlayerId: d['assistPlayerId'],
      minute: d['minute'] ?? 0,
      description: d['description'],
    );
  }
}
