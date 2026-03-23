import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cricket_live_score/core/constants/app_colors.dart';
import 'package:cricket_live_score/core/utils/ad_helper.dart';
import 'package:cricket_live_score/core/di/injection_container.dart';
import 'package:cricket_live_score/core/widgets/error_view.dart';
import 'package:cricket_live_score/core/widgets/shimmer_loader.dart';
import 'package:cricket_live_score/features/series/presentation/bloc/series_bloc.dart';
import 'package:cricket_live_score/features/series/domain/entities/series_entity.dart';
import 'package:cricket_live_score/features/matches/domain/entities/match_entity.dart';
import 'package:cricket_live_score/core/widgets/native_ad_widget.dart';

class SeriesDetailPage extends StatelessWidget {
  final String seriesId;
  const SeriesDetailPage({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SeriesBloc>()..add(LoadSeriesDetail(seriesId)),
      child: _SeriesDetailView(seriesId: seriesId),
    );
  }
}

class _SeriesDetailView extends StatelessWidget {
  final String seriesId;
  const _SeriesDetailView({required this.seriesId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeriesBloc, SeriesState>(
      builder: (context, state) {
        if (state.status == SeriesStatus.loading) {
          return Scaffold(appBar: AppBar(), body: const ListShimmer());
        }
        if (state.selectedSeries == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              onRetry: () =>
                  context.read<SeriesBloc>().add(LoadSeriesDetail(seriesId)),
            ),
          );
        }
        final series = state.selectedSeries!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkCardGradient
                          : AppColors.primaryGradient,
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          series.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${series.matches.length} Matches',
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
            ],
            body: _MatchesTab(series: series),
          ),
        );
      },
    );
  }
}

class _MatchesTab extends StatelessWidget {
  final Series series;
  const _MatchesTab({required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_cricket_outlined,
                size: 48,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 16),
              Text(
                'Match schedule not available',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPremium = AdHelper.isPremium;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: isPremium
          ? series.matches.length
          : series.matches.length + (series.matches.length ~/ 4),
      itemBuilder: (context, index) {
        if (!isPremium && (index + 1) % 5 == 0) {
          final adIndex = (index + 1) ~/ 5;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NativeAdWidget.forIndex(adIndex + 20), // Use unique offset
          );
        }
        final matchIndex = isPremium ? index : index - (index ~/ 5);
        if (matchIndex >= series.matches.length) return const SizedBox.shrink();

        final match = series.matches[matchIndex];
        return _SeriesMatchCard(match: match);
      },
    );
  }
}

class _SeriesMatchCard extends StatelessWidget {
  final CricketMatch match;
  const _SeriesMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        AdHelper.showInterstitialAd(() {
          context.push('/match/${match.id}', extra: match);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkDivider.withValues(alpha: 0.3)
                : AppColors.lightDivider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    match.title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (match.status == MatchStatus.live)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _TeamRow(
              name: match.team1.name,
              score: match.team1.score,
              flagUrl: match.team1.flagUrl,
            ),
            const SizedBox(height: 8),
            _TeamRow(
              name: match.team2.name,
              score: match.team2.score,
              flagUrl: match.team2.flagUrl,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    match.venue,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(match.startTime),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (match.result != null && match.result!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                match.result!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final String? score;
  final String? flagUrl;
  const _TeamRow({required this.name, this.score, this.flagUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (flagUrl != null && flagUrl!.isNotEmpty)
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: ClipOval(
              child: Image.network(
                flagUrl!,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.sports_cricket, size: 14, color: Colors.grey),
              ),
            ),
          )
        else
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score != null && score!.isNotEmpty)
          Text(
            score!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
