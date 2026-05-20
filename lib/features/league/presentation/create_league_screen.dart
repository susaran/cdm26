import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../profile/presentation/profile_provider.dart';
import '../data/league_repository.dart';

class CreateLeagueScreen extends ConsumerStatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  ConsumerState<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends ConsumerState<CreateLeagueScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  int _maxMembers = 20;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _prizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      if (user == null) return;

      final league = await ref.read(leagueRepositoryProvider).createLeague(
            ownerUserId: user.uid,
            ownerDisplayName: profile?.displayName ?? 'Unknown',
            ownerPhotoUrl: profile?.photoUrl,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            maxMembers: _maxMembers,
            prizeDescription: _prizeCtrl.text.trim().isEmpty
                ? null
                : _prizeCtrl.text.trim(),
          );

      if (mounted) {
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
      appBar: AppBar(title: const Text('Create League')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppTextField(
              controller: _nameCtrl,
              label: 'League Name',
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter a league name' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descCtrl,
              label: 'Description (optional)',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _prizeCtrl,
              label: 'Prize Notes (optional)',
              hint: 'e.g. \$20 buy-in, winner takes all',
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Max Members'),
                DropdownButton<int>(
                  value: _maxMembers,
                  items: [5, 10, 15, 20, 30, 50]
                      .map((n) => DropdownMenuItem(
                            value: n,
                            child: Text('$n'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _maxMembers = v ?? 20),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Create League',
              loading: _loading,
              onPressed: _create,
            ),
          ],
        ),
      ),
    );
  }
}
