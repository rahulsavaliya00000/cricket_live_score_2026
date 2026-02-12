import 'package:cricketbuzz/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

abstract class CricketRepository {
  Future<List<CricketMatch>> getLiveMatches();
  Future<List<CricketMatch>> getUpcomingMatches();
  Future<List<CricketMatch>> getRecentMatches();
  Future<MatchDetail> getMatchDetail(String matchId);
  Future<List<BallCommentary>> getCommentary(String matchId);
  Future<List<Player>> getPlayers();
  Future<Player> getPlayerDetail(String playerId);
  Future<List<Series>> getSeries();
  Future<Series> getSeriesDetail(String seriesId);
  Future<List<PointsTableEntry>> getSeriesStandings(String seriesId);
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
  Future<List<Player>> getPlayers() => dataSource.getPlayers();

  @override
  Future<Player> getPlayerDetail(String playerId) =>
      dataSource.getPlayerDetail(playerId);

  @override
  Future<List<Series>> getSeries() => dataSource.getSeries();

  @override
  Future<Series> getSeriesDetail(String seriesId) =>
      dataSource.getSeriesDetail(seriesId);

  @override
  Future<List<PointsTableEntry>> getSeriesStandings(String seriesId) =>
      dataSource.getSeriesStandings(seriesId);

  @override
  Stream<CricketMatch> getLiveScoreStream(String matchId) =>
      dataSource.getLiveScoreStream(matchId);
}
