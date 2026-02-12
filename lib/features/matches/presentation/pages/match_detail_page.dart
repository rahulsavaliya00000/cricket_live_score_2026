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

class MatchDetailPage extends StatelessWidget {
  final String matchId;
  const MatchDetailPage({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MatchDetailBloc>()..add(LoadMatchDetail(matchId)),
      child: _MatchDetailView(matchId: matchId),
    );
  }
}

class _MatchDetailView extends StatelessWidget {
  final String matchId;
  const _MatchDetailView({required this.matchId});

  @override
  Widget build(BuildContext context) {
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
              onRetry: () =>
                  context.read<MatchDetailBloc>().add(LoadMatchDetail(matchId)),
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
                    isScrollable: false,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'Scorecard'),
                      Tab(text: 'Commentary'),
                      Tab(text: 'Stats'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _SummaryTab(detail: detail),
                  _ScorecardTab(innings: detail.innings),
                  _CommentaryTab(commentary: detail.commentary),
                  _StatsTab(stats: detail.stats),
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
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
          if (match.statusText != null) ...[
            const SizedBox(height: 8),
            Text(
              match.statusText!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.accentGold,
              ),
            ),
          ],
          if (match.result != null) ...[
            const SizedBox(height: 8),
            Text(
              match.result!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.greenAccent,
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
      return const Center(child: Text('Match yet to begin'));
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
                    Text(
                      inn.teamName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
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
  const _StatsTab({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: Text('No stats available'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatRow('Total Fours', '${stats!.totalFours}'),
        _StatRow('Total Sixes', '${stats!.totalSixes}'),
        _StatRow('Total Dot Balls', '${stats!.totalDotBalls}'),
        _StatRow('Highest Run Rate', stats!.highestRunRate.toStringAsFixed(2)),
        _StatRow('Highest Score', stats!.highestScore),
        _StatRow('Best Bowling', stats!.bestBowling),
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
