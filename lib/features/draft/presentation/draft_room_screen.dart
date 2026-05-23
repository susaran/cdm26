import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../matches/domain/player_model.dart';
import '../../team_builder/domain/team_model.dart';
import '../data/draft_repository.dart';
import '../domain/draft_model.dart';
import 'draft_provider.dart';

class DraftRoomScreen extends ConsumerStatefulWidget {
  const DraftRoomScreen({super.key, required this.leagueId});
  final String leagueId;

  @override
  ConsumerState<DraftRoomScreen> createState() => _DraftRoomScreenState();
}

class _DraftRoomScreenState extends ConsumerState<DraftRoomScreen> {
  String _searchQuery = '';
  String _posFilter = 'ALL';
  bool _picking = false;
  Timer? _tickTimer;
  int _secondsLeft = 600;

  // Stored each build so the timer callback can access current state.
  DraftModel? _currentDraft;
  String _currentUserId = '';
  List<PlayerModel> _availablePlayers = [];
  List<DraftPick> _currentPicksList = [];
  bool _isMyTurn = false;

  static const _positions = ['ALL', 'GK', 'DEF', 'MID', 'FWD', 'NAT'];

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startTimer(DraftModel draft) {
    _tickTimer?.cancel();
    if (draft.currentPickStartedAt == null) return;
    final elapsed = DateTime.now()
        .difference(draft.currentPickStartedAt!)
        .inSeconds;
    setState(() => _secondsLeft = (draft.pickDurationSeconds - elapsed).clamp(0, draft.pickDurationSeconds));
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = (_secondsLeft - 1).clamp(0, 9999);
      setState(() => _secondsLeft = next);
      if (next == 0 && _isMyTurn && !_picking) {
        _autoPick();
      }
    });
  }

  Map<String, int> _positionCounts(String userId) {
    final counts = <String, int>{'GK': 0, 'DEF': 0, 'MID': 0, 'FWD': 0, 'NAT': 0};
    for (final p in _currentPicksList.where((p) => p.userId == userId)) {
      counts[p.position] = (counts[p.position] ?? 0) + 1;
    }
    return counts;
  }

  bool _isPositionFull(Map<String, int> counts, String position) =>
      switch (position) {
        'GK' => (counts['GK'] ?? 0) >= kRequiredGK,
        'DEF' => (counts['DEF'] ?? 0) >= kRequiredDEF,
        'MID' => (counts['MID'] ?? 0) >= kRequiredMID,
        'FWD' => (counts['FWD'] ?? 0) >= kRequiredFWD,
        'NAT' => (counts['NAT'] ?? 0) >= 1,
        _ => false,
      };

  Future<void> _autoPick() async {
    if (_picking || _currentDraft == null || _availablePlayers.isEmpty || !mounted) return;
    final counts = _positionCounts(_currentUserId);
    // Pick the highest-priced player in a position that still needs filling
    final player = _availablePlayers.firstWhere(
      (p) => !_isPositionFull(counts, p.positionLabel),
      orElse: () => _availablePlayers.first,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏱ Time\'s up! Auto-drafting ${player.displayName}'),
        duration: const Duration(seconds: 3),
      ),
    );
    await _pick(context, _currentDraft!, _currentUserId, player);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final draftAsync = ref.watch(draftProvider(widget.leagueId));
    final picksAsync = ref.watch(draftPicksProvider(widget.leagueId));

    return draftAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (draft) {
        if (draft == null) {
          return const Scaffold(body: Center(child: Text('Draft not found.')));
        }

        if (draft.isDone && draft.status == DraftStatus.active) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await ref.read(draftRepositoryProvider).completeDraft(widget.leagueId);
          });
        }

        // Restart timer when pick index changes
        WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer(draft));

        final isMyTurn = draft.currentPickUserId == userId && !draft.isDone;
        _currentDraft = draft;
        _currentUserId = userId;
        _isMyTurn = isMyTurn;

        final allPicks = picksAsync.valueOrNull ?? [];
        _currentPicksList = allPicks;
        final myCounts = _positionCounts(userId);

        final availAsync = ref.watch(availablePlayersProvider(
            widget.leagueId, draft.draftedPlayerIds));

        return Scaffold(
          appBar: AppBar(
            title: Text('Draft · Round ${draft.currentRound}'),
            actions: [
              if (!draft.isDone)
                _TimerChip(secondsLeft: _secondsLeft, isMyTurn: isMyTurn),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // ── Status bar ──────────────────────────────────────────────
              _StatusBar(draft: draft, isMyTurn: isMyTurn),

              // ── My squad slot tracker ───────────────────────────────────
              _MySquadStatus(counts: myCounts),

              // ── Search + filter ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search players...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _positions.map((pos) {
                          final selected = _posFilter == pos;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(pos),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _posFilter = pos),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Player list ─────────────────────────────────────────────
              Expanded(
                child: availAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (players) {
                    _availablePlayers = players;
                    final filtered = players.where((p) {
                      final matchPos = _posFilter == 'ALL' ||
                          p.positionLabel == _posFilter;
                      final matchSearch = _searchQuery.isEmpty ||
                          p.displayName
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          p.teamName
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase());
                      return matchPos && matchSearch;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                          child: Text('No players match your filter.'));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _PlayerPickTile(
                        player: filtered[i],
                        isMyTurn: isMyTurn,
                        picking: _picking,
                        isPositionFull: _isPositionFull(myCounts, filtered[i].positionLabel),
                        onPick: () => _pick(context, draft, userId, filtered[i]),
                      ),
                    );
                  },
                ),
              ),

              // ── Recent picks ticker ──────────────────────────────────────
              picksAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (picks) => picks.isEmpty
                    ? const SizedBox.shrink()
                    : _RecentPicks(picks: picks.reversed.take(5).toList()),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, DraftModel draft, String userId,
      PlayerModel player) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      await ref.read(draftRepositoryProvider).makePick(
            widget.leagueId,
            userId,
            player,
            draft.currentPickIndex,
          );
      // Check if draft is complete
      if (draft.currentPickIndex + 1 >= draft.totalPicks) {
        await ref
            .read(draftRepositoryProvider)
            .completeDraft(widget.leagueId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft complete! 🎉')),
          );
          context.go('/leagues/${widget.leagueId}/leaderboard');
        }
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }
}

