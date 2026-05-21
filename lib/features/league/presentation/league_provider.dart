import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../auth/presentation/auth_provider.dart';
import '../data/league_repository.dart';
import '../domain/league_member_model.dart';
import '../domain/league_model.dart';

part 'league_provider.g.dart';

@riverpod
Stream<List<LeagueModel>> userLeagues(Ref ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(leagueRepositoryProvider).watchUserLeagues(user.uid);
}

@riverpod
Stream<List<LeagueMemberModel>> leagueMembers(
    Ref ref, String leagueId) {
  return ref.watch(leagueRepositoryProvider).watchLeagueMembers(leagueId);
}

@riverpod
Future<LeagueModel?> leagueById(Ref ref, String leagueId) {
  return ref.watch(leagueRepositoryProvider).getLeague(leagueId);
}
