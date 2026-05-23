import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/league_member_model.dart';
import '../domain/league_model.dart';

part 'league_repository.g.dart';

@riverpod
LeagueRepository leagueRepository(Ref ref) => LeagueRepository();

class LeagueRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _leagues => _db.collection('leagues');

  Future<LeagueModel> createLeague({
    required String ownerUserId,
    required String ownerDisplayName,
    String? ownerPhotoUrl,
    required String name,
    String? description,
    int maxMembers = 20,
    String? prizeDescription,
  }) async {
    final leagueId = const Uuid().v4();
    final inviteCode = _generateInviteCode();

    final league = LeagueModel(
      leagueId: leagueId,
      name: name,
      description: description,
      ownerUserId: ownerUserId,
      adminUserIds: [ownerUserId],
      tournamentId: 'wc_2026',
      inviteCode: inviteCode,
      maxMembers: maxMembers,
      prizeDescription: prizeDescription,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();

    batch.set(_leagues.doc(leagueId), league.toMap());

    final member = LeagueMemberModel(
      userId: ownerUserId,
      leagueId: leagueId,
      displayName: ownerDisplayName,
      photoUrl: ownerPhotoUrl,
      role: MemberRole.owner,
      joinedAt: DateTime.now(),
    );
    batch.set(
        _leagues.doc(leagueId).collection('members').doc(ownerUserId),
        member.toMap());

    await batch.commit();
    return league;
  }

  Future<LeagueModel?> joinByCode(String inviteCode, String userId,
      String displayName, String? photoUrl) async {
    final query = await _leagues
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .where('inviteLinkEnabled', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw const LeagueException('Invalid invite code.');

    final league = LeagueModel.fromFirestore(query.docs.first);

    if (league.memberCount >= league.maxMembers) {
      throw const LeagueException('This league is full.');
    }
    if (league.status != LeagueStatus.setup && !league.settings.allowLateJoin) {
      throw const LeagueException('This league is no longer accepting members.');
    }

    final memberRef =
        _leagues.doc(league.leagueId).collection('members').doc(userId);
    final existing = await memberRef.get();
    if (existing.exists) throw const LeagueException('Already a member.');

    final batch = _db.batch();
    final member = LeagueMemberModel(
      userId: userId,
      leagueId: league.leagueId,
      displayName: displayName,
      photoUrl: photoUrl,
      joinedAt: DateTime.now(),
    );
    batch.set(memberRef, member.toMap());
    batch.update(_leagues.doc(league.leagueId),
        {'memberCount': FieldValue.increment(1)});

    await batch.commit();
    return league;
  }

  Stream<List<LeagueModel>> watchUserLeagues(String userId) {
    return _db
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snap) async {
      final leagueIds = snap.docs.map((d) => d['leagueId'] as String).toList();
      if (leagueIds.isEmpty) return [];
      final futures = leagueIds.map((id) => _leagues.doc(id).get());
      final docs = await Future.wait(futures);
      return docs
          .where((d) => d.exists)
          .map((d) => LeagueModel.fromFirestore(d))
          .toList();
    });
  }

  Stream<List<LeagueMemberModel>> watchLeagueMembers(String leagueId) {
    return _leagues
        .doc(leagueId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => LeagueMemberModel.fromFirestore(d)).toList());
  }

  Future<LeagueModel?> getLeague(String leagueId) async {
    final doc = await _leagues.doc(leagueId).get();
    if (!doc.exists) return null;
    return LeagueModel.fromFirestore(doc);
  }

  Future<void> deleteLeague(String leagueId) async {
    final leagueRef = _leagues.doc(leagueId);
    final membersSnap = await leagueRef.collection('members').get();
    final batch = _db.batch();
    for (final doc in membersSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(leagueRef);
    await batch.commit();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(
        6, (i) => chars[(random >> (i * 5)) % chars.length]).join();
  }
}
