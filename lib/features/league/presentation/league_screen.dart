import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/league_repository.dart';
import '../domain/league_model.dart';
import 'league_provider.dart';
import 'team_identity_sheet.dart';

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  void _showLeagueActions(BuildContext context, LeagueModel league, String currentUserId) {
    final isAdmin = league.ownerUserId == currentUserId ||
        league.adminUserIds.contains(currentUserId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(league.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  ListTile(
                    leading: const Icon(Icons.leaderboard),
                    title: const Text('Leaderboard'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leagues/${league.leagueId}/leaderboard');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.accent),
                    title: const Text('Messages'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leagues/${league.leagueId}/inbox');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sports_esports),
                    title: const Text('Draft Room'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leagues/${league.leagueId}/draft');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.group),
                    title: const Text('Build Squad'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leagues/${league.leagueId}/team');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text('Trades'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leagues/${league.leagueId}/trades');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sports_soccer),
                    title: const Text('Predictions'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leagues/${league.leagueId}/predictions');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.secondary),
                    title: const Text('Edit Team Name & Badge'),
                    onTap: () {
                      Navigator.pop(context);
                      showTeamIdentitySheet(context, ref, league.leagueId);
                    },
                  ),
                  if (isAdmin) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.image_outlined,
                          color: AppColors.textSecondary),
                      title: const Text('Change League Photo'),
                      onTap: () {
                        Navigator.pop(context);
                        _changeLeaguePhoto(context, league.leagueId);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever,
                          color: AppColors.error),
                      title: const Text('Delete League',
                          style: TextStyle(color: AppColors.error)),
                      onTap: () {
                        Navigator.pop(context);
                        _confirmDelete(context, league);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLeaguePhoto(
      BuildContext context, String leagueId) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (xfile == null) return;
    await ref
        .read(leagueRepositoryProvider)
        .uploadLeagueAvatar(leagueId, File(xfile.path));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('League photo updated')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, LeagueModel league) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete League?'),
        content: Text(
          'You are about to permanently delete "${league.name}".\n\n'
          'All members will be removed and their squads and picks will be lost. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete League'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(leagueRepositoryProvider).deleteLeague(league.leagueId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final leaguesAsync = ref.watch(userLeaguesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leagues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/leagues/create'),
          ),
        ],
      ),
      body: leaguesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (leagues) {
          if (leagues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No leagues yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Create or join a league to start playing',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/leagues/create'),
                    child: const Text('Create League'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/leagues/join'),
                    child: const Text('Join with Code'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leagues.length + 1,
            itemBuilder: (ctx, i) {
              if (i == leagues.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.group_add),
                    label: const Text('Join League with Code'),
                    onPressed: () => context.go('/leagues/join'),
                  ),
                );
              }
              final league = leagues[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    backgroundImage: league.avatarUrl != null
                        ? NetworkImage(league.avatarUrl!)
                        : null,
                    child: league.avatarUrl == null
                        ? Text(league.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(league.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${league.memberCount} members • ${league.status.name}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLeagueActions(context, league, currentUserId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
