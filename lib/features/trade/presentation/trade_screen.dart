import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_message_model.dart';
import '../../league/presentation/league_provider.dart';
import '../../team_builder/presentation/team_provider.dart';
import '../data/trade_repository.dart';
import '../domain/trade_model.dart';
import 'trade_provider.dart';

class TradeScreen extends ConsumerStatefulWidget {
  const TradeScreen({super.key, required this.leagueId});
  final String leagueId;

  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen>
    with SingleTickerProviderStateMixin {
  late final _tabCtrl = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'My Trades'),
            Tab(text: 'Propose Trade'),
          ],
        ),
      ),
      body: !isTradeWindowOpen
          ? _TradeClosedBanner()
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _MyTradesTab(leagueId: widget.leagueId, userId: userId),
                _ProposeTradeTab(leagueId: widget.leagueId, userId: userId),
              ],
            ),
    );
  }
}

// ── Trade window closed ───────────────────────────────────────────────────────

class _TradeClosedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Trade window closed',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Trades are only available until the semifinals end (Jul 14).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Trades tab ─────────────────────────────────────────────────────────────

class _MyTradesTab extends ConsumerWidget {
  const _MyTradesTab({required this.leagueId, required this.userId});
  final String leagueId;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(leagueTradesProvider(leagueId, userId));

