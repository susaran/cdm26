import 'package:riverpod/riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/team_repository.dart';
import '../domain/team_model.dart';

part 'team_provider.g.dart';

@riverpod
Stream<TeamModel?> myTeam(Ref ref, String leagueId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(teamRepositoryProvider).watchTeam(leagueId, user.uid);
}
