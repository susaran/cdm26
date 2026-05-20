import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/data/auth_service.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('No profile found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 36, color: Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text('@${user.username}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 32),
              _StatsRow(stats: [
                ('Leagues Joined', user.stats.leaguesJoined.toString()),
                ('Leagues Won', user.stats.leaguesWon.toString()),
                ('Exact Scores', user.stats.exactScores.toString()),
              ]),
              const SizedBox(height: 16),
              _StatsRow(stats: [
                ('Fantasy Pts', user.stats.totalFantasyPoints.toString()),
                ('Prediction Pts', user.stats.totalPredictionPoints.toString()),
                ('Correct Results', user.stats.correctResults.toString()),
              ]),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(s.$2,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold,
                                color: AppColors.secondary)),
                        const SizedBox(height: 4),
                        Text(s.$1,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
