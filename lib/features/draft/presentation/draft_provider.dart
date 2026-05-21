import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../matches/domain/player_model.dart';
import '../data/draft_repository.dart';
import '../domain/draft_model.dart';

part 'draft_provider.g.dart';

@riverpod
Stream<DraftModel?> draft(Ref ref, String leagueId) =>
    ref.watch(draftRepositoryProvider).watchDraft(leagueId);

@riverpod
Stream<List<DraftPick>> draftPicks(Ref ref, String leagueId) =>
    ref.watch(draftRepositoryProvider).watchDraftPicks(leagueId);

@riverpod
Stream<List<PlayerModel>> availablePlayers(
    Ref ref, String leagueId, List<String> draftedIds) =>
    ref.watch(draftRepositoryProvider).watchAvailablePlayers(leagueId, draftedIds);
