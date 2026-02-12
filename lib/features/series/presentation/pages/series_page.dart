import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/features/series/presentation/bloc/series_bloc.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

class SeriesPage extends StatefulWidget {
  const SeriesPage({super.key});

  @override
  State<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends State<SeriesPage> {
  @override
  void initState() {
    super.initState();
    if (context.read<SeriesBloc>().state.status == SeriesStatus.initial) {
      context.read<SeriesBloc>().add(LoadSeries());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Series',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) =>
                  context.read<SeriesBloc>().add(SearchSeries(value)),
              decoration: InputDecoration(
                hintText: 'Search series...',
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
      body: BlocBuilder<SeriesBloc, SeriesState>(
        builder: (context, state) {
          if (state.status == SeriesStatus.loading &&
              state.seriesList.isEmpty) {
            return const ListShimmer(itemCount: 5);
          }
          if (state.status == SeriesStatus.error) {
            return ErrorView(
              message: state.error ?? 'Failed to load series',
              onRetry: () => context.read<SeriesBloc>().add(LoadSeries()),
            );
          }
          final seriesList = state.filteredSeries;
          if (seriesList.isEmpty && state.status == SeriesStatus.loaded) {
            return Center(
              child: Text(
                'No series found',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: seriesList.length,
            itemBuilder: (context, index) {
              return _SeriesCard(series: seriesList[index]);
            },
          );
        },
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final Series series;
  const _SeriesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color typeColor;
    switch (series.type) {
      case SeriesType.international:
        typeColor = AppColors.primaryGreen;
        break;
      case SeriesType.domestic:
        typeColor = AppColors.accentOrange;
        break;
      default:
        typeColor = AppColors.accentGold;
        break;
    }
    return GestureDetector(
      onTap: () => context.push('/series-detail/${series.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    series.type.name.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              series.name,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${series.startDate} - ${series.endDate} • ${series.matches.length} matches',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Start/end dates are already formatted strings
  // No date conversion needed
}
