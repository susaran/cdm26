import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../data/trade_repository.dart';
import '../domain/trade_model.dart';

part 'trade_provider.g.dart';

@riverpod
Stream<List<TradeModel>> leagueTrades(
    Ref ref, String leagueId, String userId) =>
    ref.watch(tradeRepositoryProvider).watchLeagueTrades(leagueId, userId);