    return tradesAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('$e')),
      data: (trades) {
        if (trades.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz_outlined,
                    size: 64, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('No trades yet',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Propose a trade from the next tab.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final incoming =
            trades.where((t) => t.targetUserId == userId && t.isPending).toList();
        final outgoing =
            trades.where((t) => t.proposerId == userId && t.isPending).toList();
        final resolved =
            trades.where((t) => !t.isPending).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (incoming.isNotEmpty) ...[
              _SectionHeader('Incoming (${incoming.length})'),
              ...incoming.map((t) => _TradeTile(
                    trade: t,
                    userId: userId,
                    leagueId: leagueId,
                  )),
              const SizedBox(height: 8),
            ],
            if (outgoing.isNotEmpty) ...[
              _SectionHeader('Outgoing (${outgoing.length})'),
              ...outgoing.map((t) => _TradeTile(
                    trade: t,
                    userId: userId,
                    leagueId: leagueId,
                  )),
              const SizedBox(height: 8),
            ],
            if (resolved.isNotEmpty) ...[
              _SectionHeader('History'),
              ...resolved.map((t) => _TradeTile(
                    trade: t,
                    userId: userId,
                    leagueId: leagueId,
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
      );
}

class _TradeTile extends ConsumerWidget {
  const _TradeTile(
      {required this.trade, required this.userId, required this.leagueId});
  final TradeModel trade;
  final String userId;
  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncoming = trade.targetUserId == userId;
    final statusColor = switch (trade.status) {
      TradeStatus.pending => AppColors.primary,
      TradeStatus.accepted => AppColors.success,
      TradeStatus.rejected => AppColors.error,
      TradeStatus.cancelled => AppColors.textSecondary,
      TradeStatus.expired => AppColors.textSecondary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isIncoming
                        ? 'From ${trade.proposerDisplayName}'
                        : 'To ${trade.targetDisplayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trade.status.name.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PlayerList(
                    label: isIncoming ? 'They offer' : 'You offer',
                    players: trade.offeredPlayers,
                  ),
                ),
                const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
                Expanded(
                  child: _PlayerList(
                    label: isIncoming ? 'They want' : 'You want',
                    players: trade.requestedPlayers,
                  ),
                ),
              ],
            ),
            if (trade.message != null && trade.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('"${trade.message}"',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ],
            if (isIncoming && trade.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error),
                      onPressed: () async {
                        await ref
                            .read(tradeRepositoryProvider)
                            .rejectTrade(leagueId, trade.tradeId);
                        final threadId = 'trade_${trade.tradeId}';
                        await ref
                            .read(chatRepositoryProvider)
                            .postSystemMessage(
                              leagueId: leagueId,
                              threadId: threadId,
                              senderId: userId,
                              senderName: trade.targetDisplayName,
                              text:
                                  '${trade.targetDisplayName} rejected the trade. ❌',
                              type: MessageType.tradeRejected,
                              tradeId: trade.tradeId,
                            )
                            .catchError((_) {});
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success),
                      onPressed: () async {
                        await ref
                            .read(tradeRepositoryProvider)
                            .acceptTrade(leagueId, trade);
                        // Post system message to trade thread
                        final threadId = 'trade_${trade.tradeId}';
                        await ref
                            .read(chatRepositoryProvider)
                            .postSystemMessage(
                              leagueId: leagueId,
                              threadId: threadId,
                              senderId: userId,
                              senderName: trade.targetDisplayName,
                              text:
                                  '${trade.targetDisplayName} accepted the trade! ✅',
                              type: MessageType.tradeAccepted,
                              tradeId: trade.tradeId,
                            )
                            .catchError((_) {});
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (!isIncoming && trade.isPending)
              TextButton(
                onPressed: () => ref
                    .read(tradeRepositoryProvider)
                    .cancelTrade(leagueId, trade.tradeId),
                child: const Text('Cancel Trade'),
              ),
            // Chat button — always visible on pending trades
            if (trade.isPending) ...[
              const Divider(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Chat about this trade'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36)),
                onPressed: () => _openTradeChat(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openTradeChat(BuildContext context, WidgetRef ref) async {
    final proposerName = trade.proposerDisplayName;
    final targetName = trade.targetDisplayName;
    final summary = _tradeSummary();
    final threadId = await ref
        .read(chatRepositoryProvider)
        .getOrCreateTradeThread(
          leagueId: leagueId,
          tradeId: trade.tradeId,
          proposerId: trade.proposerId,
          proposerName: proposerName,
          targetId: trade.targetUserId,
          targetName: targetName,
          systemMessage: summary,
        );
    if (!context.mounted) return;
    context.go('/leagues/$leagueId/inbox/$threadId');
  }

  String _tradeSummary() {
    final offered = trade.offeredPlayers.map((p) => p.displayName).join(', ');
    final wanted = trade.requestedPlayers.map((p) => p.displayName).join(', ');
    return '${trade.proposerDisplayName} offers $offered for $wanted';
  }
}

class _PlayerList extends StatelessWidget {
  const _PlayerList({required this.label, required this.players});
  final String label;
  final List<TradedPlayer> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        ...players.map((p) => Text(
              '${p.displayName} (${p.position})',
              style: const TextStyle(fontSize: 12),
            )),
      ],
    );
  }
}

// ── Propose Trade tab ─────────────────────────────────────────────────────────

class _ProposeTradeTab extends ConsumerStatefulWidget {
  const _ProposeTradeTab({required this.leagueId, required this.userId});
  final String leagueId;
  final String userId;

  @override
  ConsumerState<_ProposeTradeTab> createState() => _ProposeTradeTabState();
}

class _ProposeTradeTabState extends ConsumerState<_ProposeTradeTab> {
  String? _targetUserId;
  String _targetDisplayName = '';
  final Set<String> _mySelectedIds = {};
  final Set<String> _theirSelectedIds = {};
  final _messageCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myTeamAsync =
        ref.watch(watchTeamProvider(widget.leagueId, widget.userId));
    final membersAsync = ref.watch(leagueMembersProvider(widget.leagueId));

    return myTeamAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('$e')),
      data: (myTeam) {
        if (myTeam == null || myTeam.players.isEmpty) {
          return const Center(
            child: Text('You need a squad before proposing trades.',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Step 1: pick target
            const Text('1. Select trade partner',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            membersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Text('$e'),
              data: (members) {
                final others = members
                    .where((m) => m.userId != widget.userId)
                    .toList();
                return DropdownButtonFormField<String>(
                  value: _targetUserId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    hintText: 'Choose a league member',
                    isDense: true,
                  ),
                  items: others
                      .map((m) => DropdownMenuItem(
                            value: m.userId,
                            child: Text(m.displayName),
                          ))
                      .toList(),
                  onChanged: (v) {
                    final m =
                        others.firstWhere((x) => x.userId == v);
                    setState(() {
                      _targetUserId = v;
                      _targetDisplayName = m.displayName;
                      _theirSelectedIds.clear();
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Step 2: my players to offer
            const Text('2. Players you offer',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...myTeam.players.map((p) => CheckboxListTile(
                  dense: true,
                  title: Text('${p.displayName} (${p.position})'),
                  subtitle: Text(p.teamName,
                      style: const TextStyle(fontSize: 11)),
                  value: _mySelectedIds.contains(p.playerId),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _mySelectedIds.add(p.playerId);
                      } else {
                        _mySelectedIds.remove(p.playerId);
                      }
                    });
                  },
                )),
            const SizedBox(height: 20),

            // Step 3: their players you want
            if (_targetUserId != null) ...[
              const Text('3. Players you want',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final theirTeamAsync = ref.watch(
                      watchTeamProvider(widget.leagueId, _targetUserId!));
                  return theirTeamAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, _) => Text('$e'),
                    data: (theirTeam) {
                      if (theirTeam == null || theirTeam.players.isEmpty) {
                        return const Text('This player has no squad yet.',
                            style: TextStyle(
                                color: AppColors.textSecondary));
                      }
                      return Column(
                        children: theirTeam.players
                            .map((p) => CheckboxListTile(
                                  dense: true,
                                  title: Text(
                                      '${p.displayName} (${p.position})'),
                                  subtitle: Text(p.teamName,
                                      style:
                                          const TextStyle(fontSize: 11)),
                                  value:
                                      _theirSelectedIds.contains(p.playerId),
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _theirSelectedIds.add(p.playerId);
                                      } else {
                                        _theirSelectedIds
                                            .remove(p.playerId);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Optional message
            TextField(
              controller: _messageCtrl,
              decoration: InputDecoration(
                hintText: 'Add a message (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  _canSubmit && !_submitting ? () => _submit(context) : null,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              child: _submitting
                  ? const CircularProgressIndicator()
                  : const Text('Send Trade Proposal'),
            ),
          ],
        );
      },
    );
  }

  bool get _canSubmit =>
      _targetUserId != null &&
      _mySelectedIds.isNotEmpty &&
      _theirSelectedIds.isNotEmpty;

  Future<void> _submit(BuildContext context) async {
    setState(() => _submitting = true);
    try {
      final myTeam = ref
          .read(watchTeamProvider(widget.leagueId, widget.userId))
          .valueOrNull;
      final theirTeam = ref
          .read(watchTeamProvider(widget.leagueId, _targetUserId!))
          .valueOrNull;

      if (myTeam == null || theirTeam == null) return;

      final offered = myTeam.players
          .where((p) => _mySelectedIds.contains(p.playerId))
          .map((p) => TradedPlayer(
                playerId: p.playerId,
                displayName: p.displayName,
                position: p.position,
                teamName: p.teamName,
              ))
          .toList();

      final requested = theirTeam.players
          .where((p) => _theirSelectedIds.contains(p.playerId))
          .map((p) => TradedPlayer(
                playerId: p.playerId,
                displayName: p.displayName,
                position: p.position,
                teamName: p.teamName,
              ))
          .toList();

      final auth = ref.read(authStateProvider).valueOrNull;
      await ref.read(tradeRepositoryProvider).proposeTrade(
            leagueId: widget.leagueId,
            proposerId: widget.userId,
            proposerDisplayName: auth?.displayName ?? 'You',
            targetUserId: _targetUserId!,
            targetDisplayName: _targetDisplayName,
            offeredPlayers: offered,
            requestedPlayers: requested,
            message: _messageCtrl.text.trim().isEmpty
                ? null
                : _messageCtrl.text.trim(),
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade proposal sent!')),
        );
        setState(() {
          _targetUserId = null;
          _mySelectedIds.clear();
          _theirSelectedIds.clear();
          _messageCtrl.clear();
        });
      }

      // The Cloud Function will handle the FCM notification; we just
      // ensure the trade thread exists so the chat button works immediately.
      // (tradeId is not returned from proposeTrade, so thread creation
      //  is deferred to first time user taps "Chat about this trade")
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
