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
import 'package:cricketbuzz/core/services/notification_service.dart';
import 'package:cricketbuzz/core/widgets/team_flag.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _autoRefreshTimer;
  MatchCategory _selectedCategory = MatchCategory.all;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHomeData());
    _requestNotificationPermissions();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final notificationService = NotificationService();
    final granted = await notificationService.requestAndCheckPermissions();

    if (!granted && mounted) {
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

  List<CricketMatch> _filter(List<CricketMatch> matches) {
    if (_selectedCategory == MatchCategory.all) return matches;
    return matches.where((m) => _selectedCategory.matches(m)).toList();
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

            // Apply filters
            final liveMatches = _filter(state.liveMatches);
            final upcomingMatches = _filter(state.upcomingMatches);
            final recentMatches = _filter(state.recentMatches);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(RefreshHomeData());
                await Future.delayed(const Duration(seconds: 5));
              },
              color: AppColors.primaryGreen,
              child: CustomScrollView(
                slivers: [
                  // ─── App Bar ─────────────────────
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    title: PopupMenuButton<MatchCategory>(
                      useRootNavigator: true,
                      onSelected: (category) =>
                          setState(() => _selectedCategory = category),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'CricketBuzz',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
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
                                  'Updating scores...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => context.push('/settings'),
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

                  // ─── Live Matches Carousel ───────
                  if (liveMatches.isNotEmpty) ...[
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
                          itemCount: liveMatches.length,
                          itemBuilder: (context, index) {
                            return _LiveMatchCard(match: liveMatches[index]);
                          },
                        ),
                      ),
                    ),
                  ],

                  // ─── Native Ad Placeholder ───────
                  SliverToBoxAdapter(child: _NativeAdPlaceholder()),

                  // ─── Upcoming Matches ────────────
                  if (upcomingMatches.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Upcoming Matches',
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _MatchListTile(match: upcomingMatches[index]),
                        childCount: upcomingMatches.length,
                      ),
                    ),
                  ],

                  // ─── Recent Matches ──────────────
                  if (recentMatches.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Recent Results',
                        icon: Icons.history_rounded,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _MatchListTile(match: recentMatches[index]),
                        childCount: recentMatches.length,
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
        const SizedBox(width: 12), // Increased spacing
        Text(
          score,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (overs.isNotEmpty) ...[
          const SizedBox(width: 6), // Increased spacing
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
    return 'Starting soon';
  }
}

class _NativeAdPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Ad',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sponsored',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Cricket Gear 2026',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get up to 50% off on all cricket accessories.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Shop Now'),
            ),
          ),
        ],
      ),
    );
  }
}
