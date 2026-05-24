import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, tradeProposal, tradeAccepted, tradeRejected, system }

class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.sentAt,
    this.tradeId,
  });

  final String messageId;
  final String threadId;
  final String senderId;
  final String senderName;
  final String text;
  final MessageType type;
  final String? tradeId;
  final DateTime sentAt;

  bool get isSystem => type != MessageType.text;

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      messageId: doc.id,
      threadId: d['threadId'] ?? '',
      senderId: d['senderId'] ?? '',
      senderName: d['senderName'] ?? '',
      text: d['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => MessageType.text,
      ),
      tradeId: d['tradeId'],
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'threadId': threadId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'type': type.name,
        'tradeId': tradeId,
        'sentAt': FieldValue.serverTimestamp(),
      };
}
