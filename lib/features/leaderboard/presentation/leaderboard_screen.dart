import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/scoring_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/leaderboard_entry_model.dart';
import 'leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, required this.leagueId});
  final String leagueId;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  // null = Overall standings; int = specific round
  int? _selectedRound;

  @override
  void initState() {
    super.initState();
    // Default to the current active round so the user immediately sees
    // where they stand this week, not the full-season total.
    _selectedRound = ScoringRounds.current.round;
  }

  List<LeaderboardEntry> _sortedForRound(
      List<LeaderboardEntry> entries, int? round) {
    if (round == null) return entries; // already sorted by totalPoints
    final sorted = [...entries]
      ..sort((a, b) => b.pointsForRound(round) - a.pointsForRound(round));
    // Re-assign rank for this round view
    return sorted.asMap().entries.map((e) {
      final prev = entries.firstWhere((x) => x.userId == e.value.userId);
      return LeaderboardEntry(
        userId: e.value.userId,
        displayName: e.value.displayName,
        photoUrl: e.value.photoUrl,
        rank: e.key + 1,
        previousRank: prev.rank,
        totalPoints: e.value.totalPoints,
        fantasyPoints: e.value.fantasyPoints,
        predictionPoints: e.value.predictionPoints,
        exactScores: e.value.exactScores,
        correctResults: e.value.correctResults,
        roundPoints: e.value.roundPoints,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(widget.leagueId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final activeRoundInfo = _selectedRound != null
        ? ScoringRounds.forRound(_selectedRound!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'team':
                  context.go('/leagues/${widget.leagueId}/team');
                case 'predictions':
                  context.go('/leagues/${widget.leagueId}/predictions');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'team', child: Text('My Team')),
              const PopupMenuItem(
                  value: 'predictions', child: Text('Predictions')),
            ],
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No members yet'));
          }
          final displayEntries = _sortedForRound(entries, _selectedRound);

          return Column(
            children: [
              // ── Active round banner ──────────────────────────────────────
              if (activeRoundInfo != null)
                _RoundBracketBanner(info: activeRoundInfo),

              // ── Round selector chips ─────────────────────────────────────
              _RoundSelector(
                selected: _selectedRound,
                onSelected: (r) => setState(() => _selectedRound = r),
              ),

              // ── Podium (top 3) ────────────────────────────────────────────
              if (displayEntries.length >= 3)
                _Podium(
                  entries: displayEntries.take(3).toList(),
                  round: _selectedRound,
                ),

              // ── Full rankings list ────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: displayEntries.length,
                  itemBuilder: (_, i) {
                    final entry = displayEntries[i];
                    return _LeaderboardRow(
                      entry: entry,
                      isMe: entry.userId == currentUser?.uid,
                      round: _selectedRound,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Round bracket banner ──────────────────────────────────────────────────────

class _RoundBracketBanner extends StatelessWidget {
  const _RoundBracketBanner({required this.info});
  final ScoringRoundInfo info;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        info.isActive ? AppColors.success : AppColors.textSecondary;
    final statusLabel = info.isActive
        ? 'LIVE NOW'
        : info.isUpcoming
            ? 'UPCOMING'
            : 'COMPLETED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Bracket icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  info.dateRange,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Round selector chips ──────────────────────────────────────────────────────

class _RoundSelector extends StatelessWidget {
  const _RoundSelector({required this.selected, required this.onSelected});
  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // Overall chip
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _RoundChip(
              label: 'Overall',
              isSelected: selected == null,
              onTap: () => onSelected(null),
            ),
          ),
          ...ScoringRounds.all.map((info) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _RoundChip(
                  label: info.shortLabel,
                  isSelected: selected == info.round,
                  isActive: info.isActive,
                  isCompleted: info.isCompleted,
                  onTap: () => onSelected(info.round),
                ),
              )),
        ],
      ),
    );
  }
}

class _RoundChip extends StatelessWidget {
  const _RoundChip({
    required this.label,
    required this.isSelected,
    this.isActive = false,
    this.isCompleted = false,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = isSelected
        ? AppColors.primary
        : isActive
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.surfaceVariant;
    final Color fg = isSelected
        ? Colors.white
        : isActive
            ? AppColors.success
            : isCompleted
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: isActive && !isSelected
              ? Border.all(color: AppColors.success.withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: fg),
        ),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.round});
  final List<LeaderboardEntry> entries;
  final int? round;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entries.length > 1)
            _PodiumItem(entry: entries[1], place: 2, height: 70, round: round),
          _PodiumItem(entry: entries[0], place: 1, height: 90, round: round),
          if (entries.length > 2)
            _PodiumItem(entry: entries[2], place: 3, height: 55, round: round),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem(
      {required this.entry,
      required this.place,
      required this.height,
      required this.round});
  final LeaderboardEntry entry;
  final int place;
  final double height;
  final int? round;

  @override
  Widget build(BuildContext context) {
    final pts =
        round != null ? entry.pointsForRound(round!) : entry.totalPoints;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: place == 1 ? 28 : 22,
          backgroundColor: AppColors.primary,
          backgroundImage:
              entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
          child: entry.photoUrl == null
              ? Text(entry.displayName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white))
              : null,
        ),
        const SizedBox(height: 4),
        Text(entry.displayName,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis),
        Text('$pts pts',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.secondary)),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: place == 1
                ? AppColors.secondary
                : place == 2
                    ? Colors.grey[400]
                    : Colors.brown[300],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Text('$place',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Leaderboard row ───────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow(
      {required this.entry, required this.isMe, required this.round});
  final LeaderboardEntry entry;
  final bool isMe;
  final int? round;

  @override
  Widget build(BuildContext context) {
    final rankChange = entry.rankChange;
    final displayPts =
        round != null ? entry.pointsForRound(round!) : entry.totalPoints;
    final roundInfo =
        round != null ? ScoringRounds.forRound(round!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withAlpha(60)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: isMe
            ? Border.all(color: AppColors.secondary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: entry.rank == 1 ? AppColors.secondary : null,
              ),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            backgroundImage: entry.photoUrl != null
                ? NetworkImage(entry.photoUrl!)
                : null,
            child: entry.photoUrl == null
                ? Text(entry.displayName[0].toUpperCase(),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 12))
                : null,
          ),
          const SizedBox(width: 12),
          // Name + sub-label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${entry.displayName} (You)' : entry.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                round != null
                    ? Text(
                        '${roundInfo?.label ?? ''} · Total: ${entry.totalPoints} pts',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      )
                    : Text(
                        'Fantasy: ${entry.fantasyPoints} · Predictions: ${entry.predictionPoints}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
              ],
            ),
          ),
          // Points + rank change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$displayPts',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'pts',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
              if (rankChange != 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rankChange > 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 11,
                      color: rankChange > 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    Text(
                      '${rankChange.abs()}',
                      style: TextStyle(
                          fontSize: 11,
                          color: rankChange > 0
                              ? AppColors.success
                              : AppColors.error),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
