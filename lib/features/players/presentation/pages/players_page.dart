import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/core/services/remote_config_service.dart';
import 'package:cricketbuzz/features/players/presentation/bloc/players_bloc.dart';
import 'package:cricketbuzz/features/players/domain/entities/team_entity.dart';
import 'package:cricketbuzz/core/widgets/native_ad_widget.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<PlayersBloc>();
    if (bloc.state.status == PlayersStatus.initial) {
      bloc.add(LoadTeams());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Teams',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) =>
                  context.read<PlayersBloc>().add(SearchTeams(value)),
              decoration: InputDecoration(
                hintText: 'Search teams...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<PlayersBloc, PlayersState>(
        builder: (context, state) {
          if (state.status == PlayersStatus.loading && state.teams.isEmpty) {
            return const ListShimmer(itemCount: 6);
          }
          if (state.status == PlayersStatus.error && state.teams.isEmpty) {
            return ErrorView(
              message: state.error ?? 'Failed to load teams',
              onRetry: () => context.read<PlayersBloc>().add(LoadTeams()),
            );
          }
          final teams = state.filteredTeams;
          if (teams.isEmpty) {
            return Center(
              child: Text(
                'No teams found',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            );
          }
          final teamRows = (teams.length / 2).ceil();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: teamRows + (teamRows ~/ 2) + 1, // +1 for the banner
            itemBuilder: (context, index) {
              // 0. IPL Banner
              if (index == 0) {
                final hasIpl = RemoteConfigService.instance.iplScheduleSeriesId.isNotEmpty;
                if (!hasIpl) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _IplBannerCard(),
                );
              }

              // Adjust index after banner
              final listIndex = index - 1;

              // 1. Ad Row
              if ((listIndex + 1) % 3 == 0) {
                final adNumber = (listIndex + 1) ~/ 3;
                return NativeAdWidget.forIndex(adNumber);
              }

              // 2. Team Row
              final adCountBefore = listIndex ~/ 3;
              final rowIndex = listIndex - adCountBefore;
              final teamIndex = rowIndex * 2;

              if (teamIndex >= teams.length) return const SizedBox.shrink();

              final team1 = teams[teamIndex];
              final team2 = (teamIndex + 1 < teams.length)
                  ? teams[teamIndex + 1]
                  : null;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.4,
                        child: _TeamTile(team: team1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: team2 != null
                          ? AspectRatio(
                              aspectRatio: 1.4,
                              child: _TeamTile(team: team2),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _IplBannerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/ipl-squads');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)], // Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: 'https://img1.hscicdn.com/image/upload/f_auto,t_ds_wide_w_800/lsci/db/PICTURES/CMS/331100/331163.6.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  color: Colors.black38,
                  colorBlendMode: BlendMode.darken,
                  errorWidget: (context, url, error) => const SizedBox.shrink(), // Gracefully hide if 404
                ),
              ),
              // Gold border overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5), // Gold
                    width: 1.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700), // Gold badge
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SPECIAL',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4A148C),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'IPL 2026 Squads',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'View all teams & players',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFFFD700),
                      size: 24,
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
}

class _TeamTile extends StatelessWidget {
  final CricketTeam team;
  const _TeamTile({required this.team});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        AdHelper.showInterstitialAdImmediately(() {
          context.push(
            '/team-players/${team.slug}/${team.id}',
            extra: team.name,
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkCard,
                    AppColors.darkCard.withValues(alpha: 0.8),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkDivider.withValues(alpha: 0.3)
                : AppColors.lightDivider,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flag
            if (team.flagUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: team.flagUrl,
                width: 48,
                height: 36,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      team.name.isNotEmpty ? team.name[0] : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    team.name.isNotEmpty ? team.name[0] : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              team.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
