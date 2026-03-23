import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_live_score/features/matches/data/repositories/cricket_repository.dart';
import 'package:cricket_live_score/features/matches/domain/entities/match_entity.dart';

// ─── Events ──────────────────────────────────────────────
abstract class MatchDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMatchDetail extends MatchDetailEvent {
  final String matchId;
  final CricketMatch? previewMatch;
  LoadMatchDetail(this.matchId, {this.previewMatch});
  @override
  List<Object?> get props => [matchId, previewMatch];
}

class RefreshMatchDetail extends MatchDetailEvent {
  final String matchId;
  RefreshMatchDetail(this.matchId);
  @override
  List<Object?> get props => [matchId];
}

class SubscribeToLiveScore extends MatchDetailEvent {
  final String matchId;
  SubscribeToLiveScore(this.matchId);
  @override
  List<Object?> get props => [matchId];
}

class LiveScoreUpdated extends MatchDetailEvent {
  final CricketMatch match;
  LiveScoreUpdated(this.match);
  @override
  List<Object?> get props => [match];
}

// ─── States ──────────────────────────────────────────────
class MatchDetailState extends Equatable {
  final MatchDetailStatus status;
  final MatchDetail? matchDetail;
  final String? error;

  const MatchDetailState({
    this.status = MatchDetailStatus.initial,
    this.matchDetail,
    this.error,
  });

  MatchDetailState copyWith({
    MatchDetailStatus? status,
    MatchDetail? matchDetail,
    String? error,
  }) {
    return MatchDetailState(
      status: status ?? this.status,
      matchDetail: matchDetail ?? this.matchDetail,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, matchDetail, error];
}

enum MatchDetailStatus { initial, loading, loaded, error }

// ─── BLoC ────────────────────────────────────────────────
class MatchDetailBloc extends Bloc<MatchDetailEvent, MatchDetailState> {
  final CricketRepository repository;
  StreamSubscription? _liveSubscription;

  MatchDetailBloc({required this.repository})
    : super(const MatchDetailState()) {
    on<LoadMatchDetail>(_onLoadDetail);
    on<RefreshMatchDetail>(_onRefreshDetail);
    on<SubscribeToLiveScore>(_onSubscribeLive);
    on<LiveScoreUpdated>(_onLiveUpdate);
  }

  Future<void> _onLoadDetail(
    LoadMatchDetail event,
    Emitter<MatchDetailState> emit,
  ) async {
    if (event.previewMatch != null) {
      emit(
        state.copyWith(
          status: MatchDetailStatus.loading,
          matchDetail: MatchDetail(match: event.previewMatch!),
        ),
      );
    } else {
      emit(state.copyWith(status: MatchDetailStatus.loading));
    }

    try {
      final fetchedDetail = await repository.getMatchDetail(event.matchId);

      // Merge with existing param (which might be the preview) to preserve flags
      final mergedDetail = _mergeWithPreview(state.matchDetail, fetchedDetail);

      emit(
        state.copyWith(
          status: MatchDetailStatus.loaded,
          matchDetail: mergedDetail,
        ),
      );
    } catch (e) {
      if (state.matchDetail == null) {
        emit(
          state.copyWith(status: MatchDetailStatus.error, error: e.toString()),
        );
      }
      // If we have preview data, we can silently fail or show a snackbar (not handled here),
      // but we shouldn't replace valid preview data with an error screen ideally.
    }
  }

  Future<void> _onRefreshDetail(
    RefreshMatchDetail event,
    Emitter<MatchDetailState> emit,
  ) async {
    try {
      final newDetail = await repository.getMatchDetail(event.matchId);
      final currentDetail = state.matchDetail;

      if (currentDetail != null) {
        if (!_isDetailProgress(currentDetail, newDetail)) {
          // print('🛡️ MatchDetail regression detected, skipping update');
          return;
        }
      }

      // Merge to ensure we don't lose flags on refresh either
      final mergedDetail = _mergeWithPreview(currentDetail, newDetail);

      emit(
        state.copyWith(
          status: MatchDetailStatus.loaded,
          matchDetail: mergedDetail,
        ),
      );
    } catch (e) {
      // print('❌ Silent refresh failed: $e');
    }
  }

