import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../domain/match_model.dart';
import 'matches_provider.dart';
import '../../../features/splash/splash_screen.dart';

// Height of the hidden overscroll branding header
const _kBrandingHeight = 96.0;

class FixturesScreen extends ConsumerStatefulWidget {
  const FixturesScreen({super.key});

  @override
  ConsumerState<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends ConsumerState<FixturesScreen> {
  // Start scrolled past the branding so it's hidden above the fold
  late final ScrollController _scrollCtrl =
      ScrollController(initialScrollOffset: _kBrandingHeight);

  static final _tournamentStart = DateTime.utc(2026, 6, 11, 18, 0);

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(upcomingMatchesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('World Cup 2026')),
      body: matchesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) => CustomScrollView(
          controller: _scrollCtrl,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Overscroll branding (hidden above fold by initial offset) ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: _kBrandingHeight,
                child: _OverscrollBranding(),
              ),
            ),

            // ── Main content ──────────────────────────────────────────────
            if (matches.isEmpty)
              ..._draftOpenSlivers(context)
            else
              ..._fixtureSlivers(context, matches),
          ],
        ),
      ),
    );
  }

  List<Widget> _draftOpenSlivers(BuildContext context) {
    return [
      SliverToBoxAdapter(
        child: _DraftOpenState(tournamentStart: _tournamentStart),
      ),
    ];
  }

  List<Widget> _fixtureSlivers(BuildContext context, List<MatchModel> matches) {
    final grouped = _groupByDate(matches);
    final items = <Widget>[];

    for (final entry in grouped.entries) {
      items.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            entry.key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ));
      items.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _MatchTile(match: entry.value[i]),
          childCount: entry.value.length,
        ),
      ));
    }

    return items;
  }

  Map<String, List<MatchModel>> _groupByDate(List<MatchModel> matches) {
    final map = <String, List<MatchModel>>{};
    for (final m in matches) {
      final key = DateFormat('EEEE, MMM d').format(m.scheduledKickoff.toLocal());
      map.putIfAbsent(key, () => []).add(m);
    }
    return map;
  }
}

// ─── Overscroll branding header ──────────────────────────────────────────────

class _OverscrollBranding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kBrandingHeight,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GallardiganLogo(size: 44),
          const SizedBox(height: 8),
          const Text(
            'May the best Gallardigan win',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Draft Open State ────────────────────────────────────────────────────────

class _DraftOpenState extends StatelessWidget {
  const _DraftOpenState({required this.tournamentStart});
  final DateTime tournamentStart;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final diff = tournamentStart.difference(now);
    final daysLeft = diff.inDays;
    final hoursLeft = diff.inHours % 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero card
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_soccer,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('DRAFT OPEN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'FIFA World Cup\n2026',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2),
                ),
                const SizedBox(height: 8),
                const Text(
                  'USA · Canada · Mexico',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CountdownBox(value: daysLeft.toString(), label: 'DAYS'),
                      _Separator(),
                      _CountdownBox(
                          value: hoursLeft.toString().padLeft(2, '0'),
                          label: 'HOURS'),
                      _Separator(),
                      _CountdownBox(
                          value: DateFormat('MMM d').format(tournamentStart),
                          label: 'KICK OFF'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'The draft window is open. Build your 15-player squad before the first whistle.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        // Get started section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Get Started',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.group_add,
                title: 'Create or Join a League',
                subtitle: 'Play against friends with a private league',
                color: AppColors.primary,
                onTap: () => context.go('/leagues'),
              ),
              const SizedBox(height: 8),
              _ActionCard(
                icon: Icons.people,
                title: 'Build Your Squad',
                subtitle:
                    '15 players · £100m budget · 2 GK / 5 DEF / 5 MID / 3 FWD',
                color: AppColors.midColor,
                onTap: () => context.go('/leagues'),
              ),
            ],
          ),
        ),

        // Scoring highlights
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Scoring Highlights',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _ScoreChip('⚽ Goal (FWD)', '+5 pts'),
                  _ScoreChip('🎯 Goal (MID)', '+6 pts'),
                  _ScoreChip('🛡️ Goal (DEF)', '+7 pts'),
                  _ScoreChip('🤝 Assist', '+3 pts'),
                  _ScoreChip('🔒 Clean Sheet (GK)', '+5 pts'),
                  _ScoreChip('✋ Tackle Won', '+1 pt'),
                  _ScoreChip('🎩 Captain', '×2 pts'),
                  _ScoreChip('🔑 Key Pass', '+1 pt'),
                  _ScoreChip('🎯 Shot on Target', '+1 pt'),
                  _ScoreChip('🚫 Big Chance Created', '+1 pt'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Text(':', style: TextStyle(color: Colors.white38, fontSize: 24));
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip(this.label, this.pts);
  final String label;
  final String pts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '$label  ',
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            TextSpan(
                text: pts,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.positivePoints,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ─── Match Tiles (reused when fixtures are loaded) ────────────────────────────

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/fixtures/match/${match.matchId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  match.homeTeamName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              _ScoreOrTime(match: match),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  match.awayTeamName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreOrTime extends StatelessWidget {
  const _ScoreOrTime({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    if (match.isFinished) {
      return Text(
        '${match.homeScore} - ${match.awayScore}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      );
    }
    if (match.isLive) {
      return Column(
        children: [
          Text(
            '${match.homeScore} - ${match.awayScore}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.live),
          ),
          Text("${match.minute}'",
              style: const TextStyle(color: AppColors.live, fontSize: 11)),
        ],
      );
    }
    return Text(
      DateFormat('HH:mm').format(match.scheduledKickoff.toLocal()),
      style: const TextStyle(color: AppColors.textSecondary),
    );
  }
}
