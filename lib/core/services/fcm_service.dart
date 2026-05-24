import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/profile/data/profile_repository.dart';

part 'fcm_service.g.dart';

@riverpod
FcmService fcmService(Ref ref) => FcmService(ref);

class FcmService {
  FcmService(this._ref);
  final Ref _ref;

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) await _storeToken(token);

    // Refresh token whenever it rotates
    messaging.onTokenRefresh.listen(_storeToken);
  }

  Future<void> _storeToken(String token) async {
    final userId = _ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    await _ref.read(profileRepositoryProvider).updateFcmToken(userId, token);
  }
}
