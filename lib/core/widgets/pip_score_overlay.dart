import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/core/widgets/team_flag.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';

class PipScoreOverlay extends StatelessWidget {
  final CricketMatch match;

  const PipScoreOverlay({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTeamRow(match.team1),
            const SizedBox(height: 8),
            _buildTeamRow(match.team2),
            if (match.statusText != null && match.statusText!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  match.statusText!,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(Team team) {
    return Row(
      children: [
        TeamFlag(flagUrl: team.flagUrl, size: 24),
        const SizedBox(width: 10),
        Text(
          team.shortName,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              team.score ?? 'Yet to Bat',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (team.overs != null && team.overs!.isNotEmpty)
              Text(
                '(${team.overs} ov)',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
