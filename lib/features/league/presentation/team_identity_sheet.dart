import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/league_repository.dart';
import '../domain/league_member_model.dart';

Future<void> showTeamIdentitySheet(
    BuildContext context, WidgetRef ref, String leagueId,
    {LeagueMemberModel? current}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TeamIdentitySheet(
      leagueId: leagueId,
      ref: ref,
      current: current,
    ),
  );
}

class _TeamIdentitySheet extends StatefulWidget {
  const _TeamIdentitySheet(
      {required this.leagueId, required this.ref, this.current});
  final String leagueId;
  final WidgetRef ref;
  final LeagueMemberModel? current;

  @override
  State<_TeamIdentitySheet> createState() => _TeamIdentitySheetState();
}

class _TeamIdentitySheetState extends State<_TeamIdentitySheet> {
  late final TextEditingController _nameCtrl;
  File? _pickedImage;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.current?.teamName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (xfile != null) setState(() => _pickedImage = File(xfile.path));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Team name cannot be empty.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });

    final userId =
        widget.ref.read(authStateProvider).valueOrNull?.uid ?? '';
    final repo = widget.ref.read(leagueRepositoryProvider);

    String? badgeUrl = widget.current?.teamBadgeUrl;
    if (_pickedImage != null) {
      badgeUrl =
          await repo.uploadTeamBadge(widget.leagueId, userId, _pickedImage!);
    }

    await repo.updateTeamIdentity(widget.leagueId, userId, name,
        teamBadgeUrl: badgeUrl);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Team Identity',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            // Badge picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!) as ImageProvider
                        : widget.current?.teamBadgeUrl != null
                            ? NetworkImage(widget.current!.teamBadgeUrl!)
                            : null,
                    child: (_pickedImage == null &&
                            widget.current?.teamBadgeUrl == null)
                        ? const Icon(Icons.shield,
                            size: 40, color: Colors.white54)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to change badge',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            // Team name field
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Team Name',
                hintText: 'e.g. Los Galácticos FC',
                errorText: _error,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon:
                    const Icon(Icons.emoji_events, color: AppColors.secondary),
              ),
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _uploading ? null : _save,
                child: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Team Identity'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
