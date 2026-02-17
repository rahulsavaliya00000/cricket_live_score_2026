import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:cricketbuzz/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/team_entity.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

class CrexDataSource implements CricketDataSource {
  final http.Client client;
  final String _baseUrl = 'https://crex.com';

  Map<String, String> get _headers => {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  };

  CrexDataSource({required this.client});

  @override
  Future<List<CricketMatch>> getLiveMatches() async {
    return _scrapeMatches('/', MatchStatus.live);
  }

  @override
  Future<List<CricketMatch>> getUpcomingMatches() async {
    return _scrapeMatches('/schedule', MatchStatus.upcoming);
  }

  @override
  Future<List<CricketMatch>> getRecentMatches() async {
    return _scrapeMatches('/', MatchStatus.completed);
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

      // Crex shows matches in card format with team flags and scores
      final matchCards = document.querySelectorAll('a[href*="/scoreboard/"]');

      if (matchCards.isEmpty) return _getFallbackMatches(status);

      final results = matchCards
          .map((card) {
            try {
              // Extract match link and ID
              final link = card.attributes['href'] ?? '';
              final matchId = link.split(
                '/',
              )[2]; // Get ID from /scoreboard/ID/...

              // Extract series name
              final seriesLink = card.querySelector('a[href*="/series/"]');
              String seriesName = 'International';
              if (seriesLink != null) {
                seriesName = seriesLink.text.trim();
              }

              // Extract team names and flags
              final teamElements = card.querySelectorAll('img[alt]');
              String team1Name = 'Team 1';
              String team2Name = 'Team 2';
              String team1Flag = '';
              String team2Flag = '';

              if (teamElements.length >= 2) {
                team1Name =
                    teamElements[0].attributes['alt']?.trim() ?? 'Team 1';
                team2Name =
                    teamElements[1].attributes['alt']?.trim() ?? 'Team 2';
                team1Flag = teamElements[0].attributes['src'] ?? '';
                team2Flag = teamElements[1].attributes['src'] ?? '';

                // Make URLs absolute
                if (team1Flag.isNotEmpty && !team1Flag.startsWith('http')) {
                  team1Flag = _baseUrl + team1Flag;
                }
                if (team2Flag.isNotEmpty && !team2Flag.startsWith('http')) {
                  team2Flag = _baseUrl + team2Flag;
                }
              }

              // Extract scores and overs directly from span elements with specific classes
              // Look for score elements that typically have the pattern
              final allText = card.text;
              print('📋 Raw card text: $allText');

              String? score1, score2;
              String? overs1, overs2;

              // Look for individual score elements within the card
              final scoreSpans = card.querySelectorAll('span, div');
              final scoreTexts = <String>[];

              for (final span in scoreSpans) {
                final text = span.text.trim();
                // Look for score patterns like "160-9" or "162-5"
                if (RegExp(r'^\d+-\d+$').hasMatch(text)) {
                  scoreTexts.add(text);
                  print('✅ Found score: $text');
                }
              }

              // Also look for over numbers
              final oversTexts = <String>[];
              for (final span in scoreSpans) {
                final text = span.text.trim();
                // Look for over patterns like "20.0" or "19.2" but not dates
                if (RegExp(r'^\d+\.\d+$').hasMatch(text)) {
                  final num = double.tryParse(text);
                  if (num != null && num <= 50) {
                    // Cricket overs are max 50
                    oversTexts.add(text);
                    print('✅ Found overs: $text');
                  }
                }
              }

              // Assign scores and overs
              if (scoreTexts.isNotEmpty) {
                score1 = scoreTexts[0];
                overs1 = oversTexts.isNotEmpty ? oversTexts[0] : null;
              }
              if (scoreTexts.length >= 2) {
                score2 = scoreTexts[1];
                overs2 = oversTexts.length >= 2 ? oversTexts[1] : null;
              }

              print(
                '🏏 Team1: $score1 ${overs1 != null ? "($overs1 ov)" : ""}',
              );
              print(
                '🏏 Team2: $score2 ${overs2 != null ? "($overs2 ov)" : ""}',
              );

              // Extract status text - look for result/status in specific patterns
              String? statusText;

              // Pattern 1: "Team won by X wickets/runs"
              final wonByPattern = RegExp(
                r'([A-Z]{2,4})\s+won\s+by\s+\d+\s+(wickets?|runs?)',
              );
              final wonByMatch = wonByPattern.firstMatch(allText);
              if (wonByMatch != null) {
                statusText = wonByMatch.group(0);
                print('✅ Found result: $statusText');
              }

              // Pattern 2: "X runs needed from Y balls" (live matches)
              if (statusText == null) {
                final needsPattern = RegExp(
                  r'\d+\s+runs?\s+needed\s+from\s+\d+\s+balls?',
                );
                final needsMatch = needsPattern.firstMatch(allText);
                if (needsMatch != null) {
                  statusText = needsMatch.group(0);
                  print('✅ Found status: $statusText');
                }
              }

              // Pattern 3: Look in text nodes for any "won by" text
              if (statusText == null && allText.contains('won by')) {
                final lines = allText.split('\n');
                for (final line in lines) {
                  final trimmed = line.trim();
                  if (trimmed.contains('won by') && trimmed.length < 100) {
                    statusText = trimmed;
                    print('✅ Found result (fallback): $statusText');
                    break;
                  }
                }
              }

              // Determine match status from text more robustly
              MatchStatus matchStatus = status;
              final lowerText = allText.toLowerCase();

              bool hasMatch(String pattern) =>
                  RegExp('\\b$pattern\\b').hasMatch(lowerText);

              if (lowerText.contains('won by') ||
                  hasMatch('won') ||
                  hasMatch('result') ||
                  hasMatch('drawn') ||
                  hasMatch('abandoned') ||
                  lowerText.contains('no result')) {
                matchStatus = MatchStatus.completed;
              } else if (hasMatch('live') ||
                  lowerText.contains('runs needed') ||
                  hasMatch('need') ||
                  hasMatch('trail') ||
                  hasMatch('lead') ||
                  hasMatch('opted') ||
                  hasMatch('choose') ||
                  hasMatch('toss') ||
                  hasMatch('stumps') ||
                  (hasMatch('day') && !hasMatch('won'))) {
                matchStatus = MatchStatus.live;
              } else if (hasMatch('starts') ||
                  hasMatch('am') ||
                  hasMatch('pm') ||
                  hasMatch('today') ||
                  hasMatch('tomorrow') ||
                  RegExp(r'\d{1,2}:\d{2}').hasMatch(lowerText)) {
                matchStatus = MatchStatus.upcoming;
              }

              // Extract venue and match format from text
              final venue = _extractVenue(allText);
              final format = _guessFormat(allText);

              // Extract match title
              String title = seriesName;
              if (allText.contains('T20')) {
                title = 'T20 Match';
              } else if (allText.contains('ODI')) {
                title = 'ODI Match';
              } else if (allText.contains('TEST')) {
                title = 'Test Match';
              }

              return CricketMatch(
                id: matchId,
                title: title,
                seriesName: seriesName,
                venue: venue,
                status: matchStatus,
                format: format,
                startTime: DateTime.now(),
                team1: Team(
                  id: team1Name,
                  name: team1Name,
                  shortName: _getTeamShortName(team1Name),
                  flagUrl: team1Flag,
                  score: score1,
                  overs: overs1,
                ),
                team2: Team(
                  id: team2Name,
                  name: team2Name,
                  shortName: _getTeamShortName(team2Name),
                  flagUrl: team2Flag,
                  score: score2,
                  overs: overs2,
                ),
                statusText: statusText,
                result: matchStatus == MatchStatus.completed
                    ? statusText
                    : null,
              );
            } catch (e) {
              print('Error parsing match card: $e');
              return null;
            }
          })
          .whereType<CricketMatch>()
          .toList();

      // Filter by requested status
      final filtered = results.where((m) => m.status == status).toList();

      return filtered.isEmpty ? _getFallbackMatches(status) : filtered;
    } catch (e) {
      print('Error scraping Crex: $e');
      return _getFallbackMatches(status);
    }
  }

  String _extractVenue(String text) {
    // Common stadium names
    final venueKeywords = [
      'Stadium',
      'Ground',
      'Oval',
      'Park',
      'Gardens',
      'Cricket',
    ];

    final lines = text.split('\n');
    for (final line in lines) {
      for (final keyword in venueKeywords) {
        if (line.contains(keyword)) {
          return line.trim();
        }
      }
    }

    return 'TBD';
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
            flagUrl:
                'https://www.cricbuzz.com/a/img/v1/75x75/i1/c170661/mumbai-indians.jpg',
            score: '178/4',
            overs: '18.2',
          ),
          team2: const Team(
            id: 'CSK',
            name: 'Chennai Super Kings',
            shortName: 'CSK',
            flagUrl:
                'https://www.cricbuzz.com/a/img/v1/75x75/i1/c170623/chennai-super-kings.jpg',
            score: '175/8',
            overs: '20.0',
          ),
          statusText: 'MI need 10 runs in 10 balls',
        ),
      ];
    }
    return [];
  }

  @override
  Future<MatchDetail> getMatchDetail(String matchId) async {
    // Return basic match detail - would need to implement full detail scraping
    return MatchDetail(
      match: CricketMatch(
        id: matchId,
        title: 'Match Detail',
        seriesName: 'Series',
        venue: 'TBD',
        status: MatchStatus.live,
        format: MatchFormat.other,
        startTime: DateTime.now(),
        team1: const Team(id: '1', name: 'Team 1', shortName: 'T1'),
        team2: const Team(id: '2', name: 'Team 2', shortName: 'T2'),
      ),
      innings: const [],
      commentary: const [],
    );
  }

  @override
  Stream<CricketMatch> getLiveScoreStream(String matchId) {
    // Would implement WebSocket or polling here
    return Stream.periodic(const Duration(seconds: 5), (_) async {
      final detail = await getMatchDetail(matchId);
      return detail.match;
    }).asyncMap((future) => future);
  }

  @override
  Future<List<BallCommentary>> getCommentary(String matchId) async {
    return [];
  }

  @override
  Future<List<CricketTeam>> getTeams() async {
    return CricketTeam.internationalTeams;
  }

  @override
  Future<List<Player>> getTeamPlayers(String teamSlug, String teamId) async {
    return [];
  }

  @override
  Future<Player> getPlayerDetail(String id, String slug) async {
    throw UnimplementedError();
  }

  @override
  Future<Series> getSeriesDetail(String seriesId) async {
    return const Series(
      id: '',
      name: 'Unknown Series',
      startDate: '',
      endDate: '',
    );
  }

  @override
  Future<List<Series>> getSeries() async {
    return _getFallbackSeries();
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

  /// Get proper short name for a team
  String _getTeamShortName(String fullName) {
    if (fullName.isEmpty) return 'TBD';

    // Known team mappings
    final knownTeams = {
      'india': 'IND',
      'australia': 'AUS',
      'england': 'ENG',
      'pakistan': 'PAK',
      'south africa': 'SA',
      'new zealand': 'NZ',
      'sri lanka': 'SL',
      'west indies': 'WI',
      'bangladesh': 'BAN',
      'afghanistan': 'AFG',
      'zimbabwe': 'ZIM',
      'ireland': 'IRE',
      'netherlands': 'NED',
      'scotland': 'SCO',
      'united arab emirates': 'UAE',
      'uae': 'UAE',
      'mumbai indians': 'MI',
      'chennai super kings': 'CSK',
      'royal challengers bangalore': 'RCB',
      'royal challengers bengaluru': 'RCB',
      'kolkata knight riders': 'KKR',
      'delhi capitals': 'DC',
      'punjab kings': 'PBKS',
      'rajasthan royals': 'RR',
      'sunrisers hyderabad': 'SRH',
      'lucknow super giants': 'LSG',
      'gujarat titans': 'GT',
      'namibia': 'NAM',
      'oman': 'OMA',
      'qatar': 'QAT',
      'kenya': 'KEN',
      'hong kong': 'HKG',
      'nepal': 'NEP',
      'canada': 'CAN',
      'usa': 'USA',
      'united states': 'USA',
      'italy': 'ITA',
    };

    final lowerName = fullName.toLowerCase().trim();

    // Check if it's a known team
    if (knownTeams.containsKey(lowerName)) {
      return knownTeams[lowerName]!;
    }

    // Remove common suffixes
    String cleanName = fullName
        .replaceAll(
          RegExp(r'\s+(women|men|u19|u-19)$', caseSensitive: false),
          '',
        )
        .trim();

    // If it contains multiple words, create abbreviation from first letters
    final words = cleanName.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final skipWords = {'the', 'of', 'and', '&'};
      final abbreviation = words
          .where((word) => !skipWords.contains(word.toLowerCase()))
          .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
          .join();
      if (abbreviation.length >= 2) {
        return abbreviation.substring(
          0,
          abbreviation.length > 4 ? 4 : abbreviation.length,
        );
      }
    }

    // Fallback: take first 3-4 characters
    final maxLen = fullName.length >= 4 ? 4 : fullName.length;
    return fullName.substring(0, maxLen >= 3 ? 3 : maxLen).toUpperCase();
  }

  MatchFormat _guessFormat(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('t20')) return MatchFormat.t20;
    if (lower.contains('odi')) return MatchFormat.odi;
    if (lower.contains('test')) return MatchFormat.test;
    if (lower.contains('ipl')) return MatchFormat.ipl;
    return MatchFormat.other;
  }
}
