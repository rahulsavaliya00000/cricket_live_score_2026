import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/features/home/presentation/bloc/home_bloc.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/core/widgets/team_flag.dart';
import 'package:cricketbuzz/core/widgets/empty_state_widget.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  MatchCategory _selectedCategory = MatchCategory.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        context.read<HomeBloc>().add(RefreshHomeData());
      }
    });
  }

  List<CricketMatch> _filter(List<CricketMatch> matches) {
    if (_selectedCategory == MatchCategory.all) return matches;
    return matches.where((m) => _selectedCategory.matches(m)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Matches',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              // ─── Filter Chips ──────────────
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: MatchCategory.values.map((cat) {
                    final selected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          cat.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected ? Colors.white : null,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.primaryGreen,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primaryGreen
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // ─── Tabs ─────────────────────
              TabBar(
                dividerColor: Colors.transparent,
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Live'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Results'),
                ],
              ),
            ],
          ),
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
                matches: _filter(state.liveMatches),
                emptyText: 'No live matches right now',
                emptyIcon: Icons.live_tv_rounded,
              ),
              _MatchList(
                matches: _filter(state.upcomingMatches),
                emptyText: 'No upcoming matches',
                emptyIcon: Icons.event_busy_rounded,
              ),
              _MatchList(
                matches: _filter(state.recentMatches),
                emptyText: 'No recent results',
                emptyIcon: Icons.history_toggle_off_rounded,
              ),
            ],
          );
        },
      ),
      // bottomNavigationBar: _BannerAdPlaceholder(), // Removed as per request
    );
  }
}

class _MatchList extends StatelessWidget {
  final List<CricketMatch> matches;
  final String emptyText;
  final IconData? emptyIcon;

  const _MatchList({
    required this.matches,
    required this.emptyText,
    this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return EmptyStateWidget(
        title: emptyText,
        subtitle: 'Check back later for updates',
        icon: emptyIcon ?? Icons.sports_cricket_outlined,
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
      onTap: () => context.push('/match/${match.id}', extra: match),
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
                _StatusChip(status: match.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TeamFlag(flagUrl: match.team1.flagUrl, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.team1.shortName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (match.team1.overs != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${match.team1.overs})',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                TeamFlag(flagUrl: match.team2.flagUrl, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.team2.shortName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (match.team2.overs != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${match.team2.overs})',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _StatusChip extends StatelessWidget {
  final MatchStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    LinearGradient gradient;

    switch (status) {
      case MatchStatus.live:
        label = 'LIVE';
        gradient = AppColors.liveGradient;
        break;
      case MatchStatus.upcoming:
        label = 'UPCOMING';
        gradient = const LinearGradient(
          colors: [AppColors.accentOrange, AppColors.accentGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case MatchStatus.completed:
        label = 'RESULT';
        gradient = AppColors.primaryGradient;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
