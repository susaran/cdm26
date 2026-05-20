import 'package:cloud_firestore/cloud_firestore.dart';

enum PlayerPosition { gk, def, mid, fwd }
enum PlayerStatus { active, injured, suspended, doubtful, notSelected, unknown }

class PlayerModel {
  const PlayerModel({
    required this.playerId,
    required this.teamId,
    required this.displayName,
    required this.position,
    required this.fantasyPrice,
    this.providerPlayerId,
    this.tournamentId = 'wc_2026',
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.shirtNumber,
    this.age,
    this.countryCode = '',
    this.teamName = '',
    this.status = PlayerStatus.unknown,
    this.injuryStatus,
    this.ownershipPct = 0,
    this.statsSummary = const PlayerStatsSummary(),
  });

  final String playerId;
  final String? providerPlayerId;
  final String tournamentId;
  final String teamId;
  final String? firstName;
  final String? lastName;
  final String displayName;
  final PlayerPosition position;
  final String? photoUrl;
  final int? shirtNumber;
  final int? age;
  final String countryCode;
  final String teamName;
  final PlayerStatus status;
  final String? injuryStatus;
  final double fantasyPrice;
  final double ownershipPct;
  final PlayerStatsSummary statsSummary;

  String get positionLabel => switch (position) {
        PlayerPosition.gk => 'GK',
        PlayerPosition.def => 'DEF',
        PlayerPosition.mid => 'MID',
        PlayerPosition.fwd => 'FWD',
      };

  factory PlayerModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PlayerModel(
      playerId: doc.id,
      providerPlayerId: d['providerPlayerId'],
      tournamentId: d['tournamentId'] ?? 'wc_2026',
      teamId: d['teamId'] ?? '',
      firstName: d['firstName'],
      lastName: d['lastName'],
      displayName: d['displayName'] ?? '',
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == (d['position'] as String?)?.toLowerCase(),
        orElse: () => PlayerPosition.mid,
      ),
      photoUrl: d['photoUrl'],
      shirtNumber: d['shirtNumber'],
      age: d['age'],
      countryCode: d['countryCode'] ?? '',
      teamName: d['teamName'] ?? '',
      status: PlayerStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PlayerStatus.unknown,
      ),
      injuryStatus: d['injuryStatus'],
      fantasyPrice: (d['fantasyPrice'] as num?)?.toDouble() ?? 5.0,
      ownershipPct: (d['ownershipPct'] as num?)?.toDouble() ?? 0,
      statsSummary: PlayerStatsSummary.fromMap(d['statsSummary'] ?? {}),
    );
  }
}

class PlayerStatsSummary {
  const PlayerStatsSummary({
    this.appearances = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.totalFantasyPoints = 0,
  });

  final int appearances;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int totalFantasyPoints;

  factory PlayerStatsSummary.fromMap(Map<String, dynamic> m) =>
      PlayerStatsSummary(
        appearances: m['appearances'] ?? 0,
        goals: m['goals'] ?? 0,
        assists: m['assists'] ?? 0,
        yellowCards: m['yellowCards'] ?? 0,
        redCards: m['redCards'] ?? 0,
        totalFantasyPoints: m['totalFantasyPoints'] ?? 0,
      );
}
