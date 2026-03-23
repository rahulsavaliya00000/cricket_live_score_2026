import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/features/wallet/presentation/bloc/leaderboard_cubit.dart';
import 'package:cricketbuzz/features/wallet/presentation/bloc/leaderboard_state.dart';
import 'package:cricketbuzz/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:cricketbuzz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cricketbuzz/core/di/injection_container.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LeaderboardCubit>(),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatefulWidget {
  const _LeaderboardView();

  @override
  State<_LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<_LeaderboardView> {
  @override
  void initState() {
    super.initState();
    // Sync user data to leaderboard
    final walletState = context.read<WalletCubit>().state;
    final authState = context.read<AuthBloc>().state;
    String? userName;
    String? userPhoto;

    if (authState is Authenticated) {
      userName = authState.user.name;
      userPhoto = authState.user.photoUrl;
    }

    context.read<LeaderboardCubit>().updateUserData(
      coins: walletState.irCoins.toDouble(),
      balls: walletState.balls,
      bats: walletState.bats,
      name: userName,
      avatarUrl: userPhoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
              builder: (context, state) {
                final sortedPlayers = context
                    .read<LeaderboardCubit>()
                    .getSortedPlayers();

                if (sortedPlayers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.only(bottom: 150),
                      children: [
                        const SizedBox(height: 20),
                        _buildPodium(sortedPlayers.take(3).toList()),
                        const SizedBox(height: 30),
                        _buildList(sortedPlayers.skip(3).toList(), isDark),
                      ],
                    ),
                    _buildUserSticky(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _filterItem(
                context,
                'IR Coins',
                LeaderboardFilter.coins,
                state.filter,
              ),
              _filterItem(
                context,
                'Balls',
                LeaderboardFilter.balls,
                state.filter,
              ),
              _filterItem(
                context,
                'Bats',
                LeaderboardFilter.bats,
                state.filter,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterItem(
    BuildContext context,
    String title,
    LeaderboardFilter filter,
    LeaderboardFilter active,
  ) {
    final isSelected = filter == active;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AdHelper.showInterstitialAd(() {
            context.read<LeaderboardCubit>().setFilter(filter);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardPlayer> top3) {
    if (top3.length < 3) return const SizedBox();

    // Podium order: 2nd, 1st, 3rd
    final second = top3[1];
    final first = top3[0];
    final third = top3[2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _podiumItem(second, 2, 70),
          const SizedBox(width: 10),
          _podiumItem(first, 1, 100),
          const SizedBox(width: 10),
          _podiumItem(third, 3, 60),
        ],
      ),
    );
  }

  Widget _podiumItem(LeaderboardPlayer player, int rank, double height) {
    final color = rank == 1
        ? Colors.amber
        : (rank == 2 ? Colors.blueGrey[300] : Colors.brown[300]);
    final avatarSize = rank == 1 ? 80.0 : 65.0;

    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color!, width: 3),
                  color: Colors.grey[200],
                ),
                child: Center(
                  child: player.hasAvatar && player.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            player.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _fallbackLetter(player, avatarSize),
                          ),
                        )
                      : _fallbackLetter(player, avatarSize),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            _getValueStr(player, context.read<LeaderboardCubit>().state.filter),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LeaderboardPlayer> players, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 7, // Show up to rank 10
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
        itemBuilder: (context, index) {
          final player = players[index];
          final rank = index + 4;
          return _playerTile(player, rank, isDark, context);
        },
      ),
    );
  }

  Widget _playerTile(
    LeaderboardPlayer player,
    int rank,
    bool isDark,
    BuildContext context,
  ) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 25,
            child: Text(
              '$rank',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: _getAvatarColor(player.name),
            child: player.hasAvatar && player.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      player.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        player.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Text(
                    player.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
      title: Text(
        player.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        _getValueStr(player, context.read<LeaderboardCubit>().state.filter),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildUserSticky(BuildContext context) {
    final cubit = context.watch<LeaderboardCubit>();
    final rank = cubit.getUserRank();
    final sorted = cubit.getSortedPlayers();
    final userIdx = sorted.indexWhere((p) => p.isUser);
    if (userIdx == -1) return const SizedBox();
    final user = sorted[userIdx];
    final currentFilter = cubit.state.filter;

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 15),
            CircleAvatar(
              radius: 20,
              backgroundColor: user.hasAvatar && user.avatarUrl != null
                  ? Colors.white
                  : _getAvatarColor(user.name),
              child: user.hasAvatar && user.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          user.name[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      user.name[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your Rank',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'You are doing great!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getValueStr(user, currentFilter),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackLetter(LeaderboardPlayer player, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getAvatarColor(player.name),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          player.name[0].toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final List<Color> googleColors = [
      const Color(0xFF4285F4), // Blue
      const Color(0xFFEA4335), // Red
      const Color(0xFFFBBC05), // Yellow
      const Color(0xFF34A853), // Green
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF00ACC1), // Cyan
      const Color(0xFFFF7043), // Orange
      const Color(0xFF5C6BC0), // Indigo
    ];

    // Deterministic selection based on name hash
    final hash = name.hashCode.abs();
    return googleColors[hash % googleColors.length];
  }

  String _getValueStr(LeaderboardPlayer player, LeaderboardFilter filter) {
    switch (filter) {
      case LeaderboardFilter.coins:
        return '${player.coins.toStringAsFixed(2)} IR';
      case LeaderboardFilter.balls:
        return '${player.balls} Balls';
      case LeaderboardFilter.bats:
        return '${player.bats} Bats';
    }
  }
}
