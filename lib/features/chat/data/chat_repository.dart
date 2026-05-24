import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../domain/chat_message_model.dart';
import '../domain/chat_thread_model.dart';

part 'chat_repository.g.dart';

@riverpod
ChatRepository chatRepository(Ref ref) => ChatRepository();

class ChatRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference _chats(String leagueId) =>
      _db.collection('leagues').doc(leagueId).collection('chats');

  CollectionReference _messages(String leagueId, String threadId) =>
      _chats(leagueId).doc(threadId).collection('messages');

  // ── Threads ───────────────────────────────────────────────────────────────

  Stream<List<ChatThread>> watchThreads(String leagueId, String userId) {
    return _chats(leagueId)
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatThread.fromFirestore(d)).toList());
  }

  Stream<int> watchTotalUnread(String leagueId, String userId) {
    return watchThreads(leagueId, userId).map(
      (threads) => threads.fold<int>(0, (acc, t) => acc + t.unreadFor(userId)),
    );
  }

  // Returns existing thread id or creates a new one.
  // Uses a deterministic id so concurrent calls are safe.
  Future<String> getOrCreateDirectThread({
    required String leagueId,
    required String uid1,
    required String uid2,
    required String name1,
    required String name2,
  }) async {
    final ids = [uid1, uid2]..sort();
    final threadId = 'direct_${ids[0]}_${ids[1]}';
    final ref = _chats(leagueId).doc(threadId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(ChatThread(
        threadId: threadId,
        leagueId: leagueId,
        participantIds: ids,
        participantNames: {uid1: name1, uid2: name2},
        type: ThreadType.direct,
        createdAt: DateTime.now(),
      ).toMap());
    }
    return threadId;
  }

  Future<String> getOrCreateTradeThread({
    required String leagueId,
    required String tradeId,
    required String proposerId,
    required String proposerName,
    required String targetId,
    required String targetName,
    required String systemMessage,
  }) async {
    final threadId = 'trade_$tradeId';
    final ref = _chats(leagueId).doc(threadId);
    final snap = await ref.get();
    if (!snap.exists) {
      final ids = [proposerId, targetId]..sort();
      final thread = ChatThread(
        threadId: threadId,
        leagueId: leagueId,
        participantIds: ids,
        participantNames: {
          proposerId: proposerName,
          targetId: targetName,
        },
        type: ThreadType.trade,
        tradeId: tradeId,
        lastMessage: systemMessage,
        lastMessageAt: DateTime.now(),
        unreadCounts: {targetId: 1},
        createdAt: DateTime.now(),
      );
      final batch = _db.batch();
      batch.set(ref, thread.toMap());
      // Post system message as first entry
      final msgRef = _messages(leagueId, threadId).doc();
      batch.set(
          msgRef,
          ChatMessage(
            messageId: msgRef.id,
            threadId: threadId,
            senderId: proposerId,
            senderName: proposerName,
            text: systemMessage,
            type: MessageType.tradeProposal,
            tradeId: tradeId,
            sentAt: DateTime.now(),
          ).toMap());
      await batch.commit();
    }
    return threadId;
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Stream<List<ChatMessage>> watchMessages(String leagueId, String threadId) {
    return _messages(leagueId, threadId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromFirestore(d)).toList());
  }

  Future<void> sendMessage({
    required String leagueId,
    required String threadId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final msg = ChatMessage(
      messageId: '',
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      type: MessageType.text,
      sentAt: DateTime.now(),
    );
    final threadRef = _chats(leagueId).doc(threadId);
    final snap = await threadRef.get();
    final thread = ChatThread.fromFirestore(snap);
    // Increment unread for all OTHER participants
    final Map<String, dynamic> unreadUpdate = {};
    for (final uid in thread.participantIds) {
      if (uid != senderId) {
        unreadUpdate['unreadCounts.$uid'] = FieldValue.increment(1);
      }
    }
    final batch = _db.batch();
    batch.set(_messages(leagueId, threadId).doc(), msg.toMap());
    batch.update(threadRef, {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      ...unreadUpdate,
    });
    await batch.commit();
  }

  Future<void> markRead(
      String leagueId, String threadId, String userId) async {
    await _chats(leagueId).doc(threadId).update({
      'unreadCounts.$userId': 0,
    });
  }

  Future<void> postSystemMessage({
    required String leagueId,
    required String threadId,
    required String senderId,
    required String senderName,
    required String text,
    required MessageType type,
    String? tradeId,
  }) async {
    final msg = ChatMessage(
      messageId: '',
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      type: type,
      tradeId: tradeId,
      sentAt: DateTime.now(),
    );
    final threadRef = _chats(leagueId).doc(threadId);
    final batch = _db.batch();
    batch.set(_messages(leagueId, threadId).doc(), msg.toMap());
    batch.update(threadRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
