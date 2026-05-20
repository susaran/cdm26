import 'package:cloud_firestore/cloud_firestore.dart';

enum LeagueStatus { setup, active, completed, cancelled, archived }
enum LeagueVisibility { private, public }
enum DraftMode { salaryCap, snakeDraft }
enum PoolMode { free, externalPool, realMoney }

class LeagueModel {
  const LeagueModel({
    required this.leagueId,
    required this.name,
    required this.ownerUserId,
    required this.tournamentId,
    required this.inviteCode,
    required this.createdAt,
    this.description,
    this.avatarUrl,
    this.adminUserIds = const [],
    this.status = LeagueStatus.setup,
    this.visibility = LeagueVisibility.private,
    this.maxMembers = 20,
    this.memberCount = 1,
    this.scoringTemplateId = 'default_wc_2026',
    this.draftMode = DraftMode.salaryCap,
    this.poolMode = PoolMode.free,
    this.prizeDescription,
    this.suggestedEntryAmountCents = 0,
    this.inviteLinkEnabled = true,
    this.settings = const LeagueSettings(),
  });

  final String leagueId;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerUserId;
  final List<String> adminUserIds;
  final String tournamentId;
  final LeagueStatus status;
  final LeagueVisibility visibility;
  final String inviteCode;
  final bool inviteLinkEnabled;
  final int maxMembers;
  final int memberCount;
  final String scoringTemplateId;
  final DraftMode draftMode;
  final PoolMode poolMode;
  final String? prizeDescription;
  final int suggestedEntryAmountCents;
  final DateTime createdAt;
  final LeagueSettings settings;

  factory LeagueModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LeagueModel(
      leagueId: doc.id,
      name: d['name'] ?? '',
      description: d['description'],
      avatarUrl: d['avatarUrl'],
      ownerUserId: d['ownerUserId'] ?? '',
      adminUserIds: List<String>.from(d['adminUserIds'] ?? []),
      tournamentId: d['tournamentId'] ?? 'wc_2026',
      status: LeagueStatus.values.firstWhere(
          (e) => e.name == d['status'], orElse: () => LeagueStatus.setup),
      visibility: LeagueVisibility.values.firstWhere(
          (e) => e.name == d['visibility'],
          orElse: () => LeagueVisibility.private),
      inviteCode: d['inviteCode'] ?? '',
      inviteLinkEnabled: d['inviteLinkEnabled'] ?? true,
      maxMembers: d['maxMembers'] ?? 20,
      memberCount: d['memberCount'] ?? 1,
      scoringTemplateId: d['scoringTemplateId'] ?? 'default_wc_2026',
      draftMode: DraftMode.values.firstWhere(
          (e) => e.name == d['draftMode'], orElse: () => DraftMode.salaryCap),
      poolMode: PoolMode.values.firstWhere(
          (e) => e.name == d['poolMode'], orElse: () => PoolMode.free),
      prizeDescription: d['prizeDescription'],
      suggestedEntryAmountCents: d['suggestedEntryAmountCents'] ?? 0,
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: LeagueSettings.fromMap(d['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'leagueId': leagueId,
        'name': name,
        'nameLower': name.toLowerCase(),
        'description': description,
        'avatarUrl': avatarUrl,
        'ownerUserId': ownerUserId,
        'adminUserIds': adminUserIds,
        'tournamentId': tournamentId,
        'status': status.name,
        'visibility': visibility.name,
        'inviteCode': inviteCode,
        'inviteLinkEnabled': inviteLinkEnabled,
        'maxMembers': maxMembers,
        'memberCount': memberCount,
        'scoringTemplateId': scoringTemplateId,
        'draftMode': draftMode.name,
        'poolMode': poolMode.name,
        'prizeDescription': prizeDescription,
        'suggestedEntryAmountCents': suggestedEntryAmountCents,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': settings.toMap(),
      };
}

class LeagueSettings {
  const LeagueSettings({
    this.chatEnabled = false,
    this.activityFeedEnabled = true,
    this.captainEnabled = true,
    this.transfersEnabled = true,
    this.allowLateJoin = false,
    this.showOtherUserPicksBeforeLock = false,
    this.showPredictionsBeforeLock = false,
  });

  final bool chatEnabled;
  final bool activityFeedEnabled;
  final bool captainEnabled;
  final bool transfersEnabled;
  final bool allowLateJoin;
  final bool showOtherUserPicksBeforeLock;
  final bool showPredictionsBeforeLock;

  factory LeagueSettings.fromMap(Map<String, dynamic> m) => LeagueSettings(
        chatEnabled: m['chatEnabled'] ?? false,
        activityFeedEnabled: m['activityFeedEnabled'] ?? true,
        captainEnabled: m['captainEnabled'] ?? true,
        transfersEnabled: m['transfersEnabled'] ?? true,
        allowLateJoin: m['allowLateJoin'] ?? false,
        showOtherUserPicksBeforeLock: m['showOtherUserPicksBeforeLock'] ?? false,
        showPredictionsBeforeLock: m['showPredictionsBeforeLock'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'chatEnabled': chatEnabled,
        'activityFeedEnabled': activityFeedEnabled,
        'captainEnabled': captainEnabled,
        'transfersEnabled': transfersEnabled,
        'allowLateJoin': allowLateJoin,
        'showOtherUserPicksBeforeLock': showOtherUserPicksBeforeLock,
        'showPredictionsBeforeLock': showPredictionsBeforeLock,
      };
}
