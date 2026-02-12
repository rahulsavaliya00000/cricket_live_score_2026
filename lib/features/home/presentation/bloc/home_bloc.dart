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

  HomeBloc({required this.repository}) : super(const HomeState()) {
    on<LoadHomeData>(_onLoadHome);
    on<RefreshHomeData>(_onRefreshHome);
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
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.error, error: e.toString()));
    }
  }

  Future<void> _onRefreshHome(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
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
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.error, error: e.toString()));
    }
  }
}
