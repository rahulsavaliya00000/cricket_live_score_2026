import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/features/players/presentation/bloc/players_bloc.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  @override
  void initState() {
    super.initState();
    if (context.read<PlayersBloc>().state.status == PlayersStatus.initial) {
      context.read<PlayersBloc>().add(LoadPlayers());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Players',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) =>
                  context.read<PlayersBloc>().add(SearchPlayers(value)),
              decoration: InputDecoration(
                hintText: 'Search players or countries...',
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
          if (state.status == PlayersStatus.loading && state.players.isEmpty) {
            return const ListShimmer(itemCount: 5);
          }
          if (state.status == PlayersStatus.error) {
            return ErrorView(
              message: state.error ?? 'Failed to load players',
              onRetry: () => context.read<PlayersBloc>().add(LoadPlayers()),
            );
          }
          final players = state.filteredPlayers;
          if (players.isEmpty && state.status == PlayersStatus.loaded) {
            return Center(
              child: Text(
                'No players found',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return _PlayerCard(player: player);
            },
          );
        },
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/player/${player.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.darkDivider.withValues(alpha: 0.3)
                : AppColors.lightDivider,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                image: player.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(player.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: player.imageUrl.isEmpty
                  ? (player.name.trim().isNotEmpty
                        ? Text(
                            player.name.trim()[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: AppColors.primaryGreen,
                          ))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name.trim().isNotEmpty
                        ? player.name
                        : 'Unknown Player',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${player.country.trim().isNotEmpty ? player.country : 'Unknown Country'} • ${player.role}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22),
          ],
        ),
      ),
    );
  }
}
