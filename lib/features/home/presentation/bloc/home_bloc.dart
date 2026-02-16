import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricketbuzz/features/matches/data/repositories/cricket_repository.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';

// ─── Events ──────────────────────────────────────────────
abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class RefreshHomeData extends HomeEvent {}

// ─── States ──────────────────────────────────────────────
class HomeState extends Equatable {
  final HomeStatus status;
  final List<CricketMatch> liveMatches;
  final List<CricketMatch> upcomingMatches;
  final List<CricketMatch> recentMatches;
  final String? error;

  const HomeState({
    this.status = HomeStatus.initial,
    this.liveMatches = const [],
    this.upcomingMatches = const [],
    this.recentMatches = const [],
    this.error,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<CricketMatch>? liveMatches,
    List<CricketMatch>? upcomingMatches,
    List<CricketMatch>? recentMatches,
    String? error,
  }) {
    return HomeState(
      status: status ?? this.status,
      liveMatches: liveMatches ?? this.liveMatches,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      recentMatches: recentMatches ?? this.recentMatches,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    liveMatches,
    upcomingMatches,
    recentMatches,
    error,
  ];
}

enum HomeStatus { initial, loading, loaded, error }

// ─── BLoC ────────────────────────────────────────────────
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CricketRepository repository;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  HomeBloc({required this.repository}) : super(const HomeState()) {
    on<LoadHomeData>(_onLoadHome);
    on<RefreshHomeData>(
      _onRefreshHome,
      transformer: (events, mapper) {
        // Debounce: Only process the latest event within 2 seconds
        return events
            .distinct((prev, next) => true) // Ignore duplicate events
            .asyncExpand(mapper);
      },
    );
  }

  Future<void> _onLoadHome(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final results = await Future.wait([
        repository.getLiveMatches(),
        repository.getUpcomingMatches(),
        repository.getRecentMatches(),
      ]);
      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          liveMatches: results[0],
          upcomingMatches: results[1],
          recentMatches: results[2],
        ),
      );
      _lastRefreshTime = DateTime.now();
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.error, error: e.toString()));
    }
  }

  Future<void> _onRefreshHome(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    // Prevent overlapping requests
    if (_isRefreshing) {
      return;
    }

    // Prevent too frequent refreshes (minimum 5 seconds between refreshes)
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh.inSeconds < 5) {
        return; // Skip this refresh, too soon
      }
    }

    _isRefreshing = true;

    try {
      final results = await Future.wait([
        repository.getLiveMatches(),
        repository.getUpcomingMatches(),
        repository.getRecentMatches(),
      ]);

      // Only emit if data actually changed
      final hasChanges =
          _hasMatchesChanged(state.liveMatches, results[0]) ||
          _hasMatchesChanged(state.upcomingMatches, results[1]) ||
          _hasMatchesChanged(state.recentMatches, results[2]);

      if (hasChanges || state.status != HomeStatus.loaded) {
        emit(
          state.copyWith(
            status: HomeStatus.loaded,
            liveMatches: results[0],
            upcomingMatches: results[1],
            recentMatches: results[2],
          ),
        );
      }

      _lastRefreshTime = DateTime.now();
    } catch (e) {
      // Don't emit error on refresh, just keep current data
      print('Refresh error: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  bool _hasMatchesChanged(
    List<CricketMatch> oldList,
    List<CricketMatch> newList,
  ) {
    if (oldList.length != newList.length) return true;

    for (int i = 0; i < oldList.length; i++) {
      final oldMatch = oldList[i];
      final newMatch = newList[i];

      // Check if scores or status changed
      if (oldMatch.id != newMatch.id ||
          oldMatch.team1.score != newMatch.team1.score ||
          oldMatch.team2.score != newMatch.team2.score ||
          oldMatch.statusText != newMatch.statusText ||
          oldMatch.status != newMatch.status) {
        return true;
      }
    }

    return false;
  }
}