// ── Status bar ───────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.draft, required this.isMyTurn});
  final DraftModel draft;
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    final bg = isMyTurn ? AppColors.success : AppColors.primary;
    final text = draft.isDone
        ? 'Draft complete!'
        : isMyTurn
            ? 'Your pick! Choose a player.'
            : 'Waiting for pick ${draft.pickInRound} of round ${draft.currentRound}...';

    return Container(
      width: double.infinity,
      color: bg.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Timer chip ────────────────────────────────────────────────────────────────

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.secondsLeft, required this.isMyTurn});
  final int secondsLeft;
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft < 60 && isMyTurn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: urgent
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
        style: TextStyle(
          color: urgent ? AppColors.error : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Player tile ───────────────────────────────────────────────────────────────

class _PlayerPickTile extends StatelessWidget {
  const _PlayerPickTile({
    required this.player,
    required this.isMyTurn,
    required this.picking,
    required this.isPositionFull,
    required this.onPick,
  });
  final PlayerModel player;
  final bool isMyTurn;
  final bool picking;
  final bool isPositionFull;
  final VoidCallback onPick;

  bool get _isDST => player.positionLabel == 'NAT';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _posColor(player.positionLabel),
        child: _isDST
            ? const Icon(Icons.shield, color: Colors.white, size: 18)
            : Text(player.positionLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
      ),
      title: Text(player.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        _isDST ? 'National Team · DST scoring' : player.teamName,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: isMyTurn && isPositionFull
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('FULL',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
            )
          : isMyTurn
              ? ElevatedButton(
                  onPressed: picking ? null : onPick,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: picking
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Pick'),
                )
              : Text('£${player.fantasyPrice.toStringAsFixed(0)}m',
                  style: const TextStyle(color: AppColors.textSecondary)),
    );
  }

  Color _posColor(String pos) => switch (pos) {
        'GK' => const Color(0xFF1E88E5),
        'DEF' => const Color(0xFF43A047),
        'MID' => const Color(0xFFFB8C00),
        'FWD' => const Color(0xFFE53935),
        'NAT' => const Color(0xFF7B1FA2),
        _ => AppColors.primary,
      };
}

// ── My squad slot tracker ─────────────────────────────────────────────────────

class _MySquadStatus extends StatelessWidget {
  const _MySquadStatus({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SlotChip(pos: 'GK', filled: counts['GK'] ?? 0, max: kRequiredGK),
          _SlotChip(pos: 'DEF', filled: counts['DEF'] ?? 0, max: kRequiredDEF),
          _SlotChip(pos: 'MID', filled: counts['MID'] ?? 0, max: kRequiredMID),
          _SlotChip(pos: 'FWD', filled: counts['FWD'] ?? 0, max: kRequiredFWD),
          _SlotChip(pos: 'NAT', filled: counts['NAT'] ?? 0, max: 1),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.pos, required this.filled, required this.max});
  final String pos;
  final int filled;
  final int max;

  static Color _posColor(String pos) => switch (pos) {
        'GK' => const Color(0xFF1E88E5),
        'DEF' => const Color(0xFF43A047),
        'MID' => const Color(0xFFFB8C00),
        'FWD' => const Color(0xFFE53935),
        'NAT' => const Color(0xFF7B1FA2),
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final isFull = filled >= max;
    final color = _posColor(pos);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(pos,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            max,
            (i) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? color : color.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$filled/$max',
          style: TextStyle(
              fontSize: 10,
              color: isFull ? color : AppColors.textSecondary,
              fontWeight: isFull ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}

// ── Recent picks ticker ───────────────────────────────────────────────────────

class _RecentPicks extends StatelessWidget {
  const _RecentPicks({required this.picks});
  final List<DraftPick> picks;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent picks',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...picks.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Text('#${p.pickNumber} ',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    Text(p.playerName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const Text(' · ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text(p.position,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
