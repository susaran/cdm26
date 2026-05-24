import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';

class CDM26App extends ConsumerStatefulWidget {
  const CDM26App({super.key});

  @override
  ConsumerState<CDM26App> createState() => _CDM26AppState();
}

class _CDM26AppState extends ConsumerState<CDM26App> {
  bool _fcmInitDone = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // Init FCM once the user is authenticated
    ref.listen(authStateProvider, (_, next) {
      if (!_fcmInitDone && next.valueOrNull != null) {
        _fcmInitDone = true;
        ref.read(fcmServiceProvider).init();
      }
    });
    return MaterialApp.router(
      title: 'CDM 2026',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