  /// Merges [incoming] detail with [existing] to preserve data like flags
  /// that might be missing in the [incoming] (e.g. from a partial API response).
  MatchDetail _mergeWithPreview(MatchDetail? existing, MatchDetail incoming) {
    if (existing == null) return incoming;

    var t1 = incoming.match.team1;
    var t2 = incoming.match.team2;

    // Build a lookup of shortName → flagUrl from the existing (preview) teams.
    // This ensures we match by team identity, NOT by position, so flags are
    // never swapped when the API returns teams in a different order.
    final existingFlags = <String, String>{};
    final e1 = existing.match.team1;
    final e2 = existing.match.team2;
    if (e1.flagUrl.isNotEmpty) {
      existingFlags[e1.shortName.toUpperCase()] = e1.flagUrl;
      if (e1.id.isNotEmpty) existingFlags[e1.id] = e1.flagUrl;
    }
    if (e2.flagUrl.isNotEmpty) {
      existingFlags[e2.shortName.toUpperCase()] = e2.flagUrl;
      if (e2.id.isNotEmpty) existingFlags[e2.id] = e2.flagUrl;
    }

    // Apply the correct flag to each incoming team by matching short name or id
    String? resolveFlag(Team t) {
      return existingFlags[t.shortName.toUpperCase()] ??
          existingFlags[t.id] ??
          (t.flagUrl.isNotEmpty ? t.flagUrl : null);
    }

    final f1 = resolveFlag(t1);
    if (f1 != null) t1 = t1.copyWith(flagUrl: f1);

    final f2 = resolveFlag(t2);
    if (f2 != null) t2 = t2.copyWith(flagUrl: f2);

    // Return new detail with correctly-flagged teams
    return incoming.copyWith(
      match: incoming.match.copyWith(team1: t1, team2: t2),
    );
  }

  void _onSubscribeLive(
    SubscribeToLiveScore event,
    Emitter<MatchDetailState> emit,
  ) {
    _liveSubscription?.cancel();
    _liveSubscription = repository
        .getLiveScoreStream(event.matchId)
        .listen((match) => add(LiveScoreUpdated(match)));
  }

  void _onLiveUpdate(LiveScoreUpdated event, Emitter<MatchDetailState> emit) {
    if (state.matchDetail != null) {
      final currentDetail = state.matchDetail!;

      // Check if this live match update is a regression
      if (!_isMatchProgress(currentDetail.match, event.match)) {
        print('🛡️ Live score regression detected, skipping update');
        return;
      }

      emit(
        state.copyWith(
          matchDetail: MatchDetail(
            match: event.match,
            innings: currentDetail.innings,
            commentary: currentDetail.commentary,
            playingXI: currentDetail.playingXI,
            playingXI1: currentDetail.playingXI1,
            playingXI2: currentDetail.playingXI2,
            stats: currentDetail.stats,
          ),
        ),
      );
    }
  }

  bool _isDetailProgress(MatchDetail oldD, MatchDetail newD) {
    return _isMatchProgress(oldD.match, newD.match);
  }

  bool _isMatchProgress(CricketMatch oldM, CricketMatch newM) {
    final oldS1 = _parseRuns(oldM.team1.score);
    final newS1 = _parseRuns(newM.team1.score);
    final oldS2 = _parseRuns(oldM.team2.score);
    final newS2 = _parseRuns(newM.team2.score);

    // If either team has fewer runs than before, it's a regression
    if (newS1 < oldS1 || newS2 < oldS2) return false;

    // If runs are same, check overs if possible
    final oldO1 = double.tryParse(oldM.team1.overs ?? '0') ?? 0.0;
    final newO1 = double.tryParse(newM.team1.overs ?? '0') ?? 0.0;
    final oldO2 = double.tryParse(oldM.team2.overs ?? '0') ?? 0.0;
    final newO2 = double.tryParse(newM.team2.overs ?? '0') ?? 0.0;

    if (newS1 == oldS1 && newS2 == oldS2) {
      if (newO1 < oldO1 || newO2 < oldO2) return false;
    }

    return true;
  }

  int _parseRuns(String? score) {
    if (score == null || score.isEmpty) return 0;
    final match = RegExp(r'(\d+)').firstMatch(score);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  @override
  Future<void> close() {
    _liveSubscription?.cancel();
    return super.close();
  }
}
