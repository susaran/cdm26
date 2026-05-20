import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../auth/presentation/auth_provider.dart';
import '../data/prediction_repository.dart';
import '../domain/prediction_model.dart';

part 'prediction_provider.g.dart';

@riverpod
Stream<List<PredictionModel>> userPredictions(
    Ref ref, String leagueId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref
      .watch(predictionRepositoryProvider)
      .watchUserPredictions(leagueId, user.uid);
}
