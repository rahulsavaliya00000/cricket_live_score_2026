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

class IplSquadsPage extends StatefulWidget {
  const IplSquadsPage({super.key});

  @override
  State<IplSquadsPage> createState() => _IplSquadsPageState();
}

class _IplSquadsPageState extends State<IplSquadsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch series ID from remote config
    final seriesId = RemoteConfigService.instance.iplScheduleSeriesId;
    if (seriesId.isNotEmpty) {
      context.read<PlayersBloc>().add(LoadIplSquads(seriesId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IPL 2026 Squads',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocBuilder<PlayersBloc, PlayersState>(
        builder: (context, state) {
          if (state.status == PlayersStatus.loadingIplSquads &&
              state.iplTeams.isEmpty) {
            return const ListShimmer(itemCount: 6);
          }
          if (state.status == PlayersStatus.error && state.iplTeams.isEmpty) {
            return ErrorView(
              message: state.error ?? 'Failed to load IPL squads',
              onRetry: () {
                final seriesId =
                    RemoteConfigService.instance.iplScheduleSeriesId;
                if (seriesId.isNotEmpty) {
                  context.read<PlayersBloc>().add(LoadIplSquads(seriesId));
                }
              },
            );
          }
          
          final teams = state.iplTeams;
          if (teams.isEmpty && state.status != PlayersStatus.loadingIplSquads) {
            return Center(
              child: Text(
                'No IPL squads found',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            );
          }

          final isPremium = AdHelper.isPremium;
          final teamRows = (teams.length / 2).ceil();
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: isPremium ? teamRows : teamRows + (teamRows ~/ 3),
            itemBuilder: (context, index) {
              if (!isPremium && (index + 1) % 4 == 0) {
                final adIndex = (index + 1) ~/ 4;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: NativeAdWidget.forIndex(adIndex + 30),
                );
              }
              
              final rowIndex = isPremium ? index : index - (index ~/ 4);
              if (rowIndex >= teamRows) return const SizedBox.shrink();

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
                        aspectRatio: 1.2,
                        child: _IplTeamTile(team: team1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: team2 != null
                          ? AspectRatio(
                              aspectRatio: 1.2,
                              child: _IplTeamTile(team: team2),
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

class _IplTeamTile extends StatelessWidget {
  final CricketTeam team;
  const _IplTeamTile({required this.team});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        AdHelper.showInterstitialAdImmediately(() {
          context.push(
            '/team-players/${team.slug}/${team.id}',
            extra: team.name, // Pass generic team name, existing page will use this
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
            // Flag/Logo
            if (team.flagUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: team.flagUrl,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      team.name.isNotEmpty ? team.name[0] : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    team.name.isNotEmpty ? team.name[0] : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                team.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
