import 'package:cached_network_image/cached_network_image.dart';
import 'package:cricket_live_score/core/constants/app_colors.dart';
import 'package:cricket_live_score/core/widgets/shimmer_loader.dart';
import 'package:cricket_live_score/features/players/domain/entities/player_entity.dart';
import 'package:cricket_live_score/features/players/presentation/bloc/players_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricket_live_score/core/utils/ad_helper.dart';
import 'package:cricket_live_score/core/widgets/native_ad_widget.dart';

class TeamPlayersPage extends StatefulWidget {
  final String teamSlug;
  final String teamId;
  final String teamName;

  const TeamPlayersPage({
    super.key,
    required this.teamSlug,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamPlayersPage> createState() => _TeamPlayersPageState();
}

class _TeamPlayersPageState extends State<TeamPlayersPage> {
  @override
  void initState() {
    super.initState();
    context.read<PlayersBloc>().add(
      LoadTeamPlayers(
        teamSlug: widget.teamSlug,
        teamId: widget.teamId,
        teamName: widget.teamName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: BlocBuilder<PlayersBloc, PlayersState>(
        builder: (context, state) {
          final isLoading = state.status == PlayersStatus.loadingPlayers;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: isDark
                    ? AppColors.darkCard
                    : AppColors.primaryGreen,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkCardGradient
                          : AppColors.primaryGradient,
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.teamName,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLoading
                              ? 'Loading players...'
                              : '${state.teamPlayers.length} Players',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading
              if (isLoading)
                const SliverFillRemaining(child: ListShimmer(itemCount: 8)),

              // Error
              if (state.status == PlayersStatus.error)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load players',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<PlayersBloc>().add(
                            LoadTeamPlayers(
                              teamSlug: widget.teamSlug,
                              teamId: widget.teamId,
                              teamName: widget.teamName,
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Players grouped by role
              if (state.teamPlayers.isNotEmpty) ...[
                ..._buildRoleSections(context, state.teamPlayers),
                // Bottom padding
                const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
              ],

              // Empty state
              if (state.teamPlayers.isEmpty &&
                  !isLoading &&
                  state.status != PlayersStatus.error)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No players found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildRoleSections(BuildContext context, List<Player> players) {
    final roleOrder = [
      'Batsman',
      'All-Rounder',
      'Wicket-Keeper',
      'Bowler',
      'Player',
    ];
    final roleIcons = {
      'Batsman': Icons.sports_cricket,
      'All-Rounder': Icons.swap_horiz_rounded,
      'Wicket-Keeper': Icons.sports_handball_rounded,
      'Bowler': Icons.sports_baseball_rounded,
      'Player': Icons.person_rounded,
    };
    final roleColors = {
      'Batsman': AppColors.primaryGreen,
      'All-Rounder': AppColors.accentGold,
      'Wicket-Keeper': Colors.blueAccent,
      'Bowler': Colors.redAccent,
      'Player': Colors.grey,
    };

    // Group players by role
    final grouped = <String, List<Player>>{};
    for (final p in players) {
      grouped.putIfAbsent(p.role, () => []).add(p);
    }

    final isPremium = AdHelper.isPremium;
    final sections = <Widget>[];
    int sectionCount = 0;

    for (final role in roleOrder) {
      if (!grouped.containsKey(role) || grouped[role]!.isEmpty) continue;
      final rolePlayers = grouped[role]!;
      sectionCount++;

      // Section header
      sections.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (roleColors[role] ?? Colors.grey).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    roleIcons[role] ?? Icons.person,
                    size: 18,
                    color: roleColors[role] ?? Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  role == 'Batsman'
                      ? 'Batsmen'
                      : role == 'Bowler'
                      ? 'Bowlers'
                      : role == 'All-Rounder'
                      ? 'All Rounders'
                      : role == 'Wicket-Keeper'
                      ? 'Wicket Keepers'
                      : 'Players',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${rolePlayers.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Player grid (2 columns)
      sections.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final player = rolePlayers[index];
              return InkWell(
                onTap: () {
                  final slug =
                      player.slug ??
                      player.name.toLowerCase().replaceAll(' ', '-');
                  AdHelper.showInterstitialAdImmediately(() {
                    context.push('/player/${player.id}/$slug');
                  });
                },
                child: _PlayerCard(player: player),
              );
            }, childCount: rolePlayers.length),
          ),
        ),
      );

      // Add Ad between sections if not premium
      if (!isPremium && sectionCount % 2 == 0) {
        sections.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: NativeAdWidget(style: NativeAdStyle.small),
            ),
          ),
        );
      }
    }

    return sections;
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider.withOpacity(0.3)
              : AppColors.lightDivider,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Player photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withOpacity(0.08),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: player.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: player.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          player.name.isNotEmpty
                              ? player.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        player.name.isNotEmpty
                            ? player.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // Player name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              player.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getRoleColor(player.role).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              player.role,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _getRoleColor(player.role),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    if (role == 'Batsman') return AppColors.primaryGreen;
    if (role == 'All-Rounder') return AppColors.accentGold;
    if (role == 'Wicket-Keeper') return Colors.blueAccent;
    if (role == 'Bowler') return Colors.redAccent;
    return Colors.grey;
  }
}
