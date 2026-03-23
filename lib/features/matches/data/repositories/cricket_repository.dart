import 'package:cricket_live_score/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricket_live_score/features/matches/domain/entities/match_entity.dart';
import 'package:cricket_live_score/features/players/domain/entities/player_entity.dart';
import 'package:cricket_live_score/features/players/domain/entities/team_entity.dart';
import 'package:cricket_live_score/features/series/domain/entities/series_entity.dart';

abstract class CricketRepository {
  Future<List<CricketMatch>> getLiveMatches();
  Future<List<CricketMatch>> getUpcomingMatches();
  Future<List<CricketMatch>> getRecentMatches();
  Future<MatchDetail> getMatchDetail(String matchId);
  Future<List<BallCommentary>> getCommentary(String matchId);
  Future<List<CricketTeam>> getTeams();
  Future<List<CricketTeam>> getSeriesSquads(String seriesId);
  Future<List<Player>> getTeamPlayers(String teamSlug, String teamId);
  Future<Player> getPlayerDetail(String id, String slug);
  Future<List<Series>> getSeries();
  Future<Series> getSeriesDetail(String seriesId);
  Stream<CricketMatch> getLiveScoreStream(String matchId);
}

class CricketRepositoryImpl implements CricketRepository {
  final CricketDataSource dataSource;

  CricketRepositoryImpl({required this.dataSource});

  @override
  Future<List<CricketMatch>> getLiveMatches() => dataSource.getLiveMatches();

  @override
  Future<List<CricketMatch>> getUpcomingMatches() =>
      dataSource.getUpcomingMatches();

  @override
  Future<List<CricketMatch>> getRecentMatches() =>
      dataSource.getRecentMatches();

  @override
  Future<MatchDetail> getMatchDetail(String matchId) =>
      dataSource.getMatchDetail(matchId);

  @override
  Future<List<BallCommentary>> getCommentary(String matchId) =>
      dataSource.getCommentary(matchId);

  @override
  Future<List<CricketTeam>> getTeams() => dataSource.getTeams();

  @override
  Future<List<CricketTeam>> getSeriesSquads(String seriesId) =>
      dataSource.getSeriesSquads(seriesId);

  @override
  Future<List<Player>> getTeamPlayers(String teamSlug, String teamId) =>
      dataSource.getTeamPlayers(teamSlug, teamId);

  @override
  Future<Player> getPlayerDetail(String id, String slug) =>
      dataSource.getPlayerDetail(id, slug);

  @override
  Future<List<Series>> getSeries() => dataSource.getSeries();

  @override
  Future<Series> getSeriesDetail(String seriesId) =>
      dataSource.getSeriesDetail(seriesId);

  @override
  Stream<CricketMatch> getLiveScoreStream(String matchId) =>
      dataSource.getLiveScoreStream(matchId);
}
