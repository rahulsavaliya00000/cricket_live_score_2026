import 'package:cricket_live_score/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_pip/fl_pip.dart';
import 'package:cricket_live_score/features/home/presentation/bloc/home_bloc.dart';
import 'package:cricket_live_score/features/matches/domain/entities/match_entity.dart';
import 'package:cricket_live_score/features/profile/presentation/bloc/premium_bloc.dart';
import 'package:cricket_live_score/core/widgets/pip_score_overlay.dart';

class ScaffoldWithNav extends StatefulWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  @override
  State<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends State<ScaffoldWithNav> {
  static const _tabs = ['/home', '/matches', '/series', '/players', '/profile'];
  DateTime? _lastBackPressTime;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final location = GoRouterState.of(context).matchedLocation;

        if (location != '/home') {
          context.go('/home');
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.tapBackToExit),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              width: 200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, homeState) {
          CricketMatch? pipMatch;
          if (homeState.liveMatches.isNotEmpty) {
            pipMatch = homeState.liveMatches.first;
          } else if (homeState.recentMatches.isNotEmpty) {
            pipMatch = homeState.recentMatches.first;
          }

          // Automatically enable/disable PiP based on match availability and route
          // We do this in post-frame to avoid calling it during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final location = GoRouterState.of(context).matchedLocation;
            final premiumState = context.read<PremiumBloc>().state;
            final canPip = premiumState.isPremium || premiumState.isPipTrialActive;

            if (location == '/home') {
              if (pipMatch != null && canPip) {
                FlPiP().enable(
                  android: const FlPiPAndroidConfig(
                    aspectRatio: Rational(16, 9),
                    enabledWhenBackground: true,
                  ),
                  ios: const FlPiPiOSConfig(enabledWhenBackground: true),
                );
              } else {
                FlPiP().disable();
              }
            } else if (_tabs.contains(location) && location != '/home') {
              // If on another main tab, disable PiP from background
              FlPiP().disable();
            }
          });

          return PiPBuilder(
            builder: (statusInfo) {
              if (statusInfo?.status == PiPStatus.enabled && pipMatch != null) {
                return PipScoreOverlay(match: pipMatch);
              }
              // Normal UI
              return Scaffold(
                body: widget.child,
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: BottomNavigationBar(
                      currentIndex: currentIndex,
                      onTap: (index) => context.go(_tabs[index]),
                      items: [
                        _navItem(
                          Icons.home_rounded,
                          Icons.home_outlined,
                          AppLocalizations.of(context)!.home,
                        ),
                        _navItem(
                          Icons.sports_cricket_rounded,
                          Icons.sports_cricket_outlined,
                          AppLocalizations.of(context)!.matches,
                        ),
                        _navItem(
                          Icons.emoji_events_rounded,
                          Icons.emoji_events_outlined,
                          AppLocalizations.of(context)!.series,
                        ),
                        _navItem(
                          Icons.people_rounded,
                          Icons.people_outlined,
                          AppLocalizations.of(context)!.players,
                        ),
                        _navItem(
                          Icons.person_rounded,
                          Icons.person_outlined,
                          AppLocalizations.of(context)!.profile,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  BottomNavigationBarItem _navItem(
    IconData active,
    IconData inactive,
    String label,
  ) {
    return BottomNavigationBarItem(
      activeIcon: Icon(active),
      icon: Icon(inactive),
      label: label,
    );
  }
}
