import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_live_score/features/matches/data/repositories/cricket_repository.dart';
import 'package:cricket_live_score/features/players/domain/entities/player_entity.dart';
import 'package:cricket_live_score/features/players/domain/entities/team_entity.dart';

// ─── Events ──────────────────────────────────────────────
abstract class PlayersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTeams extends PlayersEvent {}

class LoadTeamPlayers extends PlayersEvent {
  final String teamSlug;
  final String teamId;
  final String teamName;
  LoadTeamPlayers({
    required this.teamSlug,
    required this.teamId,
    required this.teamName,
  });
  @override
  List<Object?> get props => [teamSlug, teamId];
}

class SearchTeams extends PlayersEvent {
  final String query;
  SearchTeams(this.query);
  @override
  List<Object?> get props => [query];
}

class LoadPlayerDetail extends PlayersEvent {
  final String playerId;
  final String playerSlug;
  final String playerName;

  LoadPlayerDetail({
    required this.playerId,
    required this.playerSlug,
    required this.playerName,
  });

  @override
  List<Object?> get props => [playerId, playerSlug];
}

class LoadIplSquads extends PlayersEvent {
  final String seriesId;
  LoadIplSquads(this.seriesId);
  @override
  List<Object?> get props => [seriesId];
}

// ─── States ──────────────────────────────────────────────
class PlayersState extends Equatable {
  final PlayersStatus status;
  final List<CricketTeam> teams;
  final List<CricketTeam> filteredTeams;
  final List<Player> teamPlayers;
  final List<CricketTeam> iplTeams;
  final String? currentTeamName;
  final String? error;

  const PlayersState({
    this.status = PlayersStatus.initial,
    this.teams = const [],
    this.filteredTeams = const [],
    this.teamPlayers = const [],
    this.iplTeams = const [],
    this.currentTeamName,
    this.selectedPlayer,
    this.error,
  });

  final Player? selectedPlayer;

  PlayersState copyWith({
    PlayersStatus? status,
    List<CricketTeam>? teams,
    List<CricketTeam>? filteredTeams,
    List<Player>? teamPlayers,
    List<CricketTeam>? iplTeams,
    String? currentTeamName,
    Player? selectedPlayer,
    String? error,
  }) {
    return PlayersState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      filteredTeams: filteredTeams ?? this.filteredTeams,
      teamPlayers: teamPlayers ?? this.teamPlayers,
      iplTeams: iplTeams ?? this.iplTeams,
      currentTeamName: currentTeamName ?? this.currentTeamName,
      selectedPlayer: selectedPlayer ?? this.selectedPlayer,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    teams,
    filteredTeams,
    teamPlayers,
    iplTeams,
    currentTeamName,
    selectedPlayer,
    error,
  ];
}

enum PlayersStatus {
  initial,
  loading,
  loaded,
  loadingPlayers,
  playersLoaded,
  loadingPlayer,
  playerLoaded,
  loadingIplSquads,
  iplSquadsLoaded,
  error,
}

// ─── BLoC ────────────────────────────────────────────────
class PlayersBloc extends Bloc<PlayersEvent, PlayersState> {
  final CricketRepository repository;

  PlayersBloc({required this.repository}) : super(const PlayersState()) {
    on<LoadTeams>(_onLoadTeams);
    on<LoadTeamPlayers>(_onLoadTeamPlayers);
    on<SearchTeams>(_onSearchTeams);
    on<LoadPlayerDetail>(_onLoadPlayerDetail);
    on<LoadIplSquads>(_onLoadIplSquads);
  }

  Future<void> _onLoadTeams(LoadTeams event, Emitter<PlayersState> emit) async {
    emit(state.copyWith(status: PlayersStatus.loading));
    try {
      final teams = await repository.getTeams();
      emit(
        state.copyWith(
          status: PlayersStatus.loaded,
          teams: teams,
          filteredTeams: teams,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PlayersStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadTeamPlayers(
    LoadTeamPlayers event,
    Emitter<PlayersState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PlayersStatus.loadingPlayers,
        currentTeamName: event.teamName,
      ),
    );
    try {
      final players = await repository.getTeamPlayers(
        event.teamSlug,
        event.teamId,
      );
      emit(
        state.copyWith(
          status: PlayersStatus.playersLoaded,
          teamPlayers: players,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PlayersStatus.error, error: e.toString()));
    }
  }

  void _onSearchTeams(SearchTeams event, Emitter<PlayersState> emit) {
    if (event.query.isEmpty) {
      emit(state.copyWith(filteredTeams: state.teams));
    } else {
      final filtered = state.teams
          .where(
            (t) => t.name.toLowerCase().contains(event.query.toLowerCase()),
          )
          .toList();
      emit(state.copyWith(filteredTeams: filtered));
    }
  }

  Future<void> _onLoadPlayerDetail(
    LoadPlayerDetail event,
    Emitter<PlayersState> emit,
  ) async {
    emit(state.copyWith(status: PlayersStatus.loadingPlayer));
    try {
      final player = await repository.getPlayerDetail(
        event.playerId,
        event.playerSlug,
      );
      emit(
        state.copyWith(
          status: PlayersStatus.playerLoaded,
          selectedPlayer: player,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PlayersStatus.error, error: e.toString()));
    }
  }

  Future<void> _onLoadIplSquads(
    LoadIplSquads event,
    Emitter<PlayersState> emit,
  ) async {
    emit(state.copyWith(status: PlayersStatus.loadingIplSquads));
    try {
      final teams = await repository.getSeriesSquads(event.seriesId);
      emit(
        state.copyWith(
          status: PlayersStatus.iplSquadsLoaded,
          iplTeams: teams,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PlayersStatus.error, error: e.toString()));
    }
  }
}
