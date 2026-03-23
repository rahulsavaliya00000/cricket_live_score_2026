import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:cricket_live_score/core/constants/app_colors.dart';
import 'package:cricket_live_score/core/di/injection_container.dart';
import 'package:cricket_live_score/core/widgets/error_view.dart';
import 'package:cricket_live_score/core/widgets/shimmer_loader.dart';
import 'package:cricket_live_score/features/matches/presentation/bloc/match_detail_bloc.dart';
import 'package:cricket_live_score/features/matches/domain/entities/match_entity.dart';
import 'package:cricket_live_score/core/widgets/team_flag.dart';
import 'package:cricket_live_score/core/widgets/empty_state_widget.dart';
import 'package:cricket_live_score/core/widgets/native_ad_widget.dart';
import 'package:cricket_live_score/core/widgets/pip_score_overlay.dart';
import 'package:fl_pip/fl_pip.dart';
import 'package:cricket_live_score/features/profile/presentation/bloc/premium_bloc.dart';
import 'package:go_router/go_router.dart';

class MatchDetailPage extends StatelessWidget {
  final String matchId;
  final CricketMatch? previewMatch;
  const MatchDetailPage({super.key, required this.matchId, this.previewMatch});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<MatchDetailBloc>()
            ..add(LoadMatchDetail(matchId, previewMatch: previewMatch)),
      child: _MatchDetailView(matchId: matchId),
    );
  }
}

class _MatchDetailView extends StatefulWidget {
  final String matchId;
  const _MatchDetailView({required this.matchId});

  @override
  State<_MatchDetailView> createState() => _MatchDetailViewState();
}

