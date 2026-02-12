import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/di/injection_container.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/features/series/presentation/bloc/series_bloc.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

class SeriesDetailPage extends StatelessWidget {
  final String seriesId;
  const SeriesDetailPage({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SeriesBloc>()..add(LoadSeriesDetail(seriesId)),
      child: _SeriesDetailView(seriesId: seriesId),
    );
  }
}

class _SeriesDetailView extends StatelessWidget {
  final String seriesId;
  const _SeriesDetailView({required this.seriesId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeriesBloc, SeriesState>(
      builder: (context, state) {
        if (state.status == SeriesStatus.loading) {
          return Scaffold(appBar: AppBar(), body: const ListShimmer());
        }
        if (state.selectedSeries == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              onRetry: () =>
                  context.read<SeriesBloc>().add(LoadSeriesDetail(seriesId)),
            ),
          );
        }
        final series = state.selectedSeries!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 150,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.darkCardGradient
                            : AppColors.primaryGradient,
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 50),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            series.name,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${series.matches.length} Matches',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottom: const TabBar(
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: 'Matches'),
                      Tab(text: 'Points Table'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _MatchesTab(series: series),
                  _PointsTableTab(entries: series.pointsTable),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MatchesTab extends StatelessWidget {
  final Series series;
  const _MatchesTab({required this.series});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_cricket_outlined,
              size: 48,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'Match schedule coming soon',
              style: GoogleFonts.poppins(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsTableTab extends StatelessWidget {
  final List<PointsTableEntry> entries;
  const _PointsTableTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Points table not available',
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Team',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'P',
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
                          'L',
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
                          'NRR',
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
                          'Pts',
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
                ...entries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final isQualified = i < 4;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isQualified
                          ? AppColors.primaryGreen.withValues(alpha: 0.05)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isQualified
                                      ? AppColors.primaryGreen
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.teamName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.matches}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.won}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.lost}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.netRunRate.toStringAsFixed(3),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.points}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
