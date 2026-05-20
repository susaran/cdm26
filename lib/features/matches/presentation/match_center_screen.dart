import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../domain/match_model.dart';
import 'matches_provider.dart';

class MatchCenterScreen extends ConsumerWidget {
  const MatchCenterScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    final eventsAsync = ref.watch(matchEventsProvider(matchId));

    return matchAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (match) {
        if (match == null) {
          return const Scaffold(body: Center(child: Text('Match not found')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${match.homeTeamName} vs ${match.awayTeamName}'),
          ),
          body: ListView(
            children: [
              _ScoreHeader(match: match),
              const Divider(),
              eventsAsync.when(
                loading: () => const LoadingWidget(),
                error: (_, __) => const SizedBox.shrink(),
                data: (events) => _EventsList(events: events),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (match.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.live,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text("LIVE ${match.minute}'",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          if (!match.isLive && match.isFinished)
            const Text('FULL TIME',
                style: TextStyle(color: AppColors.textSecondary)),
          if (match.isUpcoming)
            Text(
              DateFormat('EEE d MMM • HH:mm')
                  .format(match.scheduledKickoff.toLocal()),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: Text(match.homeTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              Text(
                '${match.homeScore} - ${match.awayScore}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: match.isLive ? AppColors.live : AppColors.textPrimary,
                ),
              ),
              Expanded(
                  child: Text(match.awayTeamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({required this.events});
  final List<MatchEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
            child: Text('No events yet',
                style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    return Column(
      children: events.map((e) => _EventRow(event: e)).toList(),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final MatchEvent event;

  @override
  Widget build(BuildContext context) {
    final icon = switch (event.type) {
      'goal' => const Icon(Icons.sports_soccer, color: AppColors.success),
      'yellow_card' =>
        const Icon(Icons.square, color: AppColors.yellowCard, size: 18),
      'red_card' =>
        const Icon(Icons.square, color: AppColors.redCard, size: 18),
      'substitution_on' =>
        const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
      _ => const Icon(Icons.circle, size: 8, color: AppColors.textDisabled),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
              width: 40,
              child: Text("${event.minute}'",
                  style: const TextStyle(color: AppColors.textSecondary))),
          icon,
          const SizedBox(width: 12),
          Expanded(child: Text(event.description ?? event.type)),
        ],
      ),
    );
  }
}
