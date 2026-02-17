import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricketbuzz/features/matches/data/repositories/cricket_repository.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';

// ─── Events ──────────────────────────────────────────────
abstract class MatchDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMatchDetail extends MatchDetailEvent {
  final String matchId;
  LoadMatchDetail(this.matchId);
  @override
  List<Object?> get props => [matchId];
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
    emit(state.copyWith(status: MatchDetailStatus.loading));
    try {
      final detail = await repository.getMatchDetail(event.matchId);
      emit(
        state.copyWith(status: MatchDetailStatus.loaded, matchDetail: detail),
      );
    } catch (e) {
      emit(
        state.copyWith(status: MatchDetailStatus.error, error: e.toString()),
      );
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
          print('🛡️ MatchDetail regression detected, skipping update');
          return;
        }
      }

      emit(
        state.copyWith(
          status: MatchDetailStatus.loaded,
          matchDetail: newDetail,
        ),
      );
    } catch (e) {
      print('❌ Silent refresh failed: $e');
    }
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
