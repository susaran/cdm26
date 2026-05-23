import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/scoring_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/leaderboard_entry_model.dart';
import 'leaderboard_provider.dart';

// ── Badge types ───────────────────────────────────────────────────────────────

enum _Badge { leader, roundLeader, biggestMover, predictionAce }

extension _BadgeExt on _Badge {
  String get emoji => switch (this) {
        _Badge.leader => '👑',
        _Badge.roundLeader => '🔥',
        _Badge.biggestMover => '📈',
        _Badge.predictionAce => '🎯',
      };
  String get label => switch (this) {
        _Badge.leader => 'Top Manager',
        _Badge.roundLeader => 'Round Leader',
        _Badge.biggestMover => 'Biggest Mover',
        _Badge.predictionAce => 'Prediction Ace',
      };
  Color get color => switch (this) {
        _Badge.leader => AppColors.secondary,
        _Badge.roundLeader => AppColors.success,
        _Badge.biggestMover => const Color(0xFF42A5F5),
        _Badge.predictionAce => const Color(0xFFCE93D8),
      };
}

// ── Screen ────────────────────────────────────────────────────────────────────

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, required this.leagueId});
  final String leagueId;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int? _selectedRound;

  @override
  void initState() {
    super.initState();
    _selectedRound = ScoringRounds.current.round;
  }

  List<LeaderboardEntry> _sortedForRound(
      List<LeaderboardEntry> entries, int? round) {
    if (round == null) return entries;
    final sorted = [...entries]
      ..sort((a, b) => b.pointsForRound(round) - a.pointsForRound(round));
    return sorted.asMap().entries.map((e) {
      final prev = entries.firstWhere((x) => x.userId == e.value.userId);
      return LeaderboardEntry(
        userId: e.value.userId,
        displayName: e.value.displayName,
        photoUrl: e.value.photoUrl,
        teamName: e.value.teamName,
        teamBadgeUrl: e.value.teamBadgeUrl,
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

  Map<String, Set<_Badge>> _computeBadges(
      List<LeaderboardEntry> all, List<LeaderboardEntry> roundView, int? round) {
    final badges = <String, Set<_Badge>>{};
    void add(String uid, _Badge b) =>
        (badges[uid] ??= {}).add(b);

    if (all.isNotEmpty) add(all.first.userId, _Badge.leader);

    if (round != null && roundView.isNotEmpty &&
        roundView.first.userId != all.first.userId) {
      add(roundView.first.userId, _Badge.roundLeader);
    }

    final mover = all
        .where((e) => e.rankChange > 0)
        .fold<LeaderboardEntry?>(null, (best, e) =>
            best == null || e.rankChange > best.rankChange ? e : best);
    if (mover != null) add(mover.userId, _Badge.biggestMover);

    final ace = all.fold<LeaderboardEntry?>(null, (best, e) =>
        best == null || e.exactScores > best.exactScores ? e : best);
    if (ace != null && ace.exactScores > 0) {
      add(ace.userId, _Badge.predictionAce);
    }

    return badges;
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
          final badges =
              _computeBadges(entries, displayEntries, _selectedRound);

          return Column(
            children: [
              if (activeRoundInfo != null)
                _RoundBracketBanner(info: activeRoundInfo),
              _RoundSelector(
                selected: _selectedRound,
                onSelected: (r) => setState(() => _selectedRound = r),
              ),
              if (badges.isNotEmpty) _AchievementStrip(badges: badges),
              if (displayEntries.length >= 3)
                _Podium(
                  entries: displayEntries.take(3).toList(),
                  round: _selectedRound,
                  badges: badges,
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: displayEntries.length,
                  itemBuilder: (_, i) {
                    final entry = displayEntries[i];
                    return _LeaderboardRow(
                      entry: entry,
                      isMe: entry.userId == currentUser?.uid,
                      round: _selectedRound,
                      badges: badges[entry.userId] ?? {},
                      onTap: () => _showManagerCard(
                          context, entry, badges[entry.userId] ?? {}),
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

  void _showManagerCard(
      BuildContext context, LeaderboardEntry entry, Set<_Badge> badges) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManagerCard(entry: entry, badges: badges),
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
            bottom: BorderSide(color: AppColors.surfaceVariant, width: 1)),
      ),
      child: Row(
        children: [
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
                Text(info.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(info.dateRange,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ── Round selector ────────────────────────────────────────────────────────────

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
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
      ),
    );
  }
}

// ── Achievement strip ─────────────────────────────────────────────────────────

class _AchievementStrip extends StatelessWidget {
  const _AchievementStrip({required this.badges});
  final Map<String, Set<_Badge>> badges;

  @override
  Widget build(BuildContext context) {
    // Collect all earned badges and find who holds each
    final earned = <(_Badge, String)>[];
    for (final entry in badges.entries) {
      for (final b in entry.value) {
        earned.add((b, entry.key));
      }
    }
    if (earned.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: earned
            .map((t) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.$1.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: t.$1.color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.$1.emoji,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(t.$1.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: t.$1.color)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium(
      {required this.entries,
      required this.round,
      required this.badges});
  final List<LeaderboardEntry> entries;
  final int? round;
  final Map<String, Set<_Badge>> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            AppColors.background.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entries.length > 1)
            _PodiumItem(
                entry: entries[1],
                place: 2,
                height: 72,
                round: round,
                badges: badges[entries[1].userId] ?? {}),
          _PodiumItem(
              entry: entries[0],
              place: 1,
              height: 96,
              round: round,
              badges: badges[entries[0].userId] ?? {}),
          if (entries.length > 2)
            _PodiumItem(
                entry: entries[2],
                place: 3,
                height: 56,
                round: round,
                badges: badges[entries[2].userId] ?? {}),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.entry,
    required this.place,
    required this.height,
    required this.round,
    required this.badges,
  });
  final LeaderboardEntry entry;
  final int place;
  final double height;
  final int? round;
  final Set<_Badge> badges;

  static const _placeColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFB0BEC5), // silver
    Color(0xFFBF8970), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    final pts = round != null ? entry.pointsForRound(round!) : entry.totalPoints;
    final placeColor = _placeColors[place - 1];
    final isFirst = place == 1;
    final badgeEmojis = badges.map((b) => b.emoji).join(' ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badgeEmojis.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(badgeEmojis,
                style: TextStyle(fontSize: isFirst ? 16 : 13)),
          ),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isFirst
                    ? [
                        BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2)
                      ]
                    : null,
              ),
              child: _TeamBadge(
                badgeUrl: entry.teamBadgeUrl,
                photoUrl: entry.photoUrl,
                name: entry.teamName ?? entry.displayName,
                radius: isFirst ? 30 : 24,
                borderColor: placeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            entry.teamName ?? entry.displayName,
            style: TextStyle(
                fontSize: isFirst ? 12 : 11,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (entry.teamName != null)
          Text(
            entry.displayName,
            style: const TextStyle(
                fontSize: 9, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text('$pts pts',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isFirst ? 13 : 11,
                color: AppColors.secondary)),
        const SizedBox(height: 4),
        Container(
          width: isFirst ? 68 : 56,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                placeColor.withValues(alpha: 0.9),
                placeColor.withValues(alpha: 0.6),
              ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          child: Text('$place',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isFirst ? 22 : 18,
                  color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Leaderboard row ───────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.isMe,
    required this.round,
    required this.badges,
    required this.onTap,
  });
  final LeaderboardEntry entry;
  final bool isMe;
  final int? round;
  final Set<_Badge> badges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rankChange = entry.rankChange;
    final displayPts =
        round != null ? entry.pointsForRound(round!) : entry.totalPoints;
    final roundInfo = round != null ? ScoringRounds.forRound(round!) : null;
    final isFirst = entry.rank == 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isFirst
              ? LinearGradient(colors: [
                  AppColors.secondary.withValues(alpha: 0.15),
                  AppColors.surface,
                ])
              : null,
          color: isFirst
              ? null
              : isMe
                  ? AppColors.primary.withAlpha(60)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: isFirst
              ? Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.6),
                  width: 1.5)
              : isMe
                  ? Border.all(color: AppColors.secondary, width: 1.5)
                  : null,
        ),
        child: Row(
          children: [
            // Rank + movement
            SizedBox(
              width: 36,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${entry.rank}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isFirst
                            ? AppColors.secondary
                            : AppColors.textPrimary),
                  ),
                  if (rankChange != 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rankChange > 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 10,
                          color: rankChange > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        Text('${rankChange.abs()}',
                            style: TextStyle(
                                fontSize: 9,
                                color: rankChange > 0
                                    ? AppColors.success
                                    : AppColors.error)),
                      ],
                    ),
                ],
              ),
            ),
            // Team badge
            _TeamBadge(
              badgeUrl: entry.teamBadgeUrl,
              photoUrl: entry.photoUrl,
              name: entry.teamName ?? entry.displayName,
              radius: 20,
              borderColor: isFirst ? AppColors.secondary : null,
            ),
            const SizedBox(width: 10),
            // Name + sublabel + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.teamName ?? entry.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        ...badges.take(2).map((b) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Text(b.emoji,
                                  style: const TextStyle(fontSize: 12)),
                            )),
                      ],
                      if (isMe)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('YOU',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    round != null
                        ? '${roundInfo?.label ?? ''} · Total: ${entry.totalPoints} pts'
                        : entry.teamName != null
                            ? entry.displayName
                            : 'Fantasy: ${entry.fantasyPoints} · Preds: ${entry.predictionPoints}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$displayPts',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17)),
                const Text('pts',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Team badge avatar ─────────────────────────────────────────────────────────

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({
    required this.name,
    required this.radius,
    this.badgeUrl,
    this.photoUrl,
    this.borderColor,
  });
  final String name;
  final double radius;
  final String? badgeUrl;
  final String? photoUrl;
  final Color? borderColor;

  static const _colors = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF880E4F),
    Color(0xFF004D40), Color(0xFFBF360C), Color(0xFF01579B),
    Color(0xFF1B5E20), Color(0xFF4E342E), Color(0xFF37474F),
    Color(0xFF4527A0),
  ];

  Color get _bgColor => _colors[name.codeUnitAt(0) % _colors.length];

  @override
  Widget build(BuildContext context) {
    final url = badgeUrl ?? photoUrl;
    final border = borderColor != null
        ? Border.all(color: borderColor!, width: 2)
        : null;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
        color: url == null ? _bgColor : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, x) => _Initial(name: name, color: _bgColor),
              errorWidget: (_, x, y) =>
                  _Initial(name: name, color: _bgColor),
            )
          : _Initial(name: name, color: _bgColor),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14),
      ),
    );
  }
}

