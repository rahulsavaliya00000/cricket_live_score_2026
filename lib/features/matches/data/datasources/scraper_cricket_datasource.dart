import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:cricketbuzz/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

class ScraperCricketDataSource implements CricketDataSource {
  final http.Client client;
  final String _baseUrl = 'https://www.cricbuzz.com';
  final String _mBaseUrl = 'https://m.cricbuzz.com';
  final Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
  };

  ScraperCricketDataSource({required this.client});

  @override
  Future<List<CricketMatch>> getLiveMatches() async {
    return _scrapeMatches('/cricket-match/live-scores', MatchStatus.live);
  }

  @override
  Future<List<CricketMatch>> getUpcomingMatches() async {
    return _scrapeMatches(
      '/cricket-match/live-scores/upcoming-matches',
      MatchStatus.upcoming,
    );
  }

  @override
  Future<List<CricketMatch>> getRecentMatches() async {
    return _scrapeMatches(
      '/cricket-match/live-scores/recent-matches',
      MatchStatus.completed,
    );
  }

  @override
  Future<MatchDetail> getMatchDetail(String matchId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/live-cricket-scores/$matchId'),
        headers: _headers,
      );

      if (response.statusCode != 200) throw Exception();

      final document = parse(response.body);
      return MatchDetail(
        match: CricketMatch(
          id: matchId,
          title:
              document.querySelector('h1.cb-nav-hdr')?.text.trim() ?? 'Match',
          seriesName:
              document.querySelector('a.cb-nav-hdr')?.text.trim() ??
              'Unknown Series',
          venue: 'Unknown Venue',
          status: MatchStatus.live,
          format: MatchFormat.other,
          startTime: DateTime.now(),
          team1: Team(id: '1', name: 'Team 1', shortName: 'T1'),
          team2: Team(id: '2', name: 'Team 2', shortName: 'T2'),
        ),
        innings: [],
      );
    } catch (e) {
      return MatchDetail(
        match: CricketMatch(
          id: matchId,
          title: 'Match Details',
          seriesName: 'International Cricket',
          venue: 'TBD',
          status: MatchStatus.live,
          format: MatchFormat.other,
          startTime: DateTime.now(),
          team1: Team(id: '1', name: 'Team 1', shortName: 'T1'),
          team2: Team(id: '2', name: 'Team 2', shortName: 'T2'),
        ),
        innings: [],
      );
    }
  }

  @override
  Future<List<BallCommentary>> getCommentary(String matchId) async {
    return [];
  }

  @override
  Future<List<Player>> getPlayers() async {
    try {
      final response = await client.get(
        Uri.parse('$_mBaseUrl/cricket-stats/icc-rankings/men/batting'),
        headers: _headers,
      );
      if (response.statusCode != 200) return _getFallbackPlayers();

      final document = parse(response.body);
      final playerLinks = document.querySelectorAll('a[href^="/profiles/"]');

      final results = playerLinks
          .map((link) {
            final nameContainer = link.querySelector('div > div:first-child');
            final countryContainer = link.querySelector('div > div:last-child');
            final name = nameContainer?.text.trim() ?? '';
            final country = countryContainer?.text.trim() ?? '';
            final href = link.attributes['href'] ?? '';
            final id = href.split('/').last;

            if (name.isEmpty) return null;
            return Player(
              id: id,
              name: name,
              country: country,
              role: 'Batsman',
            );
          })
          .whereType<Player>()
          .toList();

      return results.isEmpty ? _getFallbackPlayers() : results;
    } catch (e) {
      return _getFallbackPlayers();
    }
  }

  @override
  Future<Player> getPlayerDetail(String playerId) async {
    return Player(
      id: playerId,
      name: 'Player $playerId',
      country: 'Unknown',
      role: 'Professional',
    );
  }

  @override
  Future<List<Series>> getSeries() async {
    try {
      final response = await client.get(
        Uri.parse('$_mBaseUrl/cricket-schedule/series/all'),
        headers: _headers,
      );
      if (response.statusCode != 200) return _getFallbackSeries();

      final document = parse(response.body);
      final seriesLinks = document.querySelectorAll(
        'a.flex.justify-between.items-center',
      );

      final results = seriesLinks
          .map((link) {
            final nameContainer = link.querySelector('div > div:first-child');
            final dateContainer = link.querySelector('div > div:last-child');
            final name = nameContainer?.text.trim() ?? '';
            final dates = dateContainer?.text.trim() ?? '';
            final href = link.attributes['href'] ?? '';
            final id = href.split('/').last;

            if (name.isEmpty) return null;
            return Series(
              id: id,
              name: name,
              startDate: dates.split('-').first.trim(),
              endDate: dates.contains('-') ? dates.split('-').last.trim() : '',
            );
          })
          .whereType<Series>()
          .toList();

      return results.isEmpty ? _getFallbackSeries() : results;
    } catch (e) {
      return _getFallbackSeries();
    }
  }

  @override
  Future<Series> getSeriesDetail(String seriesId) async {
    return Series(
      id: seriesId,
      name: 'Series $seriesId',
      startDate: '',
      endDate: '',
    );
  }

  @override
  Future<List<PointsTableEntry>> getSeriesStandings(String seriesId) async {
    try {
      final response = await client.get(
        Uri.parse('$_mBaseUrl/cricket-series/$seriesId/points-table'),
        headers: _headers,
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final rows = document.querySelectorAll('.grid.point-table-grid.p-2');

      return rows
          .map((row) {
            final cells = row.children;
            if (cells.length < 8) {
              return const PointsTableEntry(
                teamName: '',
                teamShortName: '',
                matches: 0,
                won: 0,
                lost: 0,
                points: 0,
                netRunRate: 0.0,
              );
            }

            final name = cells[1].text.trim();
            final p = int.tryParse(cells[2].text.trim()) ?? 0;
            final w = int.tryParse(cells[3].text.trim()) ?? 0;
            final l = int.tryParse(cells[4].text.trim()) ?? 0;
            final nr = int.tryParse(cells[5].text.trim()) ?? 0;
            final pts = int.tryParse(cells[6].text.trim()) ?? 0;
            final nrr = double.tryParse(cells[7].text.trim()) ?? 0.0;

            return PointsTableEntry(
              teamName: name,
              teamShortName: name
                  .substring(0, name.length >= 3 ? 3 : name.length)
                  .toUpperCase(),
              matches: p,
              won: w,
              lost: l,
              noResult: nr,
              points: pts,
              netRunRate: nrr,
            );
          })
          .where((e) => e.teamName.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<CricketMatch> getLiveScoreStream(String matchId) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 30));
      final detail = await getMatchDetail(matchId);
      yield detail.match;
    }
  }

  Future<List<CricketMatch>> _scrapeMatches(
    String path,
    MatchStatus status,
  ) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
      );
      if (response.statusCode != 200) return _getFallbackMatches(status);

      final document = parse(response.body);
      final matchCards = document.querySelectorAll('a.bg-cbWhite');

      final results = matchCards.map((card) {
        final spans = card.querySelectorAll('span');
        String title = 'Unknown Match',
            team1Name = 'Team 1',
            team2Name = 'Team 2';
        String? score1, score2, statusText;

        if (spans.isNotEmpty) {
          statusText = spans.last.text.trim();
          final teamCandidates = spans.where((s) {
            final t = s.text.trim().toLowerCase();
            if (t.contains('•') || t.contains('/') || t.length < 2)
              return false;
            if (RegExp(r'\d+[-–—]\d+|\d+/\d+').hasMatch(t)) return false;
            final statusKeywords = [
              'need',
              'runs',
              'won',
              'stumps',
              'tea',
              'lunch',
              'session',
              'day',
              'leads',
              'trail',
              'starts',
              'opted',
              'choose',
              'toss',
            ];
            if (statusKeywords.any((kw) => t.contains(kw))) return false;
            if (t == spans.last.text.trim().toLowerCase()) return false;
            return true;
          }).toList();

          if (teamCandidates.isNotEmpty) {
            team1Name = teamCandidates[0].text.trim();
            if (teamCandidates.length >= 2)
              team2Name = teamCandidates[1].text.trim();
          }

          final scoreCandidates = spans
              .where((s) => RegExp(r'\d+-\d+|\d+/\d+').hasMatch(s.text))
              .toList();
          if (scoreCandidates.isNotEmpty) {
            score1 = scoreCandidates[0].text.trim();
            if (scoreCandidates.length > 1)
              score2 = scoreCandidates[1].text.trim();
          }

          final header = spans.firstWhere(
            (s) => s.text.contains('•'),
            orElse: () => spans.first,
          );
          title = header.text.trim();
        }

        final link = card.attributes['href'] ?? '';
        final id = link.split('/').where((s) => s.isNotEmpty).last;

        return CricketMatch(
          id: id,
          title: title,
          seriesName: 'International',
          venue: 'TBD',
          status: status,
          format: _guessFormat(title),
          startTime: DateTime.now(),
          team1: Team(
            id: team1Name,
            name: team1Name,
            shortName: team1Name
                .substring(0, team1Name.length >= 3 ? 3 : team1Name.length)
                .toUpperCase(),
            score: score1,
          ),
          team2: Team(
            id: team2Name,
            name: team2Name,
            shortName: team2Name
                .substring(0, team2Name.length >= 3 ? 3 : team2Name.length)
                .toUpperCase(),
            score: score2,
          ),
          statusText: statusText,
        );
      }).toList();

      return results.isEmpty ? _getFallbackMatches(status) : results;
    } catch (e) {
      return _getFallbackMatches(status);
    }
  }

  List<CricketMatch> _getFallbackMatches(MatchStatus status) {
    if (status == MatchStatus.live) {
      return [
        CricketMatch(
          id: 'fb_1',
          title: 'IPL 2026 - Match 1',
          seriesName: 'Indian Premier League',
          venue: 'Wankhede Stadium',
          status: MatchStatus.live,
          format: MatchFormat.ipl,
          startTime: DateTime.now(),
          team1: const Team(
            id: 'MI',
            name: 'Mumbai Indians',
            shortName: 'MI',
            score: '178/4',
            overs: '18.2',
          ),
          team2: const Team(
            id: 'CSK',
            name: 'Chennai Super Kings',
            shortName: 'CSK',
            score: '175/8',
            overs: '20.0',
          ),
          statusText: 'MI need 10 runs in 10 balls',
        ),
      ];
    }
    return [];
  }

  List<Player> _getFallbackPlayers() {
    return [
      const Player(
        id: '141',
        name: 'Virat Kohli',
        country: 'India',
        role: 'Batsman',
      ),
      const Player(
        id: '576',
        name: 'Rohit Sharma',
        country: 'India',
        role: 'Batsman',
      ),
    ];
  }

  List<Series> _getFallbackSeries() {
    return [
      const Series(
        id: '7607',
        name: 'IPL 2024',
        startDate: 'Mar 22',
        endDate: 'May 26',
      ),
      const Series(
        id: '11253',
        name: 'T20 World Cup 2026',
        startDate: 'Jun 1',
        endDate: 'Jun 29',
      ),
    ];
  }

  MatchFormat _guessFormat(String title) {
    if (title.contains('T20')) return MatchFormat.t20;
    if (title.contains('ODI')) return MatchFormat.odi;
    if (title.contains('Test')) return MatchFormat.test;
    return MatchFormat.other;
  }
}
