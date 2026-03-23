import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/constants/app_constants.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';

import 'package:cricketbuzz/l10n/app_localizations.dart';
import 'package:cricketbuzz/features/home/presentation/bloc/home_bloc.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/core/services/notification_service.dart';
import 'package:cricketbuzz/core/widgets/team_flag.dart';
import 'package:cricketbuzz/core/widgets/native_ad_widget.dart';
import 'package:cricketbuzz/features/wallet/presentation/widgets/wallet_chip.dart';
import 'package:cricketbuzz/features/wallet/presentation/widgets/spinning_fab.dart';
import 'package:cricketbuzz/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:cricketbuzz/features/profile/presentation/bloc/premium_bloc.dart';
import 'package:cricketbuzz/features/home/presentation/widgets/live_feed_button.dart';
import 'package:cricketbuzz/features/home/presentation/widgets/ipl_schedule_button.dart';
import 'package:cricketbuzz/core/services/remote_config_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _autoRefreshTimer;
  Timer? _retentionTimer;
  late PageController _pageController;
  late ScrollController _scrollController;
  MatchCategory _selectedCategory = MatchCategory.all;
  bool _showRetentionPrompt = false;
  bool _isTourRunning = false;
  String _tourMessage = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _scrollController = ScrollController();
    context.read<HomeBloc>().add(LoadHomeData());
    _requestNotificationPermissions();
    _startAutoRefresh();
    _startRetentionTimer();
    _checkAndStartTour();
  }

  Future<void> _checkAndStartTour() async {
    // skip_tour: true → never show, not even once
    if (AppConstants.devSkipAppTour) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool(AppConstants.hasSeenAppTourKey) ?? false;

    // skip_tour: false → show exactly once (first time user reaches home)
    if (!hasSeenTour) {
      // Small delay to ensure data is loaded/shimmer is gone
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _startAppTour();
      });
    }
  }

  Future<void> _startAppTour() async {
    if (!mounted) return;
    final random = Random();

    setState(() {
      _isTourRunning = true;
      _tourMessage = 'Welcome to CricketBuzz! Let\'s explore the matches...';
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Perform a sequence of 4-6 randomized "human-like" moves
    final numMoves = random.nextInt(3) + 4; // 4 to 6 moves

    for (int i = 0; i < numMoves; i++) {
      if (!mounted) return;

      // 30% chance to do a carousel swipe if near the top
      if (_scrollController.offset < 500 && random.nextDouble() < 0.3) {
        await _performRandomCarouselSwipes();
      } else {
        // Vertical movement
        double distance = (random.nextInt(400) + 200).toDouble();

        // 30% chance to go UP instead of DOWN (if we have room)
        bool goUp = _scrollController.offset > 300 && random.nextDouble() < 0.3;
        if (goUp) distance = -distance;

        await _performHumanSwipe(distance);

        // Update message occasionally
        if (i == 1) {
          setState(
            () => _tourMessage =
                'Check out the Live Matches and Series highlights!',
          );
        }
        if (i == 3) {
          setState(
            () => _tourMessage =
                'Explore upcoming series and match results below.',
          );
        }
      }

      // Random delay between moves
      await Future.delayed(Duration(milliseconds: 800 + random.nextInt(700)));
    }

    if (!mounted) return;
    setState(
      () => _tourMessage = 'Almost done! Let\'s check your daily rewards...',
    );
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    // Mark as seen (ignored in testing mode) and navigate
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasSeenAppTourKey, true);

    setState(() => _isTourRunning = false);
    AdHelper.showInterstitialAd(() {
      context.push('/spin-wheel?fromTour=true');
    });
  }

  Future<void> _performHumanSwipe(double distance) async {
    if (!mounted) return;
    final currentOffset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetOffset = (currentOffset + distance).clamp(0.0, maxScroll);

    await _scrollController.animateTo(
      targetOffset,
      duration: Duration(milliseconds: 1200 + (distance % 5 * 100).toInt()),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _performRandomCarouselSwipes() async {
    if (!mounted || !_pageController.hasClients) return;
    final random = Random();

    // Decide if we should skip carousel swiping entirely (30% chance)
    if (random.nextDouble() < 0.3) return;

    final numSwipes = random.nextInt(2) + 1; // 1 to 2 swipes
    for (int i = 0; i < numSwipes; i++) {
      if (!mounted) return;

      // 20% chance to "don't scroll" for a moment
      if (random.nextDouble() < 0.2) {
        await Future.delayed(const Duration(milliseconds: 1000));
        continue;
      }

      final currentPage = _pageController.page?.round() ?? 0;
      final nextPage =
          currentPage + (random.nextBool() ? 1 : 2); // Swipe 1 or 2 cards

      await _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
      );
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  void _startRetentionTimer() {
    // Initial prompt after 2 minutes
    _retentionTimer = Timer(const Duration(minutes: 2), () {
      _checkAndShowRetentionPrompt();

      // Subsequent prompts every 7 minutes
      _retentionTimer?.cancel();
      _retentionTimer = Timer.periodic(const Duration(minutes: 7), (timer) {
        _checkAndShowRetentionPrompt();
      });
    });
  }

  void _checkAndShowRetentionPrompt() {
    if (!AppConstants.devShowWalletUI) return; // Wallet/spin UI hidden — skip
    if (mounted && !_showRetentionPrompt) {
      final walletState = context.read<WalletCubit>().state;
      if (walletState.canSpinFree) {
        setState(() => _showRetentionPrompt = true);
      }
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _retentionTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 5 seconds
    print('🔄 Auto-refresh timer started - will refresh every 5 seconds');
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        print('🔄 Auto-refresh triggered at ${DateTime.now()}');
        context.read<HomeBloc>().add(RefreshHomeData());
      } else {
        print('⚠️ Widget not mounted, canceling timer');
        timer.cancel();
      }
    });
  }

  Future<void> _requestNotificationPermissions() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    final notificationService = NotificationService();
    final granted = await notificationService.requestAndCheckPermissions();

    if (granted && mounted) {
      // Permission just granted — immediately show sticky spin notification
      // if the user hasn't spun today.
      if (AppConstants.devShowWalletUI) {
        final canSpin = context.read<WalletCubit>().state.canSpinFree;
        if (canSpin) {
          notificationService.showStickySpinNotification();
        }
      }
    } else if (!granted && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Enable Notifications 🔔',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Stay updated with live match scores and daily cricket alerts! Please enable notifications in your device settings.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Later',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                notificationService.openAppSettings();
              },
              child: Text(
                'Open Settings',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  List<CricketMatch> _filter(List<CricketMatch> matches, {bool alwaysShowIpl = false}) {
    if (_selectedCategory == MatchCategory.all) return matches;
    return matches.where((m) {
      if (alwaysShowIpl && m.format == MatchFormat.ipl) return true;
      return _selectedCategory.matches(m);
    }).toList();
  }

  /// Sort live matches: IPL first, then T20/T20I, then ODI, then everything else.
  List<CricketMatch> _sortByFormatPriority(List<CricketMatch> matches) {
    if (matches.length <= 1) return matches;
    int priority(MatchFormat f) {
      switch (f) {
        case MatchFormat.ipl:
          return -1; // absolute highest priority
        case MatchFormat.t20i:
        case MatchFormat.t20:
          return 0;
        case MatchFormat.odi:
          return 1;
        default:
          return 2;
      }
    }

    return List<CricketMatch>.from(matches)
      ..sort((a, b) => priority(a.format).compareTo(priority(b.format)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (AppConstants.showAdInspector)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton(
                heroTag: 'ad_inspector_fab',
                onPressed: () => context.push('/ad-debug'),
                backgroundColor: Colors.orange.shade700,
                child: const Icon(Icons.bug_report, color: Colors.white),
              ),
            ),
          if (AppConstants.devShowWalletUI) const SpinningFAB(),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state.status == HomeStatus.loading &&
                    state.liveMatches.isEmpty) {
                  return const ListShimmer(itemCount: 4);
                }
                if (state.status == HomeStatus.error &&
                    state.liveMatches.isEmpty) {
                  return ErrorView(
                    message: state.error ?? 'Failed to load data',
                    onRetry: () => context.read<HomeBloc>().add(LoadHomeData()),
                  );
                }

                // Apply filters
                final liveMatches = _sortByFormatPriority(
                  _filter(state.liveMatches, alwaysShowIpl: true),
                );
                final upcomingMatches = _filter(state.upcomingMatches);
                final recentMatches = _filter(state.recentMatches);
                final isPremium = context.read<PremiumBloc>().state.isPremium;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeBloc>().add(RefreshHomeData());
                    await Future.delayed(const Duration(seconds: 5));
                  },
                  color: AppColors.primaryGreen,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // ─── App Bar ─────────────────────
                      SliverAppBar(
                        floating: false,
                        pinned: true,
                        centerTitle: false,
                        title: PopupMenuButton<MatchCategory>(
                          useRootNavigator: true,
                          onSelected: (category) {
                            AdHelper.showInterstitialAd(() {
                              setState(() => _selectedCategory = category);
                            });
                          },
                          itemBuilder: (context) => MatchCategory.values
                              .map(
                                (cat) => PopupMenuItem(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      if (_selectedCategory == cat)
                                        const Icon(
                                          Icons.check_rounded,
                                          color: AppColors.primaryGreen,
                                          size: 18,
                                        )
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        cat.label,
                                        style: GoogleFonts.poppins(
                                          fontWeight: _selectedCategory == cat
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _selectedCategory == cat
                                              ? AppColors.primaryGreen
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sports_cricket_rounded,
                                  color: AppColors.primaryGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'CricketBuzz',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 20,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                        ),
                                      ],
                                    ),
                                    if (_selectedCategory != MatchCategory.all)
                                      Text(
                                        _selectedCategory.label,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    else if (state.isRefreshing)
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.updatingScores,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          if (AppConstants.devShowWalletUI) const WalletChip(),
                          IconButton(
                            onPressed: () {
                              AdHelper.showInterstitialAd(() {
                                context.push('/settings');
                              });
                            },
                            icon: const Icon(Icons.settings_outlined, size: 22),
                          ),
                        ],
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(2),
                          child: state.isRefreshing
                              ? const LinearProgressIndicator(
                                  minHeight: 2,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGreen,
                                  ),
                                )
                              : const SizedBox(height: 2),
                        ),
                      ),

                      // ─── Live Feed Button ────────────
                      if (RemoteConfigService.instance.devShowLiveFeedButton)
                        const SliverToBoxAdapter(child: LiveFeedButton()),

                      // ─── IPL Schedule Button ──────────
                      const SliverToBoxAdapter(child: IplScheduleButton()),

                      // ─── Live Matches Carousel ───────
                      if (liveMatches.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: AppLocalizations.of(context)!.liveMatches,
                            icon: Icons.circle,
                            iconColor: AppColors.liveRed,
                            iconSize: 10,
                            pulse: true,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 180,
                            child: PageView.builder(
                              key: const PageStorageKey(
                                'live_matches_carousel',
                              ),
                              controller: _pageController,
                              itemCount: isPremium
                                  ? liveMatches.length
                                  : liveMatches.length +
                                        (liveMatches.length ~/ 2),
                              itemBuilder: (context, index) {
                                if (!isPremium && (index + 1) % 3 == 0) {
                                  return NativeAdWidget(
                                    key: ValueKey('carousel_ad_$index'),
                                    style: NativeAdStyle.carousel,
                                  );
                                }
                                final matchIndex = isPremium
                                    ? index
                                    : index - (index ~/ 3);
                                final match = liveMatches[matchIndex];
                                return _LiveMatchCard(
                                  key: ValueKey(match.id),
                                  match: match,
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      // ─── Native Ad Placeholder ───────
                      if (!isPremium)
                        const SliverToBoxAdapter(
                          child: NativeAdWidget(style: NativeAdStyle.small),
                        ),

                      // ─── Upcoming Matches ────────────
                      if (upcomingMatches.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: AppLocalizations.of(
                              context,
                            )!.upcomingMatches,
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (!isPremium && (index + 1) % 3 == 0) {
                                final adNumber = (index + 1) ~/ 3;
                                return NativeAdWidget.forIndex(adNumber);
                              }
                              final matchIndex = isPremium
                                  ? index
                                  : index - (index ~/ 3);
                              return _MatchListTile(
                                match: upcomingMatches[matchIndex],
                              );
                            },
                            childCount: isPremium
                                ? upcomingMatches.length
                                : upcomingMatches.length +
                                      (upcomingMatches.length ~/ 2),
                          ),
                        ),
                      ],

                      // ─── Recent Matches ──────────────
                      if (recentMatches.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: AppLocalizations.of(context)!.recentMatches,
                            icon: Icons.history_rounded,
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (!isPremium && (index + 1) % 3 == 0) {
                                final adNumber = (index + 1) ~/ 3;
                                return NativeAdWidget.forIndex(adNumber);
                              }
                              final matchIndex = isPremium
                                  ? index
                                  : index - (index ~/ 3);
                              return _MatchListTile(
                                match: recentMatches[matchIndex],
                              );
                            },
                            childCount: isPremium
                                ? recentMatches.length
                                : recentMatches.length +
                                      (recentMatches.length ~/ 2),
                          ),
                        ),
                      ],

                      // Bottom spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                );
              },
            ),

            // ── Retention Prompt ─────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              top: _showRetentionPrompt ? 16 : -250,
              left: 16,
              right: 16,
              child: _RetentionPrompt(
                onClose: () => setState(() => _showRetentionPrompt = false),
                onTap: () {
                  setState(() => _showRetentionPrompt = false);
                  AdHelper.showInterstitialAd(() {
                    context.push('/spin-wheel');
                  });
                },
              ),
            ),

            // ── Tour Overlay (Policy Safe Bottom Card) ──────────────────────
            if (_isTourRunning)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: AppColors.primaryGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            _tourMessage,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final bool pulse;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.iconColor,
    this.iconSize = 18,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Match Card ────────────────────────────────────
