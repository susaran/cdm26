import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../data/match_repository.dart';
import '../domain/match_model.dart';
import '../domain/player_model.dart';
// NationalTeam is defined in match_repository.dart

part 'matches_provider.g.dart';

@riverpod
Stream<List<MatchModel>> upcomingMatches(Ref ref) {
  return ref.watch(matchRepositoryProvider).watchUpcomingMatches();
}

@riverpod
Stream<MatchModel?> matchDetail(Ref ref, String matchId) {
  return ref.watch(matchRepositoryProvider).watchMatch(matchId);
}

@riverpod
Stream<List<MatchEvent>> matchEvents(Ref ref, String matchId) {
  return ref.watch(matchRepositoryProvider).watchMatchEvents(matchId);
}

@riverpod
Future<List<PlayerModel>> allPlayers(Ref ref) {
  return ref.watch(matchRepositoryProvider).getAllPlayers();
}

@riverpod
Stream<List<NationalTeam>> nationalTeams(Ref ref) {
  return ref.watch(matchRepositoryProvider).watchNationalTeams();
}
