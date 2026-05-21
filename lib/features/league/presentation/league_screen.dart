import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import 'league_provider.dart';

class LeagueScreen extends ConsumerWidget {
  const LeagueScreen({super.key});

  void _showLeagueActions(
      BuildContext context, String leagueId, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Leaderboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/leagues/$leagueId/leaderboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_esports),
              title: const Text('Draft Room'),
              onTap: () {
                Navigator.pop(context);
                context.go('/leagues/$leagueId/draft');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Build Squad'),
              onTap: () {
                Navigator.pop(context);
                context.go('/leagues/$leagueId/team');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Trades'),
              onTap: () {
                Navigator.pop(context);
                context.go('/leagues/$leagueId/trades');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('Predictions'),
              onTap: () {
                Navigator.pop(context);
                context.go('/leagues/$leagueId/predictions');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(userLeaguesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leagues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/leagues/create'),
          ),
        ],
      ),
      body: leaguesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (leagues) {
          if (leagues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No leagues yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Create or join a league to start playing',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/leagues/create'),
                    child: const Text('Create League'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/leagues/join'),
                    child: const Text('Join with Code'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leagues.length + 1,
            itemBuilder: (ctx, i) {
              if (i == leagues.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.group_add),
                    label: const Text('Join League with Code'),
                    onPressed: () => context.go('/leagues/join'),
                  ),
                );
              }
              final league = leagues[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    backgroundImage: league.avatarUrl != null
                        ? NetworkImage(league.avatarUrl!)
                        : null,
                    child: league.avatarUrl == null
                        ? Text(league.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(league.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${league.memberCount} members • ${league.status.name}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLeagueActions(context, league.leagueId, league.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
