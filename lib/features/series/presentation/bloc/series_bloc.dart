import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricketbuzz/features/matches/data/repositories/cricket_repository.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

// ─── Events ──────────────────────────────────────────────
abstract class SeriesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSeries extends SeriesEvent {}

class LoadSeriesDetail extends SeriesEvent {
  final String seriesId;
  LoadSeriesDetail(this.seriesId);
  @override
  List<Object?> get props => [seriesId];
}

class SelectSeriesType extends SeriesEvent {
  final SeriesType? type;
  SelectSeriesType(this.type);
  @override
  List<Object?> get props => [type];
}

class SearchSeries extends SeriesEvent {
  final String query;
  SearchSeries(this.query);
  @override
  List<Object?> get props => [query];
}

// ─── States ──────────────────────────────────────────────
class SeriesState extends Equatable {
  final SeriesStatus status;
  final List<Series> seriesList;
  final List<Series> filteredSeries;
  final Series? selectedSeries;
  final SeriesType? selectedType; // null = All
  final String searchQuery;
  final String? error;

  const SeriesState({
    this.status = SeriesStatus.initial,
    this.seriesList = const [],
    this.filteredSeries = const [],
    this.selectedSeries,
    this.selectedType = SeriesType.ipl,
    this.searchQuery = '',
    this.error,
  });

