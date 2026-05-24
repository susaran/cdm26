import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message_model.dart';
import '../domain/chat_thread_model.dart';
import 'chat_provider.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen(
      {super.key, required this.leagueId, required this.threadId});
  final String leagueId;
  final String threadId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final userId = ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final displayName =
        ref.read(authStateProvider).valueOrNull?.displayName ?? 'User';
    setState(() => _sending = true);
    _ctrl.clear();
    await ref.read(chatRepositoryProvider).sendMessage(
          leagueId: widget.leagueId,
          threadId: widget.threadId,
          senderId: userId,
          senderName: displayName,
          text: text,
        );
    setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.leagueId, widget.threadId));

    // Mark read on open
    ref
        .read(chatRepositoryProvider)
        .markRead(widget.leagueId, widget.threadId, userId);

    return Scaffold(
      appBar: AppBar(
        title: _ThreadTitle(
            leagueId: widget.leagueId,
            threadId: widget.threadId,
            myUserId: userId),
        actions: [
          // If this is a trade thread, link to the trade
          Consumer(builder: (_, r, x) {
            final threads =
                r.watch(chatThreadsProvider(widget.leagueId, userId));
            final thread = threads.valueOrNull?.firstWhere(
              (t) => t.threadId == widget.threadId,
              orElse: () => ChatThread(
                threadId: '',
                leagueId: '',
                participantIds: [],
                participantNames: {},
                type: ThreadType.direct,
                createdAt: DateTime.now(),
              ),
            );
            if (thread?.type == ThreadType.trade) {
              return IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'View Trade',
                onPressed: () =>
                    context.go('/leagues/${widget.leagueId}/trades'),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, x) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isNotEmpty) _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final showDate = i == 0 ||
                        !_sameDay(
                            messages[i - 1].sentAt, msg.sentAt);
                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.sentAt),
                        msg.isSystem
                            ? _SystemBubble(message: msg)
                            : _MessageBubble(
                                message: msg,
                                isMe: msg.senderId == userId,
                              ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            ctrl: _ctrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Thread title ──────────────────────────────────────────────────────────────

class _ThreadTitle extends ConsumerWidget {
  const _ThreadTitle({
    required this.leagueId,
    required this.threadId,
    required this.myUserId,
  });
  final String leagueId;
  final String threadId;
  final String myUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider(leagueId, myUserId));
    final thread = threadsAsync.valueOrNull
        ?.where((t) => t.threadId == threadId)
        .firstOrNull;
    if (thread == null) return const Text('Chat');

    final name = thread.otherParticipantName(myUserId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(thread.type == ThreadType.trade ? 'Trade Chat' : name),
        if (thread.type == ThreadType.trade)
          Text('with $name',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Date divider ──────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ── System bubble ─────────────────────────────────────────────────────────────

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (message.type) {
      case MessageType.tradeProposal:
        color = AppColors.primary;
        icon = Icons.swap_horiz;
      case MessageType.tradeAccepted:
        color = AppColors.success;
        icon = Icons.check_circle;
      case MessageType.tradeRejected:
        color = AppColors.error;
        icon = Icons.cancel;
      default:
        color = AppColors.textSecondary;
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(message.text,
                style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});
  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style:
                    const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary),
                      ),
                    ),
                  Text(message.text,
                      style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(message.sentAt),
                    style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white60
                            : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar(
      {required this.ctrl, required this.sending, required this.onSend});
  final TextEditingController ctrl;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top:
                  BorderSide(color: AppColors.surfaceVariant, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: sending ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