class _LiveMatchCard extends StatelessWidget {
  final CricketMatch match;
  const _LiveMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        AdHelper.showInterstitialAd(() {
          context.push('/match/${match.id}', extra: match);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkCardGradient : null,
          color: isDark ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.liveRed.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.liveRed.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Series name & Live badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.seriesName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(match: match),
                ],
              ),
              const SizedBox(height: 14),
              // Team 1
              _TeamScore(
                flag: match.team1.flagUrl,
                name: match.team1.shortName,
                score: match.team1.score ?? '',
                overs: match.team1.overs != null
                    ? '(${match.team1.overs} ov)'
                    : '',
              ),
              const SizedBox(height: 8),
              // Team 2
              _TeamScore(
                flag: match.team2.flagUrl,
                name: match.team2.shortName,
                score: match.team2.score ?? '',
                overs: match.team2.overs != null
                    ? '(${match.team2.overs} ov)'
                    : '',
              ),
              const Spacer(),
              // Status text
              if (match.statusText != null)
                Text(
                  match.statusText!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CricketMatch match;
  const _StatusBadge({required this.match});

  @override
  Widget build(BuildContext context) {
    switch (match.status) {
      case MatchStatus.live:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: AppColors.liveGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'LIVE',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      case MatchStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 12,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 4),
              Text(
                'UPCOMING',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      case MatchStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 12, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'RESULT',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _TeamScore extends StatelessWidget {
  final String flag;
  final String name;
  final String score;
  final String overs;

  const _TeamScore({
    required this.flag,
    required this.name,
    required this.score,
    required this.overs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamFlag(flagUrl: flag, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        if (score.isEmpty)
          Text(
            'Yet to bat',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          )
        else ...[
          Text(
            score,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (overs.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              overs,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ],
    );
  }
}

// ─── Match List Tile ────────────────────────────────────
class _MatchListTile extends StatelessWidget {
  final CricketMatch match;
  const _MatchListTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        AdHelper.showInterstitialAd(() {
          context.push('/match/${match.id}', extra: match);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.darkDivider.withValues(alpha: 0.3)
                : AppColors.lightDivider.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${match.title} • ${match.seriesName}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (match.status == MatchStatus.upcoming)
                  _formatBadge(match.format),
              ],
            ),
            const SizedBox(height: 10),
            _TeamScore(
              flag: match.team1.flagUrl,
              name: match.team1.shortName,
              score: match.team1.score ?? '',
              overs: match.team1.overs != null
                  ? '(${match.team1.overs} ov)'
                  : '',
            ),
            const SizedBox(height: 6),
            _TeamScore(
              flag: match.team2.flagUrl,
              name: match.team2.shortName,
              score: match.team2.score ?? '',
              overs: match.team2.overs != null
                  ? '(${match.team2.overs} ov)'
                  : '',
            ),
            if (match.result != null || match.statusText != null) ...[
              const SizedBox(height: 8),
              Text(
                match.result ?? match.statusText ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.winGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (match.status == MatchStatus.upcoming) ...[
              const SizedBox(height: 8),
              Text(
                _formatUpcoming(match.startTime),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _formatBadge(MatchFormat format) {
    String label;
    switch (format) {
      case MatchFormat.test:
        label = 'TEST';
        break;
      case MatchFormat.odi:
        label = 'ODI';
        break;
      case MatchFormat.t20i:
      case MatchFormat.t20:
        label = 'T20';
        break;
      case MatchFormat.ipl:
        label = 'IPL';
        break;
      default:
        label = 'MATCH';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  String _formatUpcoming(DateTime time) {
    final diff = time.difference(DateTime.now());
    if (diff.inDays > 0) {
      return 'Starts in ${diff.inDays}d ${diff.inHours % 24}h';
    }
    return 'Starting soon';
  }
}

class _RetentionPrompt extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _RetentionPrompt({required this.onTap, required this.onClose});

  @override
  State<_RetentionPrompt> createState() => _RetentionPromptState();
}

class _RetentionPromptState extends State<_RetentionPrompt>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutQuad),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Premium Background with Animated Shimmer
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF00332E),
                                const Color(0xFF00695C),
                                const Color(0xFF00332E),
                              ]
                            : [
                                const Color(0xFF1B5E20),
                                const Color(0xFF388E3C),
                                const Color(0xFF1B5E20),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, _shimmerController.value, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: child,
                  );
                },
                child: Row(
                  children: [
                    // Icon Container with intense glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.stars_rounded,
                          color: Color(0xFFFFD700),
                          size: 44,
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFFFD700)],
                            ).createShader(bounds),
                            child: Text(
                              'DAILY FREE SPIN! 🎰',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Don't miss out! Your premium daily free spin is ready to claim.",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onTap,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA000),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFD700,
                                      ).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'SPIN NOW',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Colors.black,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.flash_on_rounded,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Close Icon - Highly Visible & Premium
              Positioned(
                right: 12,
                top: 12,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
