import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../league/presentation/league_provider.dart';
import '../data/draft_repository.dart';
import '../domain/draft_model.dart';
import 'draft_provider.dart';

class DraftLobbyScreen extends ConsumerWidget {
  const DraftLobbyScreen({super.key, required this.leagueId});
  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftAsync = ref.watch(draftProvider(leagueId));
    final leagueAsync = ref.watch(leagueByIdProvider(leagueId));
    final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Draft Lobby')),
      body: draftAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (draft) {
          if (draft == null) {
            return _NoDraftState(leagueId: leagueId);
          }

          return switch (draft.status) {
            DraftStatus.active => _ActiveDraftBanner(
                leagueId: leagueId,
                draft: draft,
                userId: userId,
              ),
            DraftStatus.completed => const _CompletedBanner(),
            DraftStatus.cancelled => const _CancelledBanner(),
            DraftStatus.scheduled => _ScheduledState(
                leagueId: leagueId,
                draft: draft,
                userId: userId,
                leagueAsync: leagueAsync,
              ),
          };
        },
      ),
    );
  }
}

// ── No draft configured yet ──────────────────────────────────────────────────

class _NoDraftState extends ConsumerWidget {
  const _NoDraftState({required this.leagueId});
  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(leagueByIdProvider(leagueId));
    final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return leagueAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('$e')),
      data: (league) {
        final isOwner = league?.ownerUserId == userId;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports_outlined,
                    size: 72, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('No draft scheduled',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Set a draft date and time so your league can pick their squads.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: const Text('Schedule Draft'),
                    onPressed: () => _showSchedulePicker(context, ref),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSchedulePicker(
      BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026, 6, 10),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (time == null || !context.mounted) return;

    final scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    await ref
        .read(draftRepositoryProvider)
        .scheduleDraft(leagueId, scheduledAt);
  }
}

// ── Draft is scheduled ───────────────────────────────────────────────────────

class _ScheduledState extends ConsumerStatefulWidget {
  const _ScheduledState({
    required this.leagueId,
    required this.draft,
    required this.userId,
    required this.leagueAsync,
  });
  final String leagueId;
  final DraftModel draft;
  final String userId;
  final AsyncValue leagueAsync;

  @override
  ConsumerState<_ScheduledState> createState() => _ScheduledStateState();
}

class _ScheduledStateState extends ConsumerState<_ScheduledState> {
  late final _timer = Stream.periodic(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _timer,
      builder: (context, _) {
        final now = DateTime.now();
        final scheduled = widget.draft.scheduledAt;
        final diff = scheduled != null ? scheduled.difference(now) : Duration.zero;
        final canStart = diff.isNegative || diff.inSeconds < 60;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Countdown card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Draft starts in',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    if (scheduled != null && !diff.isNegative)
                      _CountdownDisplay(diff: diff)
                    else
                      const Text('Ready to start!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (scheduled != null)
                      Text(
                        DateFormat('EEEE, MMM d • h:mm a').format(scheduled),
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Draft rules reminder
              _RulesCard(),

              const SizedBox(height: 24),

              widget.leagueAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (league) {
                  final isOwner = league?.ownerUserId == widget.userId;
                  if (!isOwner) {
                    return const Text(
                      'Wait for the league owner to start the draft.',
                      style: TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    );
                  }
                  return Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Draft Now'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: AppColors.success,
                        ),
                        onPressed: canStart
                            ? () => _startDraft(context, ref, league!)
                            : null,
                      ),
                      if (!canStart)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Available when the scheduled time is reached.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startDraft(BuildContext context, WidgetRef ref, dynamic league) async {
    final membersSnap = await FirebaseFirestore.instance
        .collection('leagues')
        .doc(widget.leagueId)
        .collection('members')
        .get();
    final memberIds = membersSnap.docs.map((d) => d.id).toList();

    await ref.read(draftRepositoryProvider).startDraft(widget.leagueId, memberIds);
    if (context.mounted) {
      context.go('/leagues/${widget.leagueId}/draft/room');
    }
  }
}

class _CountdownDisplay extends StatelessWidget {
  const _CountdownDisplay({required this.diff});
  final Duration diff;

  @override
  Widget build(BuildContext context) {
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    final secs = diff.inSeconds % 60;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Unit(value: days, label: 'D'),
        const _Sep(),
        _Unit(value: hours, label: 'H'),
        const _Sep(),
        _Unit(value: mins, label: 'M'),
        const _Sep(),
        _Unit(value: secs, label: 'S'),
      ],
    );
  }
}

class _Unit extends StatelessWidget {
  const _Unit({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value.toString().padLeft(2, '0'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      );
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(':',
            style: TextStyle(
                color: Colors.white38, fontSize: 28, height: 1.2)),
      );
}

class _RulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Draft Rules',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...[
              ('🐍', 'Snake draft format — order reverses each round'),
              ('⏱️', '2 minutes per pick'),
              ('🚫', 'Once picked, a player is locked to that team'),
              ('👥', '15 players per squad: 2 GK · 5 DEF · 5 MID · 3 FWD'),
              ('💰', 'No salary cap — draft freely'),
              ('🔁', 'Trades open after the draft, until the semifinals'),
            ].map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(r.$1, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(r.$2,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Active draft banner ───────────────────────────────────────────────────────

class _ActiveDraftBanner extends StatelessWidget {
  const _ActiveDraftBanner({
    required this.leagueId,
    required this.draft,
    required this.userId,
  });
  final String leagueId;
  final DraftModel draft;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final isMyTurn = draft.currentPickUserId == userId;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMyTurn ? Icons.touch_app : Icons.hourglass_top,
              size: 72,
              color: isMyTurn ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isMyTurn ? "It's your pick!" : "Draft in progress",
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Round ${draft.currentRound} · Pick ${draft.pickInRound}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_esports),
              label: const Text('Enter Draft Room'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 52),
              ),
              onPressed: () =>
                  context.go('/leagues/$leagueId/draft/room'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 72, color: AppColors.success),
            SizedBox(height: 16),
            Text('Draft Complete!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('All teams have been drafted.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 72, color: AppColors.error),
            SizedBox(height: 16),
            Text('Draft Cancelled',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
