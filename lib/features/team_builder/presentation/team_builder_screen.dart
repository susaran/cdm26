import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/scoring_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../matches/data/match_repository.dart';
import '../../matches/domain/player_model.dart';
import '../../matches/presentation/matches_provider.dart';
import '../data/team_repository.dart';
import '../domain/team_model.dart';
import 'team_provider.dart';

class TeamBuilderScreen extends ConsumerStatefulWidget {
  const TeamBuilderScreen({super.key, required this.leagueId});
  final String leagueId;

  @override
  ConsumerState<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends ConsumerState<TeamBuilderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(myTeamProvider(widget.leagueId));
    final playersAsync = ref.watch(allPlayersProvider);

    return teamAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (team) {
        final currentTeam = team ??
            TeamModel(
              leagueId: widget.leagueId,
              userId: ref.read(authStateProvider).valueOrNull?.uid ?? '',
              players: [],
            );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Draft Squad'),
            actions: [_BudgetChip(team: currentTeam), const SizedBox(width: 8)],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.people, size: 18), text: 'My Squad'),
                Tab(icon: Icon(Icons.search, size: 18), text: 'Players'),
                Tab(icon: Icon(Icons.star, size: 18), text: 'Scoring'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _MySquadTab(team: currentTeam, leagueId: widget.leagueId),
              playersAsync.when(
                loading: () => const LoadingWidget(),
                error: (e, _) => Center(child: Text('$e')),
                data: (players) => _PlayerMarketTab(
                  players: players,
                  team: currentTeam,
                  leagueId: widget.leagueId,
                ),
              ),
              const _ScoringGuideTab(),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget chip in app bar
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetChip extends StatelessWidget {
  const _BudgetChip({required this.team});
  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    final ok = team.budgetRemaining >= 0;
    return Chip(
      backgroundColor: ok ? AppColors.surfaceVariant : AppColors.error,
      label: Text(
        '£${team.budgetRemaining.toStringAsFixed(1)}m',
        style: TextStyle(
          color: ok ? AppColors.secondary : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      avatar: Icon(Icons.account_balance_wallet,
          size: 16, color: ok ? AppColors.secondary : Colors.white),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MY SQUAD TAB
// ─────────────────────────────────────────────────────────────────────────────

class _MySquadTab extends ConsumerWidget {
  const _MySquadTab({required this.team, required this.leagueId});
  final TeamModel team;
  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = [
      ('GK', kRequiredGK, AppColors.gkColor),
      ('DEF', kRequiredDEF, AppColors.defColor),
      ('MID', kRequiredMID, AppColors.midColor),
      ('FWD', kRequiredFWD, AppColors.fwdColor),
    ];

    return Column(
      children: [
        _SquadProgress(team: team),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              for (final (pos, required, color) in sections) ...[
                _PositionHeader(
                    position: pos,
                    count: team.players.where((p) => p.position == pos).length,
                    required: required,
                    color: color),
                ...team.players
                    .where((p) => p.position == pos)
                    .map((slot) => _SquadPlayerTile(
                          slot: slot,
                          isCaptain: team.captainPlayerId == slot.playerId,
                          isViceCaptain:
                              team.viceCaptainPlayerId == slot.playerId,
                          onTap: () => _showPlayerActions(context, ref, slot),
                        )),
                ...List.generate(
                  required -
                      team.players.where((p) => p.position == pos).length,
                  (_) => _EmptySlot(position: pos, color: color),
                ),
              ],
              // ── Team DST pick ──
              _DSTPickTile(
                team: team,
                onTap: () => _showTeamPicker(context, ref),
              ),
              const SizedBox(height: 8),
              _validationErrors(context),
              const SizedBox(height: 8),
              if (team.hasMinimumPlayers)
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Lock In Squad'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () => _submit(context, ref),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  label: Text(
                      'Draft ${kSquadTotal - team.players.length} more players'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _validationErrors(BuildContext context) {
    if (team.validation.errors.isEmpty && team.players.isEmpty) return const SizedBox.shrink();
    final errors = team.validation.errors;
    if (errors.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors
            .map((e) => Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(e,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.error))),
                ]))
            .toList(),
      ),
    );
  }

  void _showPlayerActions(
      BuildContext context, WidgetRef ref, TeamPlayerSlot slot) {
    final isCaptain = team.captainPlayerId == slot.playerId;
    final isVc = team.viceCaptainPlayerId == slot.playerId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _PositionBadge(position: slot.position),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slot.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(slot.teamName,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('£${slot.purchasePrice.toStringAsFixed(1)}m',
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 24),
            if (!isCaptain)
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    radius: 14,
                    child: Text('C',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
                title: const Text('Set as Captain'),
                subtitle: const Text('All points ×2'),
                onTap: () async {
                  Navigator.pop(context);
                  final repo = ref.read(teamRepositoryProvider);
                  final updated = repo.setCaptain(team, slot.playerId);
                  await repo.saveTeam(updated);
                },
              ),
            if (!isVc && !isCaptain)
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 14,
                    child: Text('V',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold))),
                title: const Text('Set as Vice-Captain'),
                subtitle: const Text('Points ×1.5 if captain doesn\'t play'),
                onTap: () async {
                  Navigator.pop(context);
                  final repo = ref.read(teamRepositoryProvider);
                  final updated = repo.setViceCaptain(team, slot.playerId);
                  await repo.saveTeam(updated);
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.remove_circle_outline, color: AppColors.error),
              title: const Text('Remove from Squad',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(teamRepositoryProvider);
                final updated = repo.removePlayer(team, slot.playerId);
                await repo.saveTeam(updated);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showTeamPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _TeamPickerSheet(team: team, leagueId: leagueId),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(teamRepositoryProvider).submitTeam(team);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Squad locked in!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _SquadProgress extends StatelessWidget {
  const _SquadProgress({required this.team});
  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          _PositionCount('GK', team.gkCount, kRequiredGK, AppColors.gkColor),
          _PositionCount('DEF', team.defCount, kRequiredDEF, AppColors.defColor),
          _PositionCount('MID', team.midCount, kRequiredMID, AppColors.midColor),
          _PositionCount('FWD', team.fwdCount, kRequiredFWD, AppColors.fwdColor),
          const Spacer(),
          Text(
            '${team.players.length}/$kSquadTotal',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PositionCount extends StatelessWidget {
  const _PositionCount(this.label, this.count, this.required, this.color);
  final String label;
  final int count;
  final int required;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final done = count >= required;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('$count/$required',
              style: TextStyle(
                  color: done ? AppColors.success : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: done ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _PositionHeader extends StatelessWidget {
  const _PositionHeader(
      {required this.position,
      required this.count,
      required this.required,
      required this.color});
  final String position;
  final int count;
  final int required;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            _label(position),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1),
          ),
          const SizedBox(width: 8),
          Text('$count / $required',
              style: TextStyle(
                  fontSize: 11,
                  color: count >= required ? AppColors.success : AppColors.warning)),
        ],
      ),
    );
  }

  String _label(String pos) => switch (pos) {
        'GK' => 'GOALKEEPERS',
        'DEF' => 'DEFENDERS',
        'MID' => 'MIDFIELDERS',
        'FWD' => 'FORWARDS',
        _ => pos,
      };
}

class _SquadPlayerTile extends StatelessWidget {
  const _SquadPlayerTile({
    required this.slot,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.onTap,
  });
  final TeamPlayerSlot slot;
  final bool isCaptain;
  final bool isViceCaptain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _PositionBadge(position: slot.position),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            slot.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        if (isCaptain) _Badge('C', AppColors.secondary),
                        if (isViceCaptain) _Badge('V', AppColors.primary),
                      ],
                    ),
                    Text(
                      slot.teamName,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '£${slot.purchasePrice.toStringAsFixed(1)}m',
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.position, required this.color});
  final String position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(position,
                  style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Text('Add $position',
              style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position});
  final String position;

  @override
  Widget build(BuildContext context) {
    final color = _color(position);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(position,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Color _color(String pos) => switch (pos) {
        'GK' => AppColors.gkColor,
        'DEF' => AppColors.defColor,
        'MID' => AppColors.midColor,
        _ => AppColors.fwdColor,
      };
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYER MARKET TAB
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerMarketTab extends ConsumerStatefulWidget {
  const _PlayerMarketTab({
    required this.players,
    required this.team,
    required this.leagueId,
  });
  final List<PlayerModel> players;
  final TeamModel team;
  final String leagueId;

  @override
  ConsumerState<_PlayerMarketTab> createState() => _PlayerMarketTabState();
}

class _PlayerMarketTabState extends ConsumerState<_PlayerMarketTab> {
  String _posFilter = 'ALL';
  String _sortBy = 'price';
  final _search = TextEditingController();

  static const _positions = ['ALL', 'GK', 'DEF', 'MID', 'FWD', 'TEAM'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PlayerModel> get _filtered {
    var list = widget.players.where((p) {
      if (_posFilter != 'ALL' && p.positionLabel != _posFilter) return false;
      if (_search.text.isNotEmpty &&
          !p.displayName.toLowerCase().contains(_search.text.toLowerCase()) &&
          !p.teamName.toLowerCase().contains(_search.text.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) => switch (_sortBy) {
          'price_asc' => a.fantasyPrice.compareTo(b.fantasyPrice),
          'points' => b.statsSummary.totalFantasyPoints
              .compareTo(a.statsSummary.totalFantasyPoints),
          _ => b.fantasyPrice.compareTo(a.fantasyPrice),
        });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = widget.team.players.map((p) => p.playerId).toSet();
    final repo = ref.read(teamRepositoryProvider);
    final filtered = _filtered;

    return Column(
      children: [
        // Search + sort row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search player or team…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            })
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (v) => setState(() => _sortBy = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'price', child: Text('Price ↓')),
                  PopupMenuItem(value: 'price_asc', child: Text('Price ↑')),
                  PopupMenuItem(value: 'points', child: Text('Points ↓')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textDisabled),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sort, size: 16),
                      SizedBox(width: 4),
                      Text('Sort', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Position filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _positions.map((pos) {
              final isSelected = _posFilter == pos;
              final slotsLeft = switch (pos) {
                'GK' => widget.team.gkSlotsFree,
                'DEF' => widget.team.defSlotsFree,
                'MID' => widget.team.midSlotsFree,
                'FWD' => widget.team.fwdSlotsFree,
                _ => null,
              };
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    pos == 'ALL'
                        ? 'All'
                        : '$pos${slotsLeft != null && slotsLeft > 0 ? ' ($slotsLeft)' : ''}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _posFilter = pos),
                  selectedColor: _posColor(pos),
                  backgroundColor: AppColors.surface,
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // If TEAM filter active, show national team picker instead of player list
        if (_posFilter == 'TEAM')
          Expanded(
            child: _NationalTeamList(team: widget.team, leagueId: widget.leagueId),
          )
        else
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No players found',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final player = filtered[i];
                      final isSelected = selectedIds.contains(player.playerId);
                      final canAdd = !isSelected &&
                          repo.canAddPosition(widget.team, player.positionLabel) &&
                          widget.team.budgetRemaining >= player.fantasyPrice &&
                          widget.team.players.length < kSquadTotal;

                      return _MarketPlayerTile(
                        player: player,
                        isSelected: isSelected,
                        canAdd: canAdd,
                        onAdd: canAdd
                            ? () async {
                                try {
                                  final updated =
                                      repo.addPlayer(widget.team, player);
                                  await repo.saveTeam(updated);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())));
                                  }
                                }
                              }
                            : null,
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Color _posColor(String pos) => switch (pos) {
        'GK' => AppColors.gkColor,
        'DEF' => AppColors.defColor,
        'MID' => AppColors.midColor,
        'TEAM' => AppColors.secondary,
        'FWD' => AppColors.fwdColor,
        _ => AppColors.primary,
      };
}

class _MarketPlayerTile extends StatelessWidget {
  const _MarketPlayerTile({
    required this.player,
    required this.isSelected,
    required this.canAdd,
    required this.onAdd,
  });
  final PlayerModel player;
  final bool isSelected;
  final bool canAdd;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _PositionBadge(position: player.positionLabel),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(
                    children: [
                      Text(player.teamName,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      if (player.statsSummary.totalFantasyPoints > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${player.statsSummary.totalFantasyPoints} pts',
                          style: const TextStyle(
                              color: AppColors.positivePoints, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('£${player.fantasyPrice.toStringAsFixed(1)}m',
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                if (isSelected)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 14),
                      SizedBox(width: 2),
                      Text('In squad',
                          style: TextStyle(
                              color: AppColors.success, fontSize: 10)),
                    ],
                  )
                else
                  SizedBox(
                    height: 28,
                    child: FilledButton(
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        backgroundColor: canAdd
                            ? AppColors.primary
                            : AppColors.textDisabled,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DST TEAM PICK TILE (in My Squad)
// ─────────────────────────────────────────────────────────────────────────────

class _DSTPickTile extends StatelessWidget {
  const _DSTPickTile({required this.team, required this.onTap});
  final TeamModel team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picked = team.teamPickId != null;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('TEAM DEFENSE (DST)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1)),
              const SizedBox(width: 8),
              Text(picked ? '1 / 1' : '0 / 1',
                  style: TextStyle(
                      fontSize: 11,
                      color: picked ? AppColors.success : AppColors.warning)),
            ],
          ),
          const SizedBox(height: 6),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: picked
                            ? AppColors.secondary.withValues(alpha: 0.2)
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          picked ? '🛡️' : '?',
                          style: TextStyle(
                              fontSize: picked ? 18 : 20,
                              color: picked ? null : AppColors.textDisabled),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: picked
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(team.teamPickName ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const Text('National team defense',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            )
                          : const Text('Pick a national team',
                              style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    Icon(
                      picked ? Icons.swap_horiz : Icons.add_circle_outline,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAM PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _TeamPickerSheet extends ConsumerWidget {
  const _TeamPickerSheet({required this.team, required this.leagueId});
  final TeamModel team;
  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(nationalTeamsProvider);
    final repo = ref.read(teamRepositoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.shield, color: AppColors.secondary),
                SizedBox(width: 8),
                Text('Pick Your Team Defense',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Scores points for wins, goals scored, clean sheets, and solid defending.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: teamsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('$e')),
              data: (teams) => ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: teams.length,
                itemBuilder: (_, i) {
                  final t = teams[i];
                  final isSelected = team.teamPickId == t.teamId;
                  return Card(
                    color: isSelected
                        ? AppColors.secondary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceVariant,
                        child: Text(t.flagEmoji.isNotEmpty ? t.flagEmoji : '🏳️',
                            style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(t.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: t.group.isNotEmpty
                          ? Text('Group ${t.group}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12))
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppColors.success)
                          : const Icon(Icons.radio_button_unchecked,
                              color: AppColors.textDisabled),
                      onTap: () async {
                        final updated = repo.setTeamPick(team, t.teamId, t.name);
                        await repo.saveTeam(updated);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          if (team.teamPickId != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.error),
                label: const Text('Remove team pick',
                    style: TextStyle(color: AppColors.error)),
                onPressed: () async {
                  final updated = repo.removeTeamPick(team);
                  await repo.saveTeam(updated);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NATIONAL TEAM LIST (shown in Players tab when TEAM filter is active)
// ─────────────────────────────────────────────────────────────────────────────

class _NationalTeamList extends ConsumerWidget {
  const _NationalTeamList({required this.team, required this.leagueId});
  final TeamModel team;
  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(nationalTeamsProvider);
    final repo = ref.read(teamRepositoryProvider);

    return teamsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => Center(child: Text('$e')),
      data: (teams) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Win bonus · +1/goal scored · -1/goal conceded · +5 clean sheet',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: teams.length,
              itemBuilder: (_, i) {
                final t = teams[i];
                final isSelected = team.teamPickId == t.teamId;
                return Card(
                  color: isSelected
                      ? AppColors.secondary.withValues(alpha: 0.15)
                      : AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceVariant,
                      child: Text(t.flagEmoji.isNotEmpty ? t.flagEmoji : '🏳️',
                          style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(t.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: t.group.isNotEmpty
                        ? Text('Group ${t.group}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12))
                        : null,
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.success)
                        : SizedBox(
                            height: 28,
                            child: FilledButton(
                              onPressed: () async {
                                final updated =
                                    repo.setTeamPick(team, t.teamId, t.name);
                                await repo.saveTeam(updated);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Pick',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black)),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCORING GUIDE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ScoringGuideTab extends StatelessWidget {
  const _ScoringGuideTab();

  @override
  Widget build(BuildContext context) {
    final rules = FantasyPoints.allRules;
    final positive = rules.where((r) => r.pts.startsWith('+')).toList();
    final multipliers = rules.where((r) => r.pts.startsWith('×')).toList();
    final negative = rules.where((r) => r.pts.startsWith('-')).toList();
    final dstRules = TeamDefensePoints.dstRules;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Player Points', AppColors.positivePoints),
        ...positive.map((r) => _RuleTile(r)),
        const SizedBox(height: 8),
        _SectionHeader('Captain Bonuses', AppColors.secondary),
        ...multipliers.map((r) => _RuleTile(r)),
        const SizedBox(height: 8),
        _SectionHeader('Deductions', AppColors.negativePoints),
        ...negative.map((r) => _RuleTile(r)),
        const SizedBox(height: 16),
        _SectionHeader('Team Defense (DST)', AppColors.secondary),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Pick 1 national team. Points scored based on their match performance.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        ...dstRules.map((r) => _RuleTile(r)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.color);
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile(this.rule);
  final ({String label, String pts, String note}) rule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              rule.pts,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: rule.pts.startsWith('-')
                    ? AppColors.negativePoints
                    : rule.pts.startsWith('×')
                        ? AppColors.secondary
                        : AppColors.positivePoints,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.label,
                    style: const TextStyle(fontSize: 13)),
                if (rule.note.isNotEmpty)
                  Text(rule.note,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
