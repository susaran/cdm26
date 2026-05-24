import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/profile_repository.dart';
import 'profile_provider.dart';

const _kPrivacyPolicyUrl = 'https://yoursite.com/privacy';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (xfile == null) return;

    final userId =
        ref.read(authStateProvider).valueOrNull?.uid ?? '';
    if (userId.isEmpty) return;

    setState(() => _uploadingPhoto = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .uploadProfilePhoto(userId, File(xfile.path));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all data — '
          'including your teams, predictions, and league history.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref.read(authServiceProvider).deleteAccount();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not delete account. Please sign out and back in, then try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, x) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No profile found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tappable avatar
              Center(
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : _changeProfilePhoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: _uploadingPhoto
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : user.photoUrl == null
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 36, color: Colors.white),
                                  )
                                : null,
                      ),
                      if (!_uploadingPhoto)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.background, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tap to change photo',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(user.displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Center(
                child: Text('@${user.username}',
                    style: const TextStyle(
                        color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 32),
              _StatsRow(stats: [
                ('Leagues Joined',
                    user.stats.leaguesJoined.toString()),
                ('Leagues Won', user.stats.leaguesWon.toString()),
                ('Exact Scores', user.stats.exactScores.toString()),
              ]),
              const SizedBox(height: 16),
              _StatsRow(stats: [
                ('Fantasy Pts',
                    user.stats.totalFantasyPoints.toString()),
                ('Prediction Pts',
                    user.stats.totalPredictionPoints.toString()),
                ('Correct Results',
                    user.stats.correctResults.toString()),
              ]),
              const SizedBox(height: 32),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined,
                    color: AppColors.textSecondary),
                title: const Text('Privacy Policy'),
                onTap: () async {
                  final uri = Uri.parse(_kPrivacyPolicyUrl);
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever,
                    color: AppColors.error),
                title: const Text('Delete Account',
                    style: TextStyle(color: AppColors.error)),
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(s.$2,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary)),
                        const SizedBox(height: 4),
                        Text(s.$1,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
