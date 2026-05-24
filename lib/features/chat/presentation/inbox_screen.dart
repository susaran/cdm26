import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../league/data/league_repository.dart';
import '../../league/domain/league_member_model.dart';
import '../../league/presentation/league_provider.dart';
import '../data/chat_repository.dart';
import '../domain/chat_thread_model.dart';
import 'chat_provider.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key, required this.leagueId});
  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final threadsAsync = ref.watch(chatThreadsProvider(leagueId, userId));
    final leagueName =
        ref.watch(leagueByIdProvider(leagueId)).valueOrNull?.name ?? 'League';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Messages'),
            Text(leagueName,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Message a teammate',
            onPressed: () => _showNewConversation(context, ref, userId),
          ),
        ],
      ),
      body: threadsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, x) => Center(child: Text('Error: $e')),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No conversations yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Propose a trade or message a teammate\nto start chatting.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('New Conversation'),
                    onPressed: () =>
                        _showNewConversation(context, ref, userId),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: threads.length,
            separatorBuilder: (_, i) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) => _ThreadTile(
              thread: threads[i],
              myUserId: userId,
              onTap: () {
                ref.read(chatRepositoryProvider).markRead(
                    leagueId, threads[i].threadId, userId);
                context.go(
                    '/leagues/$leagueId/inbox/${threads[i].threadId}');
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNewConversation(
      BuildContext context, WidgetRef ref, String myUserId) async {
    final members = await ref
        .read(leagueRepositoryProvider)
        .watchLeagueMembers(leagueId)
        .first;
    final others =
        members.where((m) => m.userId != myUserId).toList();
    if (!context.mounted) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _MemberPicker(members: others),
    );
    if (picked == null || !context.mounted) return;

    final me = members.firstWhere((m) => m.userId == myUserId,
        orElse: () => members.first);
    final other =
        members.firstWhere((m) => m.userId == picked);

    final threadId = await ref
        .read(chatRepositoryProvider)
        .getOrCreateDirectThread(
          leagueId: leagueId,
          uid1: myUserId,
          uid2: picked,
          name1: me.displayName,
          name2: other.displayName,
        );

    if (!context.mounted) return;
    context.go('/leagues/$leagueId/inbox/$threadId');
  }
}

// ── Thread tile ───────────────────────────────────────────────────────────────

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.myUserId,
    required this.onTap,
  });
  final ChatThread thread;
  final String myUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = thread.unreadFor(myUserId);
    final otherName = thread.otherParticipantName(myUserId);
    final isTradeThread = thread.type == ThreadType.trade;

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isTradeThread
                ? AppColors.primary
                : AppColors.surfaceVariant,
            child: Icon(
              isTradeThread ? Icons.swap_horiz : Icons.person,
              color: Colors.white,
            ),
          ),
          if (unread > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
                constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isTradeThread ? 'Trade · $otherName' : otherName,
              style: TextStyle(
                  fontWeight:
                      unread > 0 ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          if (thread.lastMessageAt != null)
            Text(
              timeago.format(thread.lastMessageAt!),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
        ],
      ),
      subtitle: thread.lastMessage != null
          ? Text(
              thread.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: unread > 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      unread > 0 ? FontWeight.w500 : null),
            )
          : null,
    );
  }
}

// ── Member picker ─────────────────────────────────────────────────────────────

class _MemberPicker extends StatelessWidget {
  const _MemberPicker({required this.members});
  final List<LeagueMemberModel> members;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Choose a teammate',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          ...members.map((m) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    m.displayName.isNotEmpty
                        ? m.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(m.displayName),
                subtitle: m.teamName != null
                    ? Text(m.teamName!,
                        style: const TextStyle(
                            color: AppColors.textSecondary))
                    : null,
                onTap: () => Navigator.pop(context, m.userId),
              )),
        ],
      ),
    );
  }
}
