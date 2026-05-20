import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../matches/domain/player_model.dart';
import '../domain/team_model.dart';

part 'team_repository.g.dart';

@riverpod
TeamRepository teamRepository(Ref ref) => TeamRepository();

class TeamRepository {
  final _db = FirebaseFirestore.instance;

  DocumentReference _teamDoc(String leagueId, String userId) =>
      _db.collection('leagues').doc(leagueId).collection('teams').doc(userId);

  Stream<TeamModel?> watchTeam(String leagueId, String userId) {
    return _teamDoc(leagueId, userId).snapshots().map(
          (doc) => doc.exists ? TeamModel.fromFirestore(doc) : null,
        );
  }

  Future<void> saveTeam(TeamModel team) async {
    final errors = _validateTeam(team);
    final validated = team.copyWith(
      validation: TeamValidation(isValid: errors.isEmpty, errors: errors),
    );
    await _teamDoc(team.leagueId, team.userId).set(validated.toMap());
  }

  Future<void> submitTeam(TeamModel team) async {
    final errors = _validateTeam(team);
    if (errors.isNotEmpty) throw TeamException(errors.first);
    final submitted = team.copyWith(
      status: TeamStatus.submitted,
      validation: const TeamValidation(isValid: true),
    );
    await _teamDoc(team.leagueId, team.userId).set({
      ...submitted.toMap(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  // Returns whether a player of the given position can still be added.
  bool canAddPosition(TeamModel team, String positionLabel) {
    return switch (positionLabel) {
      'GK' => team.gkCount < kRequiredGK,
      'DEF' => team.defCount < kRequiredDEF,
      'MID' => team.midCount < kRequiredMID,
      'FWD' => team.fwdCount < kRequiredFWD,
      _ => false,
    };
  }

  TeamModel addPlayer(TeamModel team, PlayerModel player) {
    if (team.players.any((p) => p.playerId == player.playerId)) {
      throw const TeamException('Player already in squad.');
    }
    if (team.players.length >= kSquadTotal) {
      throw const TeamException('Squad is full (15 players).');
    }
    if (!canAddPosition(team, player.positionLabel)) {
      throw TeamException('Position quota full for ${player.positionLabel}.');
    }
    if (team.budgetRemaining < player.fantasyPrice) {
      throw const TeamException('Not enough budget.');
    }

    // Enforce max 3 players per country
    if (player.countryCode.isNotEmpty) {
      final countryCount = team.players
          .where((p) => p.countryCode == player.countryCode)
          .length;
      if (countryCount >= AppConstants.maxPlayersPerCountry) {
        throw TeamException(
            'Max ${AppConstants.maxPlayersPerCountry} players from same country.');
      }
    }

    // First starter slot; overflow goes to bench
    final isStarter = _starterCountForPosition(team, player.positionLabel) <
        _maxStartersForPosition(player.positionLabel);

    final slot = TeamPlayerSlot(
      playerId: player.playerId,
      position: player.positionLabel,
      purchasePrice: player.fantasyPrice,
      displayName: player.displayName,
      teamName: player.teamName,
      countryCode: player.countryCode,
      photoUrl: player.photoUrl,
      slot: isStarter ? 'starter' : 'bench',
    );

    return team.copyWith(
      players: [...team.players, slot],
      budgetUsed: team.budgetUsed + player.fantasyPrice,
    );
  }

  TeamModel removePlayer(TeamModel team, String playerId) {
    final slot = team.players.firstWhere(
      (p) => p.playerId == playerId,
      orElse: () => throw const TeamException('Player not in squad.'),
    );
    final newPlayers =
        team.players.where((p) => p.playerId != playerId).toList();
    final captainId =
        team.captainPlayerId == playerId ? null : team.captainPlayerId;
    final vcId = team.viceCaptainPlayerId == playerId
        ? null
        : team.viceCaptainPlayerId;
    return team.copyWith(
      players: newPlayers,
      budgetUsed: team.budgetUsed - slot.purchasePrice,
      captainPlayerId: captainId,
      viceCaptainPlayerId: vcId,
    );
  }

  TeamModel setTeamPick(TeamModel team, String teamId, String teamName) {
    return team.copyWith(teamPickId: teamId, teamPickName: teamName);
  }

  TeamModel removeTeamPick(TeamModel team) {
    return team.copyWith(teamPickId: null, teamPickName: null);
  }

  TeamModel setCaptain(TeamModel team, String playerId) {
    if (team.viceCaptainPlayerId == playerId) {
      return team.copyWith(captainPlayerId: playerId, viceCaptainPlayerId: null);
    }
    return team.copyWith(captainPlayerId: playerId);
  }

  TeamModel setViceCaptain(TeamModel team, String playerId) {
    if (team.captainPlayerId == playerId) {
      return team.copyWith(captainPlayerId: null, viceCaptainPlayerId: playerId);
    }
    return team.copyWith(viceCaptainPlayerId: playerId);
  }

  TeamModel toggleBench(TeamModel team, String playerId) {
    final updated = team.players.map((p) {
      if (p.playerId != playerId) return p;
      return p.copyWith(slot: p.isBench ? 'starter' : 'bench');
    }).toList();
    return team.copyWith(players: updated);
  }

  List<String> _validateTeam(TeamModel team) {
    final errors = <String>[];

    if (team.gkCount < kRequiredGK) {
      errors.add('Need ${kRequiredGK - team.gkCount} more GK.');
    }
    if (team.defCount < kRequiredDEF) {
      errors.add('Need ${kRequiredDEF - team.defCount} more DEF.');
    }
    if (team.midCount < kRequiredMID) {
      errors.add('Need ${kRequiredMID - team.midCount} more MID.');
    }
    if (team.fwdCount < kRequiredFWD) {
      errors.add('Need ${kRequiredFWD - team.fwdCount} more FWD.');
    }
    if (team.captainPlayerId == null) {
      errors.add('Set a captain.');
    }
    if (team.teamPickId == null) {
      errors.add('Pick a national team (DST slot).');
    }
    if (team.budgetUsed > team.budgetLimit) {
      errors.add('Budget exceeded.');
    }

    final countryCount = <String, int>{};
    for (final p in team.players) {
      if (p.countryCode.isNotEmpty) {
        countryCount[p.countryCode] = (countryCount[p.countryCode] ?? 0) + 1;
      }
    }
    for (final entry in countryCount.entries) {
      if (entry.value > AppConstants.maxPlayersPerCountry) {
        errors.add('Max ${AppConstants.maxPlayersPerCountry} players per country (${entry.key}).');
      }
    }

    return errors;
  }

  int _starterCountForPosition(TeamModel team, String pos) =>
      team.players.where((p) => p.position == pos && p.isStarter).length;

  int _maxStartersForPosition(String pos) => switch (pos) {
        'GK' => 1,
        'DEF' => 4,
        'MID' => 4,
        'FWD' => 2,
        _ => 0,
      };
}
