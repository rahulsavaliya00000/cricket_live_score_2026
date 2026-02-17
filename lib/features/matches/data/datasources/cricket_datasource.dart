import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/team_entity.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

/// Abstract data source for cricket data.
/// Swap this implementation for real API or web scraping.
abstract class CricketDataSource {
  Future<List<CricketMatch>> getLiveMatches();
  Future<List<CricketMatch>> getUpcomingMatches();
  Future<List<CricketMatch>> getRecentMatches();
  Future<MatchDetail> getMatchDetail(String matchId);
  Future<List<BallCommentary>> getCommentary(String matchId);
  Future<List<CricketTeam>> getTeams();
  Future<List<Player>> getTeamPlayers(String teamSlug, String teamId);
  Future<Player> getPlayerDetail(String id, String slug);
  Future<List<Series>> getSeries();
  Future<Series> getSeriesDetail(String seriesId);
  Stream<CricketMatch> getLiveScoreStream(String matchId);
}
