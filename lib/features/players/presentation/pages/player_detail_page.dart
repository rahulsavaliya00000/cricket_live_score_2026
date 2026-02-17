import 'package:cached_network_image/cached_network_image.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';
import 'package:cricketbuzz/features/players/presentation/bloc/players_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerDetailPage extends StatefulWidget {
  final String playerId;
  final String playerSlug;

  const PlayerDetailPage({
    super.key,
    required this.playerId,
    required this.playerSlug,
  });

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<PlayersBloc>().add(
      LoadPlayerDetail(
        playerId: widget.playerId,
        playerSlug: widget.playerSlug,
        playerName: '', // Optional, will be fetched
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Player Profile',
          style: GoogleFonts.poppins(color: textColor),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: BlocBuilder<PlayersBloc, PlayersState>(
        builder: (context, state) {
          if (state.status == PlayersStatus.loadingPlayer) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == PlayersStatus.error) {
            return Center(
              child: Text(
                'Error: ${state.error}',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          } else if (state.selectedPlayer != null) {
            return _buildPlayerContent(
              state.selectedPlayer!,
              isDark,
              cardColor,
              textColor,
              secondaryTextColor,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildPlayerContent(
    Player player,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            player,
            isDark,
            cardColor,
            textColor,
            secondaryTextColor,
          ),
          const SizedBox(height: 16),
          // ─── Quick Stats Cards ─────────────
          if (player.battingStats.isNotEmpty || player.bowlingStats.isNotEmpty)
            _buildQuickStats(
              player,
              isDark,
              cardColor,
              textColor,
              secondaryTextColor,
            ),
          const SizedBox(height: 24),
          if (_hasPersonalInfo(player)) ...[
            _buildSection(
              'Personal Information',
              _buildPersonalInfo(player, textColor, secondaryTextColor),
              isDark,
              cardColor,
              textColor,
            ),
            const SizedBox(height: 24),
          ],
          // ─── Teams ─────────────────────────
          if (player.teams.isNotEmpty) ...[
            _buildSection(
              'Teams',
              _buildTeams(player, isDark, textColor),
              isDark,
              cardColor,
              textColor,
            ),
            const SizedBox(height: 24),
          ],
          if (player.bio.isNotEmpty) ...[
            _buildSection(
              'Bio',
              Text(
                player.bio,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                  color: secondaryTextColor,
                ),
              ),
              isDark,
              cardColor,
              textColor,
            ),
            const SizedBox(height: 24),
          ],
          _buildSection(
            'Batting Stats',
            _buildStatsTable(
              player.battingStats,
              isBatting: true,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            ),
            isDark,
            cardColor,
            textColor,
          ),
          const SizedBox(height: 24),
          if (player.bowlingStats.isNotEmpty) ...[
            _buildSection(
              'Bowling Stats',
              _buildStatsTable(
                player.bowlingStats,
                isBatting: false,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                isDark: isDark,
              ),
              isDark,
              cardColor,
              textColor,
            ),
            const SizedBox(height: 24),
          ],
          // ─── Recent Performances ───────────
          if (player.recentPerformances.isNotEmpty) ...[
            _buildSection(
              'Recent Performances',
              _buildRecentPerformances(
                player,
                isDark,
                textColor,
                secondaryTextColor,
              ),
              isDark,
              cardColor,
              textColor,
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    Player player,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'player_${player.id}',
            child: CircleAvatar(
              radius: 40,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              backgroundImage: player.imageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(player.imageUrl)
                  : null,
              child: player.imageUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: isDark ? Colors.grey[600] : Colors.grey,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  player.country,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (player.role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      player.role,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    Widget content,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
          ),
          child: content,
        ),
      ],
    );
  }

  String? _calculateAge(Player player) {
    // Try dateOfBirth first, then parse from born string
    DateTime? dob = player.dateOfBirth;
    if (dob == null && player.born.isNotEmpty) {
      // Try to parse common formats like "October 18, 1988" or "18 Oct 1988"
      try {
        final months = {
          'jan': 1,
          'january': 1,
          'feb': 2,
          'february': 2,
          'mar': 3,
          'march': 3,
          'apr': 4,
          'april': 4,
          'may': 5,
          'jun': 6,
          'june': 6,
          'jul': 7,
          'july': 7,
          'aug': 8,
          'august': 8,
          'sep': 9,
          'september': 9,
          'oct': 10,
          'october': 10,
          'nov': 11,
          'november': 11,
          'dec': 12,
          'december': 12,
        };
        // Extract all numbers and month name
        final cleaned = player.born.replaceAll(',', '').trim();
        final parts = cleaned.split(RegExp(r'\s+'));
        int? year, month, day;
        for (final p in parts) {
          final num = int.tryParse(p);
          if (num != null) {
            if (num > 31) {
              year = num;
            } else {
              day = num;
            }
          } else {
            final m = months[p.toLowerCase()];
            if (m != null) month = m;
          }
        }
        if (year != null && month != null) {
          dob = DateTime(year, month, day ?? 1);
        }
      } catch (_) {}
    }
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return '$age years';
  }

  Widget _buildPersonalInfo(
    Player player,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final age = _calculateAge(player);
    return Column(
      children: [
        _buildInfoRow('Born', player.born, textColor, secondaryTextColor),
        if (age != null)
          _buildInfoRow('Age', age, textColor, secondaryTextColor),
        if (player.height.isNotEmpty)
          _buildInfoRow('Height', player.height, textColor, secondaryTextColor),
        _buildInfoRow(
          'Batting Style',
          player.battingStyle,
          textColor,
          secondaryTextColor,
        ),
        if (player.bowlingStyle.isNotEmpty)
          _buildInfoRow(
            'Bowling Style',
            player.bowlingStyle,
            textColor,
            secondaryTextColor,
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color textColor,
    Color secondaryTextColor,
  ) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTable(
    Map<String, PlayerStats> statsMap, {
    required bool isBatting,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
  }) {
    if (statsMap.isEmpty) {
      return Text(
        'No stats available',
        style: GoogleFonts.poppins(color: secondaryTextColor),
      );
    }

    // Determine formats (Test, ODI, T20, IPL)
    final formats = ['Test', 'ODI', 'T20', 'IPL'];
    // Filter to only existing formats
    final availableFormats = formats
        .where((f) => statsMap.containsKey(f))
        .toList();
    // Add any others found
    statsMap.keys.forEach((k) {
      if (!availableFormats.contains(k)) availableFormats.add(k);
    });

    if (availableFormats.isEmpty) return const SizedBox.shrink();

    final headerStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    final cellStyle = GoogleFonts.poppins(color: textColor);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: MaterialStateProperty.all(
          isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        ),
        columns: [
          DataColumn(label: Text('Format', style: headerStyle)),
          DataColumn(label: Text('Mat', style: headerStyle)),
          if (isBatting) ...[
            DataColumn(label: Text('Runs', style: headerStyle)),
            DataColumn(label: Text('Avg', style: headerStyle)),
            DataColumn(label: Text('SR', style: headerStyle)),
            DataColumn(label: Text('HS', style: headerStyle)),
            DataColumn(label: Text('100s', style: headerStyle)),
          ] else ...[
            // Bowling
            DataColumn(label: Text('Wkts', style: headerStyle)),
            DataColumn(label: Text('Eco', style: headerStyle)),
            DataColumn(label: Text('Avg', style: headerStyle)),
            DataColumn(label: Text('Best', style: headerStyle)),
            DataColumn(label: Text('5W', style: headerStyle)),
          ],
        ],
        rows: availableFormats.map((fmt) {
          final stats = statsMap[fmt]!;
          return DataRow(
            cells: [
              DataCell(
                Text(
                  fmt,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              DataCell(Text(stats.matches.toString(), style: cellStyle)),
              if (isBatting) ...[
                DataCell(Text(stats.runs.toString(), style: cellStyle)),
                DataCell(Text(stats.average.toString(), style: cellStyle)),
                DataCell(Text(stats.strikeRate.toString(), style: cellStyle)),
                DataCell(Text(stats.highestScore.toString(), style: cellStyle)),
                DataCell(Text(stats.hundreds.toString(), style: cellStyle)),
              ] else ...[
                DataCell(Text(stats.wickets.toString(), style: cellStyle)),
                DataCell(Text(stats.economy.toString(), style: cellStyle)),
                DataCell(
                  Text(stats.bowlingAverage.toString(), style: cellStyle),
                ),
                DataCell(Text(stats.bestBowling, style: cellStyle)),
                DataCell(Text(stats.fiveWickets.toString(), style: cellStyle)),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  bool _hasPersonalInfo(Player player) {
    return player.born.isNotEmpty ||
        player.height.isNotEmpty ||
        player.battingStyle.isNotEmpty ||
        player.bowlingStyle.isNotEmpty;
  }

  // ─── Quick Stats Cards ──────────────────────────────────
  Widget _buildQuickStats(
    Player player,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    // Aggregate stats across all formats
    int totalMatches = 0;
    int totalRuns = 0;
    int totalWickets = 0;
    int totalHundreds = 0;

    for (final s in player.battingStats.values) {
      totalMatches += s.matches;
      totalRuns += s.runs;
      totalHundreds += s.hundreds;
    }
    for (final s in player.bowlingStats.values) {
      totalWickets += s.wickets;
      // Only add matches if batting stats didn't cover it
      if (player.battingStats.isEmpty) totalMatches += s.matches;
    }

    return Row(
      children: [
        _statCard(
          'Matches',
          totalMatches.toString(),
          Icons.sports_cricket_rounded,
          isDark,
          cardColor,
          textColor,
          secondaryTextColor,
        ),
        const SizedBox(width: 8),
        _statCard(
          'Runs',
          totalRuns.toString(),
          Icons.trending_up_rounded,
          isDark,
          cardColor,
          textColor,
          secondaryTextColor,
        ),
        const SizedBox(width: 8),
        _statCard(
          'Wickets',
          totalWickets.toString(),
          Icons.gps_fixed_rounded,
          isDark,
          cardColor,
          textColor,
          secondaryTextColor,
        ),
        const SizedBox(width: 8),
        _statCard(
          '100s',
          totalHundreds.toString(),
          Icons.star_rounded,
          isDark,
          cardColor,
          textColor,
          secondaryTextColor,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryGreen),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Teams Chips ────────────────────────────────────────
  Widget _buildTeams(Player player, bool isDark, Color textColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: player.teams.map((team) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryGreen.withOpacity(0.15)
                : AppColors.primaryGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_rounded,
                size: 14,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 6),
              Text(
                team,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Recent Performances ────────────────────────────────
  Widget _buildRecentPerformances(
    Player player,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Column(
      children: player.recentPerformances.map((perf) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ),
            child: Row(
              children: [
                // Match Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sports_cricket_rounded,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs ${perf.against}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perf.matchTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Runs & Wickets badges
                if (perf.runs.isNotEmpty && perf.runs != '0')
                  _perfBadge('${perf.runs}r', Colors.blue, isDark),
                const SizedBox(width: 6),
                if (perf.wickets.isNotEmpty && perf.wickets != '0')
                  _perfBadge(
                    '${perf.wickets}w',
                    AppColors.primaryGreen,
                    isDark,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _perfBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
