import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricketbuzz/features/matches/data/repositories/cricket_repository.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';

// ─── Events ──────────────────────────────────────────────
abstract class PlayersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPlayers extends PlayersEvent {}

class LoadPlayerDetail extends PlayersEvent {
  final String playerId;
  LoadPlayerDetail(this.playerId);
  @override
  List<Object?> get props => [playerId];
}

class SearchPlayers extends PlayersEvent {
  final String query;
  SearchPlayers(this.query);
  @override
  List<Object?> get props => [query];
}

// ─── States ──────────────────────────────────────────────
class PlayersState extends Equatable {
  final PlayersStatus status;
  final List<Player> players;
  final List<Player> filteredPlayers;
  final Player? selectedPlayer;
  final String? error;

  const PlayersState({
    this.status = PlayersStatus.initial,
    this.players = const [],
    this.filteredPlayers = const [],
    this.selectedPlayer,
    this.error,
  });

  PlayersState copyWith({
    PlayersStatus? status,
    List<Player>? players,
    List<Player>? filteredPlayers,
    Player? selectedPlayer,
    String? error,
  }) {
    return PlayersState(
      status: status ?? this.status,
      players: players ?? this.players,
      filteredPlayers: filteredPlayers ?? this.filteredPlayers,
      selectedPlayer: selectedPlayer ?? this.selectedPlayer,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    players,
    filteredPlayers,
    selectedPlayer,
    error,
  ];
}

enum PlayersStatus { initial, loading, loaded, error }

// ─── BLoC ────────────────────────────────────────────────
class PlayersBloc extends Bloc<PlayersEvent, PlayersState> {
  final CricketRepository repository;

  PlayersBloc({required this.repository}) : super(const PlayersState()) {
    on<LoadPlayers>(_onLoadPlayers);
    on<LoadPlayerDetail>(_onLoadPlayerDetail);
    on<SearchPlayers>(_onSearchPlayers);
  }

  Future<void> _onLoadPlayers(
    LoadPlayers event,
    Emitter<PlayersState> emit,
  ) async {
    emit(state.copyWith(status: PlayersStatus.loading));
    try {
      final players = await repository.getPlayers();
      emit(
        state.copyWith(
          status: PlayersStatus.loaded,
          players: players,
          filteredPlayers: players,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PlayersStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadPlayerDetail(
    LoadPlayerDetail event,
    Emitter<PlayersState> emit,
  ) async {
    emit(state.copyWith(status: PlayersStatus.loading));
    try {
      final player = await repository.getPlayerDetail(event.playerId);
      emit(
        state.copyWith(status: PlayersStatus.loaded, selectedPlayer: player),
      );
    } catch (e) {
      emit(state.copyWith(status: PlayersStatus.error, error: e.toString()));
    }
  }

  void _onSearchPlayers(SearchPlayers event, Emitter<PlayersState> emit) {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredPlayers: state.players));
    } else {
      final filtered = state.players
          .where(
            (p) =>
                p.name.toLowerCase().contains(event.query.toLowerCase()) ||
                p.country.toLowerCase().contains(event.query.toLowerCase()),
          )
          .toList();
      emit(state.copyWith(filteredPlayers: filtered));
    }
  }
}
