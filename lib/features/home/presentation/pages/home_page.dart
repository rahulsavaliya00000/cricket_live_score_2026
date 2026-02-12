import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';

import 'package:cricketbuzz/features/home/presentation/bloc/home_bloc.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/core/services/notification_service.dart';
import 'package:cricketbuzz/core/widgets/team_flag.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHomeData());
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    // Delay request by 5 seconds to ensure app is loaded and user is settled
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      // We use the singleton instance directly or via DI if available.
      // Since it's a singleton, this is fine.
      // Ideally getting it from SL would be cleaner but for now consistent with main.dart usage pattern (or lack thereof, since main created it).
      // Actually main.dart created it but it's a singleton with factory.

      /* 
       Wait, in main.dart:
       final notificationService = NotificationService();
       factory NotificationService() => _instance;
       So new NotificationService() returns the singleton.
       */

      final notificationService = NotificationService(); // Gets singleton
      await notificationService.requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state.status == HomeStatus.loading &&
                state.liveMatches.isEmpty) {
              return const ListShimmer(itemCount: 4);
            }
            if (state.status == HomeStatus.error && state.liveMatches.isEmpty) {
              return ErrorView(
                message: state.error ?? 'Failed to load data',
                onRetry: () => context.read<HomeBloc>().add(LoadHomeData()),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(RefreshHomeData());
                await Future.delayed(const Duration(seconds: 1));
              },
              color: AppColors.primaryGreen,
              child: CustomScrollView(
                slivers: [
                  // ─── App Bar ─────────────────────
                  SliverAppBar(
                    floating: true,
                    title: Row(
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
                        Text(
                          'CricketBuzz',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_outlined, size: 22),
                      ),
                    ],
                  ),

                  // ─── Live Matches Carousel ───────
                  if (state.liveMatches.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Live Matches',
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
                          controller: PageController(viewportFraction: 0.92),
                          itemCount: state.liveMatches.length,
                          itemBuilder: (context, index) {
                            return _LiveMatchCard(
                              match: state.liveMatches[index],
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // ─── Upcoming Matches ────────────
                  if (state.upcomingMatches.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Upcoming Matches',
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _MatchListTile(match: state.upcomingMatches[index]),
                        childCount: state.upcomingMatches.length,
                      ),
                    ),
                  ],

                  // ─── Recent Matches ──────────────
                  if (state.recentMatches.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Recent Results',
                        icon: Icons.history_rounded,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _MatchListTile(match: state.recentMatches[index]),
                        childCount: state.recentMatches.length,
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
  const _LiveMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                  ),
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
        Text(
          name,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          score,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (overs.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            overs,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
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
      onTap: () => context.push('/match/${match.id}'),
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
            if (match.result != null) ...[
              const SizedBox(height: 8),
              Text(
                match.result!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.winGreen,
                ),
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
    if (diff.inHours > 0) {
      return 'Starts in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return 'Starting soon';
  }
}
