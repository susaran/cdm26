import 'package:cloud_firestore/cloud_firestore.dart';

enum ThreadType { trade, direct }

class ChatThread {
  const ChatThread({
    required this.threadId,
    required this.leagueId,
    required this.participantIds,
    required this.participantNames,
    required this.type,
    required this.createdAt,
    this.tradeId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCounts = const {},
  });

  final String threadId;
  final String leagueId;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final ThreadType type;
  final String? tradeId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;

  int unreadFor(String userId) => unreadCounts[userId] ?? 0;

  String otherParticipantName(String myUserId) {
    final otherId =
        participantIds.firstWhere((id) => id != myUserId, orElse: () => '');
    return participantNames[otherId] ?? 'Unknown';
  }

  String otherParticipantId(String myUserId) =>
      participantIds.firstWhere((id) => id != myUserId, orElse: () => '');

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final raw = d['unreadCounts'] as Map<String, dynamic>? ?? {};
    return ChatThread(
      threadId: doc.id,
      leagueId: d['leagueId'] ?? '',
      participantIds: List<String>.from(d['participantIds'] ?? []),
      participantNames:
          Map<String, String>.from(d['participantNames'] ?? {}),
      type: d['type'] == 'trade' ? ThreadType.trade : ThreadType.direct,
      tradeId: d['tradeId'],
      lastMessage: d['lastMessage'],
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCounts:
          raw.map((k, v) => MapEntry(k, (v as num).toInt())),
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'leagueId': leagueId,
        'participantIds': participantIds,
        'participantNames': participantNames,
        'type': type.name,
        'tradeId': tradeId,
        'lastMessage': lastMessage,
        'lastMessageAt':
            lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'unreadCounts': unreadCounts,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
