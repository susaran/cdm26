import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;
import 'package:uuid/uuid.dart';

import '../domain/user_model.dart';

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) => ProfileRepository();

class ProfileRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');

  Future<void> createProfile({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final username = _generateUsername(displayName);
    final user = UserModel(
      userId: userId,
      email: email,
      displayName: displayName,
      username: username,
      createdAt: DateTime.now(),
    );
    await _users.doc(userId).set(user.toMap());
  }

  Future<UserModel?> getProfile(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> watchProfile(String userId) {
    return _users.doc(userId).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }

  Future<void> updateProfile(UserModel user) async {
    await _users.doc(user.userId).update(user.toMap());
  }

  Future<void> updatePhoto(String userId, String photoUrl) async {
    await _users.doc(userId).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _generateUsername(String displayName) {
    final base = displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final suffix = const Uuid().v4().substring(0, 4);
    return '$base$suffix';
  }
}
