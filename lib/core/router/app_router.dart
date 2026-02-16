import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cricketbuzz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cricketbuzz/features/auth/presentation/pages/login_page.dart';
import 'package:cricketbuzz/features/auth/presentation/pages/guest_name_page.dart';
import 'package:cricketbuzz/features/home/presentation/pages/home_page.dart';
import 'package:cricketbuzz/features/matches/presentation/pages/matches_page.dart';
import 'package:cricketbuzz/features/matches/presentation/pages/match_detail_page.dart';
import 'package:cricketbuzz/features/players/presentation/pages/players_page.dart';
import 'package:cricketbuzz/features/players/presentation/pages/player_detail_page.dart';
import 'package:cricketbuzz/features/series/presentation/pages/series_page.dart';
import 'package:cricketbuzz/features/series/presentation/pages/series_detail_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/profile_page.dart';
import 'package:cricketbuzz/features/settings/presentation/pages/settings_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/privacy_policy_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/terms_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/premium_page.dart';
import 'package:cricketbuzz/features/browser/presentation/pages/browser_page.dart';
import 'package:cricketbuzz/core/widgets/scaffold_with_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnLogin =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/guest-name';

      if (authState is Unauthenticated && !isOnLogin) {
        return '/login';
      }
      if (authState is Authenticated && isOnLogin) {
        return '/home';
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/guest-name',
        builder: (context, state) => const GuestNamePage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/matches',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MatchesPage()),
          ),
          GoRoute(
            path: '/series',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SeriesPage()),
          ),
          GoRoute(
            path: '/players',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlayersPage()),
          ),
          GoRoute(
            path: '/browser',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BrowserPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
      GoRoute(
        path: '/match/:id',
        builder: (context, state) =>
            MatchDetailPage(matchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/player/:id',
        builder: (context, state) =>
            PlayerDetailPage(playerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/series-detail/:id',
        builder: (context, state) =>
            SeriesDetailPage(seriesId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(path: '/terms', builder: (context, state) => const TermsPage()),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumPage(),
      ),
    ],
  );
}

// Helper to refresh GoRouter on BLoC state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
