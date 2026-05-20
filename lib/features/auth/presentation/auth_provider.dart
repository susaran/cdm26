import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<User?> authState(Ref ref) {
  return ref.watch(authServiceProvider).authStateChanges;
}
