import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../league/data/league_repository.dart';
import '../domain/leaderboard_entry_model.dart';
import 'leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(leagueId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'team':
                  context.go('/leagues/$leagueId/team');
                case 'predictions':
                  context.go('/leagues/$leagueId/predictions');
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
          return Column(
            children: [
              if (entries.length >= 3) _Podium(entries: entries.take(3).toList()),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final entry = entries[i];
                    final isMe = entry.userId == currentUser?.uid;
                    return _LeaderboardRow(entry: entry, isMe: isMe);
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

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entries.length > 1) _PodiumItem(entry: entries[1], place: 2, height: 70),
          _PodiumItem(entry: entries[0], place: 1, height: 90),
          if (entries.length > 2) _PodiumItem(entry: entries[2], place: 3, height: 55),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem(
      {required this.entry, required this.place, required this.height});
  final LeaderboardEntry entry;
  final int place;
  final double height;

  @override
  Widget build(BuildContext context) {
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
        Text('${entry.totalPoints} pts',
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
                  fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.isMe});
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final rankChange = entry.rankChange;
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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            backgroundImage:
                entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
            child: entry.photoUrl == null
                ? Text(entry.displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${entry.displayName} (You)' : entry.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'F: ${entry.fantasyPoints} · P: ${entry.predictionPoints}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalPoints}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (rankChange != 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rankChange > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
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
                            : AppColors.error,
                      ),
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