// ── Manager card modal ────────────────────────────────────────────────────────

class _ManagerCard extends StatelessWidget {
  const _ManagerCard({required this.entry, required this.badges});
  final LeaderboardEntry entry;
  final Set<_Badge> badges;

  @override
  Widget build(BuildContext context) {
    final completedRounds = ScoringRounds.all
        .where((r) => r.isCompleted && entry.roundPoints.containsKey(r.round))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  // Header
                  Row(
                    children: [
                      _TeamBadge(
                        badgeUrl: entry.teamBadgeUrl,
                        photoUrl: entry.photoUrl,
                        name: entry.teamName ?? entry.displayName,
                        radius: 36,
                        borderColor: entry.rank == 1
                            ? AppColors.secondary
                            : AppColors.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.teamName ?? entry.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            if (entry.teamName != null)
                              Text(entry.displayName,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _RankBadge(rank: entry.rank),
                                const SizedBox(width: 8),
                                ...badges.map((b) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6),
                                      child: Tooltip(
                                        message: b.label,
                                        child: Text(b.emoji,
                                            style: const TextStyle(
                                                fontSize: 18)),
                                      ),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${entry.totalPoints}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  color: AppColors.secondary)),
                          const Text('total pts',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Points breakdown
                  _SectionTitle('Points Breakdown'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatCard(
                          label: 'Fantasy',
                          value: entry.fantasyPoints,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      _StatCard(
                          label: 'Predictions',
                          value: entry.predictionPoints,
                          color: const Color(0xFF6A1B9A)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tiebreakers
                  _SectionTitle('Tiebreakers'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatCard(
                          label: 'Exact Scores',
                          value: entry.exactScores,
                          color: AppColors.success),
                      const SizedBox(width: 8),
                      _StatCard(
                          label: 'Correct Results',
                          value: entry.correctResults,
                          color: AppColors.warning),
                    ],
                  ),
                  if (completedRounds.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('Round by Round'),
                    const SizedBox(height: 8),
                    ...completedRounds.map((r) => _RoundPointsRow(
                          label: r.shortLabel,
                          pts: entry.pointsForRound(r.round),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int? rank;

  @override
  Widget build(BuildContext context) {
    if (rank == null) return const SizedBox.shrink();
    final isFirst = rank == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFirst
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: isFirst
            ? Border.all(color: AppColors.secondary.withValues(alpha: 0.5))
            : null,
      ),
      child: Text(
        'Rank #$rank',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isFirst ? AppColors.secondary : AppColors.textSecondary),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _RoundPointsRow extends StatelessWidget {
  const _RoundPointsRow({required this.label, required this.pts});
  final String label;
  final int pts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Text('$pts pts',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
