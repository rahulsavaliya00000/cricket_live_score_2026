import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/di/injection_container.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/features/matches/presentation/bloc/match_detail_bloc.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/core/widgets/team_flag.dart';
import 'package:cricketbuzz/core/widgets/empty_state_widget.dart';

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

class _MatchDetailViewState extends State<_MatchDetailView> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
    // Subscribe to live score stream for real-time updates
    context.read<MatchDetailBloc>().add(SubscribeToLiveScore(widget.matchId));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _MatchHeader(match: match),
                  ),
                  bottom: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    labelColor: isDark ? AppColors.primaryGreen : Colors.white,
                    unselectedLabelColor: isDark
                        ? Colors.white60
                        : Colors.white60,
                    indicatorColor: isDark
                        ? AppColors.primaryGreen
                        : Colors.white,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'Scorecard'),
                      Tab(text: 'Commentary'),
                      Tab(text: 'Info'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _SummaryTab(detail: detail),
                  _ScorecardTab(innings: detail.innings),
                  _CommentaryTab(commentary: detail.commentary),
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
              _HeaderTeam(
                flag: match.team1.flagUrl,
                name: match.team1.shortName,
                score: match.team1.score ?? '',
                overs: match.team1.overs,
              ),
              Container(
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
              _HeaderTeam(
                flag: match.team2.flagUrl,
                name: match.team2.shortName,
                score: match.team2.score ?? '',
                overs: match.team2.overs,
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
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
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
        ],
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
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: detail.innings.map((inn) {
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
                            Text(
                              '${b.name}*',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${b.runs} (${b.balls})',
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
      }).toList(),
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
    return ListView(
      padding: const EdgeInsets.all(12),
      children: innings.map((inn) {
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
      }).toList(),
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: commentary.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ball = commentary[index];
        return Padding(
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
