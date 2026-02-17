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
  final bool isRefreshing;
  final String? error;

  const HomeState({
    this.status = HomeStatus.initial,
    this.liveMatches = const [],
    this.upcomingMatches = const [],
    this.recentMatches = const [],
    this.isRefreshing = false,
    this.error,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<CricketMatch>? liveMatches,
    List<CricketMatch>? upcomingMatches,
    List<CricketMatch>? recentMatches,
    bool? isRefreshing,
    String? error,
  }) {
    return HomeState(
      status: status ?? this.status,
      liveMatches: liveMatches ?? this.liveMatches,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      recentMatches: recentMatches ?? this.recentMatches,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    liveMatches,
    upcomingMatches,
    recentMatches,
    isRefreshing,
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
      _lastRefreshTime = DateTime.now();
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.error, error: e.toString()));
    }
  }

  Future<void> _onRefreshHome(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    print('📥 RefreshHomeData event received');

    // Prevent overlapping requests
    if (_isRefreshing) {
      print('⚠️ Already refreshing, skipping...');
      return;
    }

    // Prevent too frequent refreshes (minimum 5 seconds between refreshes)
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh.inSeconds < 5) {
        print(
          '⚠️ Too soon to refresh (${timeSinceLastRefresh.inSeconds}s ago), skipping...',
        );
        return; // Skip this refresh, too soon
      }
    }

    print('✅ Starting refresh...');
    _isRefreshing = true;
    emit(state.copyWith(isRefreshing: true));

    try {
      final startTime = DateTime.now();
      print('📤 Request sent at: ${startTime.toString().split(' ')[1]}');

      final results = await Future.wait([
        repository.getLiveMatches(),
        repository.getUpcomingMatches(),
        repository.getRecentMatches(),
      ]);

      var liveMatches = results[0];
      final upcomingMatches = results[1];
      final recentMatches = results[2];

      // Apply Monotonic Score Logic for Live Matches
      liveMatches = liveMatches.map((newMatch) {
        final existingMatch = state.liveMatches.firstWhereOrNull(
          (m) => m.id == newMatch.id,
        );

        if (existingMatch == null) return newMatch;

        // Compare scores and overs to ensure progress
        final isProgress = _isScoreProgress(existingMatch, newMatch);
        if (!isProgress) {
          print('🛡️ Score jumped back for ${newMatch.id}, keeping old score');
          return existingMatch.copyWith(
            statusText: newMatch.statusText, // Allow status text updates
          );
        }
        return newMatch;
      }).toList();

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('⏱️ Duration: ${duration.inMilliseconds}ms');

      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          liveMatches: liveMatches,
          upcomingMatches: upcomingMatches,
          recentMatches: recentMatches,
          isRefreshing: false,
        ),
      );

      _lastRefreshTime = DateTime.now();
    } catch (e) {
      print('❌ Refresh error: $e');
      emit(state.copyWith(isRefreshing: false));
    } finally {
      _isRefreshing = false;
      print('✅ Refresh completed');
    }
  }

  bool _isScoreProgress(CricketMatch oldM, CricketMatch newM) {
    // Helper to evaluate if new score is actually an update
    // For simplicity, we compare runs/wickets if possible,
    // or just assume higher runs means progress.
    final oldS1 = _parseRuns(oldM.team1.score);
    final newS1 = _parseRuns(newM.team1.score);
    final oldS2 = _parseRuns(oldM.team2.score);
    final newS2 = _parseRuns(newM.team2.score);

    // If either team has fewer runs than before, it's likely a cached/old response
    if (newS1 < oldS1 || newS2 < oldS2) return false;

    // If runs are same, check overs if parsed (or just trust it)
    return true;
  }

  int _parseRuns(String? score) {
    if (score == null || score.isEmpty) return 0;
    // Extract first number (runs) before '/' or '-'
    final match = RegExp(r'(\d+)').firstMatch(score);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }
}

extension CollectionExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
