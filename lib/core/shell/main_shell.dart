import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/chat/presentation/chat_provider.dart';
import '../../features/league/presentation/league_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    // Sum unread across all leagues the user belongs to
    final leagues = ref.watch(userLeaguesProvider).valueOrNull ?? [];
    int totalUnread = 0;
    for (final l in leagues) {
      final count = ref
          .watch(leagueUnreadCountProvider(l.leagueId, userId))
          .valueOrNull ?? 0;
      totalUnread += count;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) => _onTap(context, i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: totalUnread > 0
                ? Badge(
                    label: Text('$totalUnread'),
                    child: const Icon(Icons.emoji_events),
                  )
                : const Icon(Icons.emoji_events),
            label: 'Leagues',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/leagues')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/fixtures');
      case 1:
        context.go('/leagues');
      case 2:
        context.go('/profile');
    }
  }
}
