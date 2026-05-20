import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../matches/domain/match_model.dart';
import '../../matches/presentation/matches_provider.dart';
import '../data/prediction_repository.dart';
import '../domain/prediction_model.dart';
import 'prediction_provider.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(upcomingMatchesProvider);
    final predictionsAsync = ref.watch(userPredictionsProvider(leagueId));

    return Scaffold(
      appBar: AppBar(title: const Text('Predictions')),
      body: matchesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          final predictions = predictionsAsync.valueOrNull ?? [];
          final predMap = {for (final p in predictions) p.matchId: p};
          final upcoming = matches
              .where((m) => m.scheduledKickoff.isAfter(DateTime.now()))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcoming.length,
            itemBuilder: (ctx, i) {
              final match = upcoming[i];
              final prediction = predMap[match.matchId];
              return _PredictionCard(
                match: match,
                prediction: prediction,
                leagueId: leagueId,
              );
            },
          );
        },
      ),
    );
  }
}

class _PredictionCard extends ConsumerStatefulWidget {
  const _PredictionCard({
    required this.match,
    required this.leagueId,
    this.prediction,
  });

  final MatchModel match;
  final String leagueId;
  final PredictionModel? prediction;

  @override
  ConsumerState<_PredictionCard> createState() => _PredictionCardState();
}

class _PredictionCardState extends ConsumerState<_PredictionCard> {
  late int _home;
  late int _away;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _home = widget.prediction?.homeScore ?? 0;
    _away = widget.prediction?.awayScore ?? 0;
  }

  bool get _isLocked =>
      widget.match.scheduledKickoff.isBefore(DateTime.now());

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      await ref.read(predictionRepositoryProvider).savePrediction(
            leagueId: widget.leagueId,
            userId: user.uid,
            matchId: widget.match.matchId,
            match: widget.match,
            homeScore: _home,
            awayScore: _away,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prediction saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEE d MMM • HH:mm')
                      .format(widget.match.scheduledKickoff.toLocal()),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                if (_isLocked)
                  const Chip(
                    label: Text('LOCKED', style: TextStyle(fontSize: 10)),
                    backgroundColor: AppColors.surfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: Text(widget.match.homeTeamName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                _ScoreInput(
                  value: _home,
                  onChanged: _isLocked ? null : (v) => setState(() => _home = v),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _ScoreInput(
                  value: _away,
                  onChanged: _isLocked ? null : (v) => setState(() => _away = v),
                ),
                Expanded(
                    child: Text(widget.match.awayTeamName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            if (!_isLocked) ...[
              const SizedBox(height: 12),
              AppButton(
                label: widget.prediction?.isSubmitted == true
                    ? 'Update Prediction'
                    : 'Save Prediction',
                loading: _saving,
                onPressed: _save,
              ),
            ],
            if (widget.prediction?.points.total != null &&
                widget.prediction!.points.total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${widget.prediction!.points.total} pts',
                  style: const TextStyle(
                      color: AppColors.positivePoints,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreInput extends StatelessWidget {
  const _ScoreInput({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onChanged != null)
            IconButton(
              icon: const Icon(Icons.remove, size: 16),
              onPressed: value > 0 ? () => onChanged!(value - 1) : null,
              visualDensity: VisualDensity.compact,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$value',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          if (onChanged != null)
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              onPressed: value < 20 ? () => onChanged!(value + 1) : null,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
