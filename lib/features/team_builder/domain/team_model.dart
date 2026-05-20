import 'package:cloud_firestore/cloud_firestore.dart';

enum TeamStatus { draft, submitted, locked, invalid }

// Required squad composition (FPL-style)
const kSquadTotal = 15;
const kRequiredGK = 2;
const kRequiredDEF = 5;
const kRequiredMID = 5;
const kRequiredFWD = 3;
const kStartingXI = 11;
const kBenchSize = 4;

class TeamPlayerSlot {
  const TeamPlayerSlot({
    required this.playerId,
    required this.position,
    required this.purchasePrice,
    required this.displayName,
    this.teamName = '',
    this.countryCode = '',
    this.photoUrl,
    this.slot = 'starter',
  });

  final String playerId;
  final String position;
  final String slot; // 'starter' | 'bench'
  final double purchasePrice;
  final String displayName;
  final String teamName;
  final String countryCode;
  final String? photoUrl;

  bool get isBench => slot == 'bench';
  bool get isStarter => slot == 'starter';

  TeamPlayerSlot copyWith({String? slot}) => TeamPlayerSlot(
        playerId: playerId,
        position: position,
        purchasePrice: purchasePrice,
        displayName: displayName,
        teamName: teamName,
        countryCode: countryCode,
        photoUrl: photoUrl,
        slot: slot ?? this.slot,
      );

  factory TeamPlayerSlot.fromMap(Map<String, dynamic> m) => TeamPlayerSlot(
        playerId: m['playerId'] ?? '',
        position: m['position'] ?? 'MID',
        slot: m['slot'] ?? 'starter',
        purchasePrice: (m['purchasePrice'] as num?)?.toDouble() ?? 0,
        displayName: m['displayName'] ?? '',
        teamName: m['teamName'] ?? '',
        countryCode: m['countryCode'] ?? '',
        photoUrl: m['photoUrl'],
      );

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'position': position,
        'slot': slot,
        'purchasePrice': purchasePrice,
        'displayName': displayName,
        'teamName': teamName,
        'countryCode': countryCode,
        'photoUrl': photoUrl,
      };
}

class TeamModel {
  const TeamModel({
    required this.leagueId,
    required this.userId,
    required this.players,
    this.formation = '4-3-3',
    this.budgetLimit = 100,
    this.budgetUsed = 0,
    this.status = TeamStatus.draft,
    this.captainPlayerId,
    this.viceCaptainPlayerId,
    this.teamPickId,
    this.teamPickName,
    this.submittedAt,
    this.validation = const TeamValidation(),
  });

  final String leagueId;
  final String userId;
  final String formation;
  final double budgetLimit;
  final double budgetUsed;
  final TeamStatus status;
  final String? captainPlayerId;
  final String? viceCaptainPlayerId;
  final String? teamPickId;   // national team chosen as DST slot
  final String? teamPickName;
  final DateTime? submittedAt;
  final List<TeamPlayerSlot> players;
  final TeamValidation validation;

  double get budgetRemaining => budgetLimit - budgetUsed;

  List<TeamPlayerSlot> get starters =>
      players.where((p) => p.isStarter).toList();
  List<TeamPlayerSlot> get bench =>
      players.where((p) => p.isBench).toList();

  int get gkCount => players.where((p) => p.position == 'GK').length;
  int get defCount => players.where((p) => p.position == 'DEF').length;
  int get midCount => players.where((p) => p.position == 'MID').length;
  int get fwdCount => players.where((p) => p.position == 'FWD').length;

  // How many more of each position can still be picked
  int get gkSlotsFree => kRequiredGK - gkCount;
  int get defSlotsFree => kRequiredDEF - defCount;
  int get midSlotsFree => kRequiredMID - midCount;
  int get fwdSlotsFree => kRequiredFWD - fwdCount;

  bool get hasMinimumPlayers =>
      players.length >= kSquadTotal &&
      gkCount >= kRequiredGK &&
      defCount >= kRequiredDEF &&
      midCount >= kRequiredMID &&
      fwdCount >= kRequiredFWD &&
      captainPlayerId != null &&
      teamPickId != null;

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeamModel(
      leagueId: d['leagueId'] ?? '',
      userId: doc.id,
      formation: d['formation'] ?? '4-3-3',
      budgetLimit: (d['budgetLimit'] as num?)?.toDouble() ?? 100,
      budgetUsed: (d['budgetUsed'] as num?)?.toDouble() ?? 0,
      status: TeamStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => TeamStatus.draft,
      ),
      captainPlayerId: d['captainPlayerId'],
      viceCaptainPlayerId: d['viceCaptainPlayerId'],
      teamPickId: d['teamPickId'],
      teamPickName: d['teamPickName'],
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
      players: (d['players'] as List<dynamic>? ?? [])
          .map((p) => TeamPlayerSlot.fromMap(p as Map<String, dynamic>))
          .toList(),
      validation: TeamValidation.fromMap(d['validation'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'leagueId': leagueId,
        'userId': userId,
        'formation': formation,
        'budgetLimit': budgetLimit,
        'budgetUsed': budgetUsed,
        'status': status.name,
        'captainPlayerId': captainPlayerId,
        'viceCaptainPlayerId': viceCaptainPlayerId,
        'teamPickId': teamPickId,
        'teamPickName': teamPickName,
        'submittedAt':
            submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
        'players': players.map((p) => p.toMap()).toList(),
        'validation': validation.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  TeamModel copyWith({
    List<TeamPlayerSlot>? players,
    double? budgetUsed,
    String? formation,
    String? captainPlayerId,
    String? viceCaptainPlayerId,
    Object? teamPickId = _sentinel,
    Object? teamPickName = _sentinel,
    TeamStatus? status,
    TeamValidation? validation,
  }) =>
      TeamModel(
        leagueId: leagueId,
        userId: userId,
        formation: formation ?? this.formation,
        budgetLimit: budgetLimit,
        budgetUsed: budgetUsed ?? this.budgetUsed,
        status: status ?? this.status,
        captainPlayerId: captainPlayerId ?? this.captainPlayerId,
        viceCaptainPlayerId: viceCaptainPlayerId ?? this.viceCaptainPlayerId,
        teamPickId: teamPickId == _sentinel ? this.teamPickId : teamPickId as String?,
        teamPickName: teamPickName == _sentinel ? this.teamPickName : teamPickName as String?,
        submittedAt: submittedAt,
        players: players ?? this.players,
        validation: validation ?? this.validation,
      );
}

// Sentinel for nullable copyWith fields
const Object _sentinel = Object();

class TeamValidation {
  const TeamValidation({this.isValid = true, this.errors = const []});
  final bool isValid;
  final List<String> errors;

  factory TeamValidation.fromMap(Map<String, dynamic> m) => TeamValidation(
        isValid: m['isValid'] ?? true,
        errors: List<String>.from(m['errors'] ?? []),
      );

  Map<String, dynamic> toMap() => {'isValid': isValid, 'errors': errors};
}
