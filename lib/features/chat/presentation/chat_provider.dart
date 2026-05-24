import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../data/chat_repository.dart';
import '../domain/chat_message_model.dart';
import '../domain/chat_thread_model.dart';

part 'chat_provider.g.dart';

@riverpod
Stream<List<ChatThread>> chatThreads(Ref ref, String leagueId, String userId) {
  return ref
      .watch(chatRepositoryProvider)
      .watchThreads(leagueId, userId);
}

@riverpod
Stream<List<ChatMessage>> chatMessages(
    Ref ref, String leagueId, String threadId) {
  return ref
      .watch(chatRepositoryProvider)
      .watchMessages(leagueId, threadId);
}

@riverpod
Stream<int> leagueUnreadCount(Ref ref, String leagueId, String userId) {
  return ref
      .watch(chatRepositoryProvider)
      .watchTotalUnread(leagueId, userId);
}
