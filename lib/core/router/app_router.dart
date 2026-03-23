import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';

import 'package:cricketbuzz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cricketbuzz/features/auth/presentation/pages/guest_name_page.dart';
import 'package:cricketbuzz/features/home/presentation/pages/home_page.dart';
import 'package:cricketbuzz/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:cricketbuzz/features/matches/presentation/pages/matches_page.dart';
import 'package:cricketbuzz/features/matches/presentation/pages/match_detail_page.dart';
import 'package:cricketbuzz/features/players/presentation/pages/players_page.dart';
import 'package:cricketbuzz/features/players/presentation/pages/player_detail_page.dart';
import 'package:cricketbuzz/features/players/presentation/pages/team_players_page.dart';
import 'package:cricketbuzz/features/players/presentation/pages/ipl_squads_page.dart';
import 'package:cricketbuzz/features/series/presentation/pages/series_page.dart';
import 'package:cricketbuzz/features/series/presentation/pages/series_detail_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/profile_page.dart';
import 'package:cricketbuzz/features/settings/presentation/pages/settings_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/privacy_policy_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/terms_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/premium_page.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/suggestion_page.dart';
import 'package:cricketbuzz/core/widgets/scaffold_with_nav.dart';
import 'package:cricketbuzz/features/wallet/presentation/pages/spin_wheel_page.dart';
import 'package:cricketbuzz/features/wallet/presentation/pages/wallet_page.dart';
import 'package:cricketbuzz/features/wallet/presentation/pages/leaderboard_page.dart';
import 'package:cricketbuzz/features/ugc/presentation/pages/ugc_feed_page.dart';
import 'package:cricketbuzz/features/ugc/presentation/pages/create_post_page.dart';
import 'package:cricketbuzz/features/ugc/presentation/cubit/ugc_cubit.dart';
import 'package:cricketbuzz/core/services/analytics_service.dart';
import 'package:cricketbuzz/core/di/injection_container.dart';
import 'package:cricketbuzz/features/profile/presentation/pages/ad_debug_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc, bool hasSeenOnboarding) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: hasSeenOnboarding ? '/home' : '/onboarding',
    observers: [AnalyticsService.instance.observer],
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnLogin = state.matchedLocation == '/guest-name';

      if (authState is Authenticated && isOnLogin) {
        return '/home';
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

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
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
          GoRoute(
            path: '/spin-wheel',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SpinWheelPage()),
          ),
          GoRoute(
            path: '/wallet',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WalletPage()),
          ),
          GoRoute(
            path: '/leaderboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LeaderboardPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/match/:id',
        builder: (context, state) => MatchDetailPage(
          matchId: state.pathParameters['id']!,
          previewMatch: state.extra as CricketMatch?,
        ),
      ),
      GoRoute(
        path: '/player/:id/:slug',
        builder: (context, state) => PlayerDetailPage(
          playerId: state.pathParameters['id']!,
          playerSlug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/series-detail/:id',
        builder: (context, state) =>
            SeriesDetailPage(seriesId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/team-players/:slug/:id',
        builder: (context, state) => TeamPlayersPage(
          teamSlug: state.pathParameters['slug']!,
          teamId: state.pathParameters['id']!,
          teamName: (state.extra as String?) ?? 'Team',
        ),
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
      GoRoute(
        path: '/suggestion',
        builder: (context, state) => const SuggestionPage(),
      ),
      GoRoute(
        path: '/ugc-feed',
        builder: (context, state) => BlocProvider<UGCCubit>(
          create: (_) => sl<UGCCubit>(),
          child: const UGCFeedPage(),
        ),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreatePostPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/ad-debug',
        builder: (context, state) => const AdDebugPage(),
      ),
      GoRoute(
        path: '/ipl-squads',
        builder: (context, state) => const IplSquadsPage(),
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
