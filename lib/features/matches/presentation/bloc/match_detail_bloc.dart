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
      emit(
        state.copyWith(
          matchDetail: MatchDetail(
            match: event.match,
            innings: state.matchDetail!.innings,
            commentary: state.matchDetail!.commentary,
            stats: state.matchDetail!.stats,
          ),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _liveSubscription?.cancel();
    return super.close();
  }
}