  SeriesState copyWith({
    SeriesStatus? status,
    List<Series>? seriesList,
    List<Series>? filteredSeries,
    Series? selectedSeries,
    SeriesType? selectedType,
    String? searchQuery,
    String? error,
  }) {
    return SeriesState(
      status: status ?? this.status,
      seriesList: seriesList ?? this.seriesList,
      filteredSeries: filteredSeries ?? this.filteredSeries,
      selectedSeries: selectedSeries ?? this.selectedSeries,
      selectedType:
          selectedType, // Allow nullable (can't use ?? if intended to be null, but copyWith usually ignores null inputs as "no change")
      // To properly handle setting to null, we'd need a sentinel or check equality.
      // For simplicity here, if passed as argument it overrides.
      // But standard copyWith pattern: type ?? this.type.
      // We will handle resetting explicitly.
      // Actually standard pattern: selectedType: selectedType ?? this.selectedType.
      // If we want to set to null, we need to pass a specific value or use a wrapper.
      // Let's stick to standard and assume if we want to clear it, we might need a separate mechanism or just be careful.
      // Wait, standard copyWith prevents setting to null if property is nullable.
      // Let's change signature to allow nullable update.
      // Using a trick: `Object? selectedType = const _Sentinel()`
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }

  // Custom copyWith to allow setting selectedType to null
  SeriesState copyWithState({
    SeriesStatus? status,
    List<Series>? seriesList,
    List<Series>? filteredSeries,
    Series? selectedSeries,
    SeriesType? selectedType,
    bool forceNullType = false,
    String? searchQuery,
    String? error,
  }) {
    return SeriesState(
      status: status ?? this.status,
      seriesList: seriesList ?? this.seriesList,
      filteredSeries: filteredSeries ?? this.filteredSeries,
      selectedSeries: selectedSeries ?? this.selectedSeries,
      selectedType: forceNullType ? null : (selectedType ?? this.selectedType),
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    seriesList,
    filteredSeries,
    selectedSeries,
    selectedType,
    searchQuery,
    error,
  ];
}

enum SeriesStatus { initial, loading, loaded, error }

// ─── BLoC ────────────────────────────────────────────────
class SeriesBloc extends Bloc<SeriesEvent, SeriesState> {
  final CricketRepository repository;

  SeriesBloc({required this.repository}) : super(const SeriesState()) {
    on<LoadSeries>(_onLoadSeries);
    on<LoadSeriesDetail>(_onLoadSeriesDetail);
    on<SearchSeries>(_onSearchSeries);
    on<SelectSeriesType>(_onSelectSeriesType);
  }

  Future<void> _onLoadSeries(
    LoadSeries event,
    Emitter<SeriesState> emit,
  ) async {
    emit(state.copyWithState(status: SeriesStatus.loading));
    try {
      final list = await repository.getSeries();

      // Sort logic
      final now = DateTime.now();
      final live = <Series>[];
      final upcoming = <Series>[];
      final recent = <Series>[];

      for (final s in list) {
        if (s.startDateTime != null && s.endDateTime != null) {
          if (now.isAfter(s.startDateTime!) && now.isBefore(s.endDateTime!)) {
            live.add(s);
          } else if (now.isBefore(s.startDateTime!)) {
            upcoming.add(s);
          } else {
            recent.add(s);
          }
        } else {
          recent.add(s);
        }
      }

      // 1. Live: Newest started first
      live.sort((a, b) => b.startDateTime!.compareTo(a.startDateTime!));

      // 2. Upcoming: Starting soonest first
      upcoming.sort((a, b) => a.startDateTime!.compareTo(b.startDateTime!));

      // 3. Recent: Recently ended first (or fallback to original order if no dates)
      recent.sort((a, b) {
        if (a.endDateTime != null && b.endDateTime != null) {
          return b.endDateTime!.compareTo(a.endDateTime!);
        }
        return 0;
      });

      final sortedList = [...live, ...upcoming, ...recent];

      emit(
        state.copyWithState(
          status: SeriesStatus.loaded,
          seriesList: sortedList,
        ),
      );
      // Apply filters (which defaults to IPL now)
      _applyFilters(emit);
    } catch (e) {
      emit(
        state.copyWithState(status: SeriesStatus.error, error: e.toString()),
      );
    }
  }

  Future<void> _onLoadSeriesDetail(
    LoadSeriesDetail event,
    Emitter<SeriesState> emit,
  ) async {
    emit(state.copyWithState(status: SeriesStatus.loading));
    try {
      final series = await repository.getSeriesDetail(event.seriesId);

      final updatedSeries = Series(
        id: series.id,
        name: series.name,
        startDate: series.startDate,
        endDate: series.endDate,
        matches: series.matches,
        type: series.type,
      );

      emit(
        state.copyWithState(
          status: SeriesStatus.loaded,
          selectedSeries: updatedSeries,
        ),
      );
    } catch (e) {
      emit(
        state.copyWithState(status: SeriesStatus.error, error: e.toString()),
      );
    }
  }

  void _onSearchSeries(SearchSeries event, Emitter<SeriesState> emit) {
    emit(state.copyWithState(searchQuery: event.query));
    _applyFilters(emit);
  }

  void _onSelectSeriesType(SelectSeriesType event, Emitter<SeriesState> emit) {
    // Toggle off if same type selected? Or just enforce usage.
    // Usually chip selection: clicking same might do nothing or untoggle.
    // Let's assume explicit selection. If they want 'All', they pass null.

    // If user taps the already selected filter, preserve it (don't toggle off here unless UI handles it)
    // Actually, UI usually has an "All" chip.
    emit(
      state.copyWithState(
        selectedType: event.type,
        forceNullType: event.type == null,
      ),
    );
    _applyFilters(emit);
  }

  void _applyFilters(Emitter<SeriesState> emit) {
    var filtered = state.seriesList;

    // 1. Apply Type Filter
    if (state.selectedType != null) {
      filtered = filtered.where((s) {
        if (state.selectedType == SeriesType.t20League) {
          // Include both IPL and generic T20 League
          return s.type == SeriesType.t20League || s.type == SeriesType.ipl;
        }
        return s.type == state.selectedType;
      }).toList();
    }

    // 2. Apply Search Filter
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.name.toLowerCase().contains(state.searchQuery.toLowerCase()),
          )
          .toList();
    }

    emit(state.copyWithState(filteredSeries: filtered));
  }
}