class _MatchDetailViewState extends State<_MatchDetailView>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRefreshTimer();
    // Subscribe to live score stream for real-time updates
    context.read<MatchDetailBloc>().add(SubscribeToLiveScore(widget.matchId));
    // Enable background PiP automatically when this page is active
    _setupAutoPip();
    // Check premium status to ensure PiP only works if allowed
    context.read<PremiumBloc>().add(CheckPremiumStatus());
  }

  void _setupAutoPip() {
    final isPremium = context.read<PremiumBloc>().state.isPremium;
    if (!isPremium) return; // Don't even try to setup if not premium

    FlPiP().enable(
      android: const FlPiPAndroidConfig(
        aspectRatio: Rational(16, 9),
        enabledWhenBackground: true,
      ),
      ios: const FlPiPiOSConfig(enabledWhenBackground: true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // Potentially enter PiP automatically here if we want
      // but explicitly triggered is safer for now.
    }
  }

  void _enterPip(CricketMatch match) {
    final premiumState = context.read<PremiumBloc>().state;

    // If fully premium, just enable PiP directly
    if (premiumState.isPremium) {
      _startPip();
      return;
    }

    // If trial is active today, allow PiP without dialog
    if (premiumState.isPipTrialActive) {
      _startPip();
      return;
    }

    // Otherwise show the explain + trial / upsell dialog
    _showPipDialog(premiumState);
  }

  void _startPip() {
    FlPiP().enable(
      android: const FlPiPAndroidConfig(
        aspectRatio: Rational(16, 9),
        enabledWhenBackground: true,
      ),
      ios: const FlPiPiOSConfig(enabledWhenBackground: true),
    );
  }

  void _showPipDialog(PremiumState premiumState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trialExpired = premiumState.isPipTrialExpired;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2530) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, const Color(0xFF00C853)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.picture_in_picture_alt_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Floating Score',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Watch live scores in a small floating window\nwhile you use other apps.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Feature bullets ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(
                  children: [
                    _PipFeatureRow(
                      icon: Icons.open_in_new_rounded,
                      text: 'Minimise the app — score stays on screen',
                    ),
                    const SizedBox(height: 10),
                    _PipFeatureRow(
                      icon: Icons.swap_horiz_rounded,
                      text: 'Switch to WhatsApp, YouTube — score follows you',
                    ),
                    const SizedBox(height: 10),
                    _PipFeatureRow(
                      icon: Icons.touch_app_rounded,
                      text: 'Tap the floating window to come back anytime',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ── Trial expired notice (only when trial was used) ──
              if (trialExpired)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your free trial has ended. Get lifetime access to keep using it.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    // Primary CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (trialExpired) {
                            // Trial already used → go to premium page
                            context.push('/premium');
                          } else {
                            // First time → activate trial and start PiP
                            context.read<PremiumBloc>().add(ActivatePipTrial());
                            Future.delayed(
                              const Duration(milliseconds: 200),
                              _startPip,
                            );
                          }
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                trialExpired
                                    ? Icons.workspace_premium_rounded
                                    : Icons.play_circle_outline_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                trialExpired
                                    ? 'Go Premium — ${context.read<PremiumBloc>().state.findPackage('\$rc_lifetime')?.storeProduct.priceString ?? '₹50'}'
                                    : 'Try Free for Today',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Dismiss
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Maybe later',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black45,
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
      ),
    );
  }

  void _startRefreshTimer() {
    // Refresh every 5 seconds for live matches
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        context.read<MatchDetailBloc>().add(RefreshMatchDetail(widget.matchId));
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<MatchDetailBloc, MatchDetailState>(
      builder: (context, state) {
        if (state.status == MatchDetailStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Match Details')),
            body: const ListShimmer(itemCount: 5),
          );
        }
        if (state.status == MatchDetailStatus.error ||
            state.matchDetail == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Match Details')),
            body: ErrorView(
              message: state.error ?? 'Failed to load match details',
              onRetry: () => context.read<MatchDetailBloc>().add(
                LoadMatchDetail(widget.matchId),
              ),
            ),
          );
        }

        final detail = state.matchDetail!;
        final match = detail.match;

        return PiPBuilder(
          builder: (statusInfo) {
            if (statusInfo?.status == PiPStatus.enabled) {
              return PipScoreOverlay(match: match);
            }
            return DefaultTabController(
              length: 4,
              child: Scaffold(
                body: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      expandedHeight: 350,
                      pinned: true,
                      actions: [
                        IconButton(
                          onPressed: () => _enterPip(match),
                          icon: const Icon(
                            Icons.picture_in_picture_alt_rounded,
                            color: Colors.white,
                          ),
                          tooltip: 'Floating Score',
                        ),
                        const SizedBox(width: 8),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _MatchHeader(match: match),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          isScrollable: false,
                          dividerColor: Colors.transparent,
                          labelColor: isDark
                              ? AppColors.primaryGreen
                              : AppColors.primaryGreen,
                          unselectedLabelColor: isDark
                              ? Colors.white60
                              : Colors.black45,
                          indicatorColor: AppColors.primaryGreen,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                          ),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: const [
                            Tab(text: 'Scorecard'),
                            Tab(text: 'Commentary'),
                            Tab(text: 'Summary'),
                            Tab(text: 'Info'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      _ScorecardTab(innings: detail.innings),
                      _CommentaryTab(commentary: detail.commentary),
                      _SummaryTab(detail: detail),
                      _StatsTab(
                        stats: detail.stats,
                        playingXI1: detail.playingXI1,
                        playingXI2: detail.playingXI2,
                        team1Name: detail.match.team1.name,
                        team2Name: detail.match.team2.name,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Match Header ───────────────────────────────────────
class _MatchHeader extends StatelessWidget {
  final CricketMatch match;
  const _MatchHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkCardGradient
            : AppColors.primaryGradient,
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 70),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            match.seriesName,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _HeaderTeam(
                  flag: match.team1.flagUrl,
                  name: match.team1.shortName,
                  score: match.team1.score ?? '',
                  overs: match.team1.overs,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'VS',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: _HeaderTeam(
                  flag: match.team2.flagUrl,
                  name: match.team2.shortName,
                  score: match.team2.score ?? '',
                  overs: match.team2.overs,
                ),
              ),
            ],
          ),
          if ((match.result != null && match.result!.isNotEmpty) ||
              (match.statusText != null && match.statusText!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                match.result?.isNotEmpty == true
                    ? match.result!
                    : match.statusText!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderTeam extends StatelessWidget {
  final String flag, name, score;
  final String? overs;
  const _HeaderTeam({
    required this.flag,
    required this.name,
    required this.score,
    this.overs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamFlag(flagUrl: flag, size: 40),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (score.isNotEmpty) ...[
          Text(
            score,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (overs != null)
            Text(
              '($overs ov)',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
            ),
        ] else
          Text(
            'Yet to bat',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white60,
            ),
          ),
      ],
    );
  }
}

// ─── Summary Tab ────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  final MatchDetail detail;
  const _SummaryTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.innings.isEmpty) {
      return const CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              title: 'Match yet to begin',
              subtitle:
                  'Detailed summary will appear here once the match starts.',
              icon: Icons.sports_cricket_outlined,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: NativeAdWidget(
                key: ValueKey('ad_summary_empty'),
                style: NativeAdStyle.small,
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: detail.innings.length + ((detail.innings.length + 1) ~/ 2),
      itemBuilder: (context, index) {
        if (index % 3 == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NativeAdWidget(
              key: ValueKey('ad_summary_$index'),
              style: NativeAdStyle.small,
            ),
          );
        }
        final innIndex = index - (index ~/ 3 + 1);
        final inn = detail.innings[innIndex];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inn.teamName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${inn.scoreText} ${inn.oversText}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'RR: ${inn.runRate.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                // Current batsmen (if batting)
                ...inn.batsmen
                    .where((b) => b.isBatting)
                    .map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sports_cricket,
                              size: 14,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${b.name}*',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${b.runs} (${b.balls})',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Scorecard Tab ──────────────────────────────────────
class _ScorecardTab extends StatelessWidget {
  final List<Innings> innings;
  const _ScorecardTab({required this.innings});

  @override
  Widget build(BuildContext context) {
    if (innings.isEmpty) {
      return const CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              title: 'Scorecard not available',
              subtitle: 'Scores will be updated here once the match begins.',
              icon: Icons.article_outlined,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: innings.length + ((innings.length + 1) ~/ 2),
      itemBuilder: (context, index) {
        if (index % 3 == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NativeAdWidget(
              key: ValueKey('ad_scorecard_$index'),
              style: NativeAdStyle.small,
            ),
          );
        }
        final innIndex = index - (index ~/ 3 + 1);
        final inn = innings[innIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Innings header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${inn.teamName} — ${inn.scoreText} ${inn.oversText}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Batting table
            _buildBattingTable(context, inn.batsmen),
            const SizedBox(height: 12),
            // Bowling table
            _buildBowlingTable(context, inn.bowlers),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildBattingTable(BuildContext context, List<BatsmanScore> batsmen) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Batter',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'R',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'B',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '4s',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '6s',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'SR',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...batsmen.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            b.isBatting ? '${b.name} *' : b.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: b.isBatting
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: b.isBatting
                                  ? AppColors.primaryGreen
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${b.runs}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${b.balls}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${b.fours}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${b.sixes}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            b.strikeRate.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (b.dismissal.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          b.dismissal,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBowlingTable(BuildContext context, List<BowlerFigure> bowlers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Bowler',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'O',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'M',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'R',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'W',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'ER',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...bowlers.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        b.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b.overs.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${b.maidens}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${b.runs}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${b.wickets}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b.economy.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Commentary Tab ─────────────────────────────────────
class _CommentaryTab extends StatelessWidget {
  final List<BallCommentary> commentary;
  const _CommentaryTab({required this.commentary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commentary.length + ((commentary.length + 1) ~/ 2),
      itemBuilder: (context, index) {
        if (index % 3 == 0) {
          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              const NativeAdWidget(style: NativeAdStyle.small),
              const Divider(height: 1),
            ],
          );
        }
        final itemIndex = index - (index ~/ 3 + 1);
        final ball = commentary[itemIndex];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ball.isWicket
                          ? AppColors.liveRed.withValues(alpha: 0.1)
                          : ball.isSix
                          ? AppColors.accentGold.withValues(alpha: 0.15)
                          : ball.isFour
                          ? AppColors.primaryGreen.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ball.isWicket
                            ? AppColors.liveRed.withValues(alpha: 0.3)
                            : ball.isSix
                            ? AppColors.accentGold.withValues(alpha: 0.3)
                            : ball.isFour
                            ? AppColors.primaryGreen.withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ball.isWicket
                          ? 'W'
                          : ball.isSix
                          ? '6'
                          : ball.isFour
                          ? '4'
                          : '${ball.runs}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ball.isWicket
                            ? AppColors.liveRed
                            : ball.isSix
                            ? AppColors.accentGold
                            : ball.isFour
                            ? AppColors.primaryGreen
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ball.overNumber}.${ball.ballNumber}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ball.commentary,
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Stats Tab ──────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final MatchStats? stats;
  final List<String> playingXI1;
  final List<String> playingXI2;
  final String team1Name;
  final String team2Name;

  const _StatsTab({
    this.stats,
    this.playingXI1 = const [],
    this.playingXI2 = const [],
    this.team1Name = 'Team 1',
    this.team2Name = 'Team 2',
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: NativeAdWidget(style: NativeAdStyle.small),
        ),
        if (playingXI1.isNotEmpty) ...[
          Text(
            "$team1Name's Playing XI",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: playingXI1.map((name) {
              return Chip(
                label: Text(name, style: GoogleFonts.poppins(fontSize: 12)),
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                side: const BorderSide(
                  color: AppColors.primaryGreen,
                  width: 0.5,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (playingXI2.isNotEmpty) ...[
          Text(
            "$team2Name's Playing XI",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: playingXI2.map((name) {
              return Chip(
                label: Text(name, style: GoogleFonts.poppins(fontSize: 12)),
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                side: const BorderSide(
                  color: AppColors.primaryGreen,
                  width: 0.5,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (stats != null) ...[
          Text(
            'Match Statistics',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _StatRow('Total Fours', '${stats!.totalFours}'),
          _StatRow('Total Sixes', '${stats!.totalSixes}'),
          _StatRow('Total Dot Balls', '${stats!.totalDotBalls}'),
          _StatRow(
            'Highest Run Rate',
            stats!.highestRunRate.toStringAsFixed(2),
          ),
          _StatRow('Highest Score', stats!.highestScore),
          _StatRow('Best Bowling', stats!.bestBowling),
        ] else if (playingXI1.isEmpty && playingXI2.isEmpty && stats == null)
          const Center(child: Text('No information available')),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 14)),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// ─── PiP Dialog Feature Row ─────────────────────────────
class _PipFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PipFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
