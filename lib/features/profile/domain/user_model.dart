import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.username,
    required this.createdAt,
    this.photoUrl,
    this.favoriteTeamId,
    this.countryCode,
    this.timezone,
    this.isDeleted = false,
    this.ageConfirmed = false,
    this.termsAcceptedAt,
    this.stats = const UserStats(),
    this.notificationSettings = const NotificationSettings(),
  });

  final String userId;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String? favoriteTeamId;
  final String? countryCode;
  final String? timezone;
  final bool isDeleted;
  final bool ageConfirmed;
  final DateTime createdAt;
  final DateTime? termsAcceptedAt;
  final UserStats stats;
  final NotificationSettings notificationSettings;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      photoUrl: data['photoUrl'],
      favoriteTeamId: data['favoriteTeamId'],
      countryCode: data['countryCode'],
      timezone: data['timezone'],
      isDeleted: data['isDeleted'] ?? false,
      ageConfirmed: data['ageConfirmed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      termsAcceptedAt:
          (data['termsAcceptedAt'] as Timestamp?)?.toDate(),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      notificationSettings:
          NotificationSettings.fromMap(data['notificationSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'photoUrl': photoUrl,
        'favoriteTeamId': favoriteTeamId,
        'countryCode': countryCode,
        'timezone': timezone,
        'isDeleted': isDeleted,
        'ageConfirmed': ageConfirmed,
        'createdAt': Timestamp.fromDate(createdAt),
        'termsAcceptedAt':
            termsAcceptedAt != null ? Timestamp.fromDate(termsAcceptedAt!) : null,
        'stats': stats.toMap(),
        'notificationSettings': notificationSettings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'role': 'user',
      };

  UserModel copyWith({
    String? displayName,
    String? username,
    String? photoUrl,
    String? favoriteTeamId,
    String? countryCode,
    String? timezone,
    UserStats? stats,
    NotificationSettings? notificationSettings,
  }) =>
      UserModel(
        userId: userId,
        email: email,
        displayName: displayName ?? this.displayName,
        username: username ?? this.username,
        photoUrl: photoUrl ?? this.photoUrl,
        favoriteTeamId: favoriteTeamId ?? this.favoriteTeamId,
        countryCode: countryCode ?? this.countryCode,
        timezone: timezone ?? this.timezone,
        isDeleted: isDeleted,
        ageConfirmed: ageConfirmed,
        createdAt: createdAt,
        termsAcceptedAt: termsAcceptedAt,
        stats: stats ?? this.stats,
        notificationSettings: notificationSettings ?? this.notificationSettings,
      );
}

class UserStats {
  const UserStats({
    this.leaguesJoined = 0,
    this.leaguesWon = 0,
    this.exactScores = 0,
    this.correctResults = 0,
    this.totalFantasyPoints = 0,
    this.totalPredictionPoints = 0,
  });

  final int leaguesJoined;
  final int leaguesWon;
  final int exactScores;
  final int correctResults;
  final int totalFantasyPoints;
  final int totalPredictionPoints;

  factory UserStats.fromMap(Map<String, dynamic> m) => UserStats(
        leaguesJoined: m['leaguesJoined'] ?? 0,
        leaguesWon: m['leaguesWon'] ?? 0,
        exactScores: m['exactScores'] ?? 0,
        correctResults: m['correctResults'] ?? 0,
        totalFantasyPoints: m['totalFantasyPoints'] ?? 0,
        totalPredictionPoints: m['totalPredictionPoints'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'leaguesJoined': leaguesJoined,
        'leaguesWon': leaguesWon,
        'exactScores': exactScores,
        'correctResults': correctResults,
        'totalFantasyPoints': totalFantasyPoints,
        'totalPredictionPoints': totalPredictionPoints,
      };
}

class NotificationSettings {
  const NotificationSettings({
    this.matchStart = true,
    this.lineups = true,
    this.goals = true,
    this.rankChanges = true,
    this.leagueActivity = true,
  });

  final bool matchStart;
  final bool lineups;
  final bool goals;
  final bool rankChanges;
  final bool leagueActivity;

  factory NotificationSettings.fromMap(Map<String, dynamic> m) =>
      NotificationSettings(
        matchStart: m['matchStart'] ?? true,
        lineups: m['lineups'] ?? true,
        goals: m['goals'] ?? true,
        rankChanges: m['rankChanges'] ?? true,
        leagueActivity: m['leagueActivity'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'matchStart': matchStart,
        'lineups': lineups,
        'goals': goals,
        'rankChanges': rankChanges,
        'leagueActivity': leagueActivity,
      };
}
