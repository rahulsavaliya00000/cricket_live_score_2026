import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cricketbuzz/core/constants/app_colors.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';
import 'package:cricketbuzz/core/widgets/shimmer_loader.dart';
import 'package:cricketbuzz/core/widgets/error_view.dart';
import 'package:cricketbuzz/features/series/presentation/bloc/series_bloc.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';
import 'package:cricketbuzz/core/widgets/native_ad_widget.dart';

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

          return Column(
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: state.selectedType == null,
                      onSelected: (selected) {
                        if (selected) {
                          AdHelper.showInterstitialAd(() {
                            context.read<SeriesBloc>().add(
                              SelectSeriesType(null),
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'IPL',
                      isSelected: state.selectedType == SeriesType.ipl,
                      onSelected: (selected) {
                        if (selected) {
                          AdHelper.showInterstitialAd(() {
                            context.read<SeriesBloc>().add(
                              SelectSeriesType(SeriesType.ipl),
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'International',
                      isSelected:
                          state.selectedType == SeriesType.international,
                      onSelected: (selected) {
                        if (selected) {
                          AdHelper.showInterstitialAd(() {
                            context.read<SeriesBloc>().add(
                              SelectSeriesType(SeriesType.international),
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'T20 Leagues',
                      isSelected: state.selectedType == SeriesType.t20League,
                      onSelected: (selected) {
                        if (selected) {
                          AdHelper.showInterstitialAd(() {
                            context.read<SeriesBloc>().add(
                              SelectSeriesType(SeriesType.t20League),
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Domestic',
                      isSelected: state.selectedType == SeriesType.domestic,
                      onSelected: (selected) {
                        if (selected) {
                          AdHelper.showInterstitialAd(() {
                            context.read<SeriesBloc>().add(
                              SelectSeriesType(SeriesType.domestic),
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Women',
                      isSelected: state.selectedType == SeriesType.women,
                      onSelected: (selected) {
                        if (selected) {
                          AdHelper.showInterstitialAd(() {
                            context.read<SeriesBloc>().add(
                              SelectSeriesType(SeriesType.women),
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final seriesList = state.filteredSeries;
                    if (seriesList.isEmpty &&
                        state.status == SeriesStatus.loaded) {
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
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: seriesList.length + (seriesList.length ~/ 2),
                      itemBuilder: (context, index) {
                        if ((index + 1) % 3 == 0) {
                          final adNumber = (index + 1) ~/ 3;
                          return NativeAdWidget.forIndex(adNumber);
                        }
                        final seriesIndex = index - (index ~/ 3);
                        return _SeriesCard(series: seriesList[seriesIndex]);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primaryGreen,
      labelStyle: GoogleFonts.poppins(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // Material 3 overrides selectedColor — use color to force correct styling
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryGreen;
        }
        return isDark ? const Color(0xFF1E1E1E) : Colors.grey[100];
      }),
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
    String typeLabel = series.type.name.toUpperCase();

    switch (series.type) {
      case SeriesType.international:
        typeColor = AppColors.primaryGreen;
        break;
      case SeriesType.domestic:
        typeColor = AppColors.accentOrange;
        break;
      case SeriesType.t20League:
      case SeriesType.ipl:
        typeColor = AppColors.accentGold;
        typeLabel = 'T20 LEAGUE';
        if (series.type == SeriesType.ipl) typeLabel = 'IPL';
        break;
      default:
        typeColor = AppColors.accentGold;
        break;
    }
    return GestureDetector(
      onTap: () {
        AdHelper.showInterstitialAd(() {
          context.push('/series-detail/${series.id}');
        });
      },
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
                    typeLabel,
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
              '${series.startDate} - ${series.endDate}',
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
}
