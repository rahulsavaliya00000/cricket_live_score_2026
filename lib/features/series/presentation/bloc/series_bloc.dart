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

// ─── States ──────────────────────────────────────────────
class SeriesState extends Equatable {
  final SeriesStatus status;
  final List<Series> seriesList;
  final Series? selectedSeries;
  final String? error;

  const SeriesState({
    this.status = SeriesStatus.initial,
    this.seriesList = const [],
    this.selectedSeries,
    this.error,
  });

  SeriesState copyWith({
    SeriesStatus? status,
    List<Series>? seriesList,
    Series? selectedSeries,
    String? error,
  }) {
    return SeriesState(
      status: status ?? this.status,
      seriesList: seriesList ?? this.seriesList,
      selectedSeries: selectedSeries ?? this.selectedSeries,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, seriesList, selectedSeries, error];
}

enum SeriesStatus { initial, loading, loaded, error }

// ─── BLoC ────────────────────────────────────────────────
class SeriesBloc extends Bloc<SeriesEvent, SeriesState> {
  final CricketRepository repository;

  SeriesBloc({required this.repository}) : super(const SeriesState()) {
    on<LoadSeries>(_onLoadSeries);
    on<LoadSeriesDetail>(_onLoadSeriesDetail);
  }

  Future<void> _onLoadSeries(
    LoadSeries event,
    Emitter<SeriesState> emit,
  ) async {
    emit(state.copyWith(status: SeriesStatus.loading));
    try {
      final list = await repository.getSeries();
      emit(state.copyWith(status: SeriesStatus.loaded, seriesList: list));
    } catch (e) {
      emit(state.copyWith(status: SeriesStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadSeriesDetail(
    LoadSeriesDetail event,
    Emitter<SeriesState> emit,
  ) async {
    emit(state.copyWith(status: SeriesStatus.loading));
    try {
      final series = await repository.getSeriesDetail(event.seriesId);
      emit(state.copyWith(status: SeriesStatus.loaded, selectedSeries: series));
    } catch (e) {
      emit(state.copyWith(status: SeriesStatus.error, error: e.toString()));
    }
  }
}
