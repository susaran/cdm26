import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/matches/domain/player_model.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
    this.isSelected = false,
    this.isCaptain = false,
    this.onTap,
  });

  final PlayerModel player;
  final bool isSelected;
  final bool isCaptain;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _positionColor(player.position),
              backgroundImage:
                  player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
              child: player.photoUrl == null
                  ? Text(player.positionLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))
                  : null,
            ),
            if (isCaptain)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child:
                          Text('C', style: TextStyle(fontSize: 8, color: Colors.black))),
                ),
              ),
          ],
        ),
        title: Text(player.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${player.positionLabel} · ${player.statsSummary.totalFantasyPoints} pts',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              player.fantasyPrice.toStringAsFixed(1),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.success, size: 16)
            else if (onTap != null)
              const Icon(Icons.add_circle_outline, size: 16),
          ],
        ),
        onTap: isSelected ? null : onTap,
      ),
    );
  }

  Color _positionColor(PlayerPosition pos) => switch (pos) {
        PlayerPosition.gk => AppColors.gkColor,
        PlayerPosition.def => AppColors.defColor,
        PlayerPosition.mid => AppColors.midColor,
        PlayerPosition.fwd => AppColors.fwdColor,
      };
}
