import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_entry_model.dart';

part 'leaderboard_provider.g.dart';

@riverpod
Stream<List<LeaderboardEntry>> leaderboard(Ref ref, String leagueId) {
  return ref.watch(leaderboardRepositoryProvider).watchLeaderboard(leagueId);
}
