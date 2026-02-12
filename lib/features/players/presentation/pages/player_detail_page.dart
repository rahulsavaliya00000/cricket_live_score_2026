import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/di/injection_container.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/features/players/presentation/bloc/players_bloc.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';

class PlayerDetailPage extends StatelessWidget {
  final String playerId;
  const PlayerDetailPage({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PlayersBloc>()..add(LoadPlayerDetail(playerId)),
      child: _PlayerDetailView(playerId: playerId),
    );
  }
}

class _PlayerDetailView extends StatelessWidget {
  final String playerId;
  const _PlayerDetailView({required this.playerId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayersBloc, PlayersState>(
      builder: (context, state) {
        if (state.status == PlayersStatus.loading) {
          return Scaffold(appBar: AppBar(), body: const ListShimmer());
        }
        if (state.selectedPlayer == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              onRetry: () =>
                  context.read<PlayersBloc>().add(LoadPlayerDetail(playerId)),
            ),
          );
        }
        final player = state.selectedPlayer!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkCardGradient
                          : AppColors.primaryGradient,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          player.name,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${player.country} • ${player.role}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal info chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (player.battingStyle.isNotEmpty)
                            Chip(label: Text(player.battingStyle)),
                          if (player.bowlingStyle.isNotEmpty)
                            Chip(label: Text(player.bowlingStyle)),
                          ...player.teams.map((t) => Chip(label: Text(t))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Batting Stats
                      if (player.battingStats != null) ...[
                        Text(
                          'Batting Stats',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _StatsGrid(
                          stats: player.battingStats!,
                          isBatting: true,
                        ),
                      ],
                      // Bowling Stats
                      if (player.bowlingStats != null &&
                          player.bowlingStats!.wickets > 0) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Bowling Stats',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _StatsGrid(
                          stats: player.bowlingStats!,
                          isBatting: false,
                        ),
                      ],
                      // Recent Performances
                      if (player.recentPerformances.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Recent Performances',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...player.recentPerformances.map(
                          (p) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.matchTitle,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'vs ${p.against} • ${p.date}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (p.runs != '-')
                                        Text(
                                          p.runs,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      if (p.wickets != '-')
                                        Text(
                                          p.wickets,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final PlayerStats stats;
  final bool isBatting;
  const _StatsGrid({required this.stats, required this.isBatting});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = isBatting
        ? [
            _StatItem('Matches', '${stats.matches}'),
            _StatItem('Runs', '${stats.runs}'),
            _StatItem('Average', stats.average.toStringAsFixed(1)),
            _StatItem('SR', stats.strikeRate.toStringAsFixed(1)),
            _StatItem('100s', '${stats.hundreds}'),
            _StatItem('50s', '${stats.fifties}'),
            _StatItem('HS', '${stats.highestScore}'),
            _StatItem('4s', '${stats.fours}'),
            _StatItem('6s', '${stats.sixes}'),
          ]
        : [
            _StatItem('Matches', '${stats.matches}'),
            _StatItem('Wickets', '${stats.wickets}'),
            _StatItem('Average', stats.bowlingAverage.toStringAsFixed(1)),
            _StatItem('Economy', stats.economy.toStringAsFixed(1)),
            _StatItem('Best', stats.bestBowling),
            _StatItem('5W', '${stats.fiveWickets}'),
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              width: (MediaQuery.of(context).size.width - 48) / 3,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkDivider.withValues(alpha: 0.3)
                      : AppColors.lightDivider,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    item.value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  final String label, value;
  _StatItem(this.label, this.value);
}
