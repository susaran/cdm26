import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../data/profile_repository.dart';
import '../domain/user_model.dart';
import '../../auth/presentation/auth_provider.dart';

part 'profile_provider.g.dart';

@riverpod
Stream<UserModel?> currentUserProfile(Ref ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
}
