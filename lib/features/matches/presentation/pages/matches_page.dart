import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/features/home/presentation/bloc/home_bloc.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Matches',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          dividerColor: Colors.transparent,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading && state.liveMatches.isEmpty) {
            return const ListShimmer(itemCount: 5);
          }
          if (state.status == HomeStatus.error && state.liveMatches.isEmpty) {
            return ErrorView(
              message: state.error ?? 'Failed to load matches',
              onRetry: () => context.read<HomeBloc>().add(LoadHomeData()),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _MatchList(
                matches: state.liveMatches,
                emptyText: 'No live matches right now',
              ),
              _MatchList(
                matches: state.upcomingMatches,
                emptyText: 'No upcoming matches',
              ),
              _MatchList(
                matches: state.recentMatches,
                emptyText: 'No recent results',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  final List<CricketMatch> matches;
  final String emptyText;
  const _MatchList({required this.matches, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_cricket_outlined,
              size: 48,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 12),
            Text(
              emptyText,
              style: GoogleFonts.poppins(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _MatchCard(match: match);
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  final CricketMatch match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: match.status == MatchStatus.live
              ? Border.all(color: AppColors.liveRed.withValues(alpha: 0.3))
              : Border.all(
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
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (match.status == MatchStatus.live)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.liveGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LIVE',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(match.team1.flagUrl, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  match.team1.shortName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (match.team1.score != null)
                  Text(
                    match.team1.score!,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (match.team1.overs != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${match.team1.overs})',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(match.team2.flagUrl, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  match.team2.shortName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (match.team2.score != null)
                  Text(
                    match.team2.score!,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (match.team2.overs != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${match.team2.overs})',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
            if (match.statusText != null || match.result != null) ...[
              const SizedBox(height: 8),
              Text(
                match.result ?? match.statusText ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: match.result != null
                      ? AppColors.winGreen
                      : AppColors.primaryGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
