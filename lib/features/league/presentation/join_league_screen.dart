import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../profile/presentation/profile_provider.dart';
import '../data/league_repository.dart';

class JoinLeagueScreen extends ConsumerStatefulWidget {
  const JoinLeagueScreen({super.key});

  @override
  ConsumerState<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends ConsumerState<JoinLeagueScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      if (user == null) return;

      final league = await ref.read(leagueRepositoryProvider).joinByCode(
            _codeCtrl.text.trim(),
            user.uid,
            profile?.displayName ?? 'Unknown',
            profile?.photoUrl,
          );

      if (mounted && league != null) {
        context.go('/leagues/${league.leagueId}/leaderboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join League')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the invite code your friend shared',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _codeCtrl,
              label: 'Invite Code',
              hint: 'e.g. A7K9Q2',
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Join League',
              loading: _loading,
              onPressed: _join,
            ),
          ],
        ),
      ),
    );
  }
}
