import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/league/presentation/create_league_screen.dart';
import '../../features/league/presentation/join_league_screen.dart';
import '../../features/league/presentation/league_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/matches/presentation/fixtures_screen.dart';
import '../../features/matches/presentation/match_center_screen.dart';
import '../../features/predictions/presentation/predictions_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/team_builder/presentation/team_builder_screen.dart';
import '../shell/main_shell.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null; // always allow splash through

      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = loc.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/fixtures';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/fixtures',
            builder: (_, __) => const FixturesScreen(),
            routes: [
              GoRoute(
                path: 'match/:matchId',
                builder: (_, state) =>
                    MatchCenterScreen(matchId: state.pathParameters['matchId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/leagues',
            builder: (_, __) => const LeagueScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateLeagueScreen(),
              ),
              GoRoute(
                path: 'join',
                builder: (_, __) => const JoinLeagueScreen(),
              ),
              GoRoute(
                path: ':leagueId/leaderboard',
                builder: (_, state) => LeaderboardScreen(
                    leagueId: state.pathParameters['leagueId']!),
              ),
              GoRoute(
                path: ':leagueId/team',
                builder: (_, state) => TeamBuilderScreen(
                    leagueId: state.pathParameters['leagueId']!),
              ),
              GoRoute(
                path: ':leagueId/predictions',
                builder: (_, state) => PredictionsScreen(
                    leagueId: state.pathParameters['leagueId']!),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
