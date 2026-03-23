import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:cricket_live_score/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricket_live_score/features/matches/domain/entities/match_entity.dart';
import 'package:cricket_live_score/features/players/domain/entities/player_entity.dart';
import 'package:cricket_live_score/features/players/domain/entities/team_entity.dart';
import 'package:cricket_live_score/features/series/domain/entities/series_entity.dart';
import 'package:cricket_live_score/core/services/remote_config_service.dart';

class ApiCricketDataSource implements CricketDataSource {
  final http.Client client;

  /// URLs come from Firebase Remote Config — never hardcoded in the binary.
  String get _baseUrl => RemoteConfigService.instance.apiBaseUrl;
  String get _mBaseUrl => RemoteConfigService.instance.apiMBaseUrl;

  Map<String, String> get _headers => {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  };

  ApiCricketDataSource({required this.client});

  @override
  Future<List<CricketMatch>> getLiveMatches() async {
    return _fetchMatches('/cricket-match/live-scores', MatchStatus.live);
  }

  @override
  Future<List<CricketMatch>> getUpcomingMatches() async {
    return _fetchMatches(
      '/cricket-match/live-scores/upcoming-matches',
      MatchStatus.upcoming,
    );
  }

  @override
  Future<List<CricketMatch>> getRecentMatches() async {
    return _fetchMatches(
      '/cricket-match/live-scores/recent-matches',
      MatchStatus.completed,
    );
  }

  @override
  Future<MatchDetail> getMatchDetail(String matchId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Fetch Scorecard API
      final scorecardResponse = await client.get(
        Uri.parse('$_mBaseUrl/api/mcenter/scorecard/$matchId?_ts=$timestamp'),
        headers: _headers,
      );

      // Fetch Commentary API
      final commResponse = await client.get(
        Uri.parse('$_mBaseUrl/api/mcenter/comm/$matchId?_ts=$timestamp'),
        headers: _headers,
      );

      if (scorecardResponse.statusCode != 200) {
        throw Exception('Failed to fetch match details from API');
      }

      final scorecardJson = json.decode(scorecardResponse.body);

      // Commentary might be 204 (No Content) for upcoming matches
      final commJson =
          (commResponse.statusCode == 200 && commResponse.body.isNotEmpty)
          ? json.decode(commResponse.body)
          : {};

      final matchHeader = scorecardJson['matchHeader'] ?? {};
      final team1 = matchHeader['team1'] ?? {};
      final team2 = matchHeader['team2'] ?? {};
      final venueData = matchHeader['venue'] ?? {};

      final List<Innings> inningsList = [];
      final scoreCardArr = scorecardJson['scoreCard'] as List? ?? [];

      for (final inningsJson in scoreCardArr) {
        final batTeamDetails = inningsJson['batTeamDetails'] ?? {};
        final bowlTeamDetails = inningsJson['bowlTeamDetails'] ?? {};
        final scoreDetails = inningsJson['scoreDetails'] ?? {};

        final List<BatsmanScore> batsmen = [];
        final batsmenData = batTeamDetails['batsmenData'] as Map? ?? {};
        batsmenData.forEach((key, value) {
          batsmen.add(
            BatsmanScore(
              name: value['batName'] ?? 'Unknown',
              dismissal:
                  value['outDesc'] ?? (value['runs'] != null ? 'Not Out' : ''),
              runs: value['runs'] ?? 0,
              balls: value['balls'] ?? 0,
              fours: value['fours'] ?? 0,
              sixes: value['sixes'] ?? 0,
              strikeRate: (value['strikeRate'] is num)
                  ? (value['strikeRate'] as num).toDouble()
                  : 0.0,
              isBatting:
                  (value['outDesc'] ?? '').isEmpty && value['runs'] != null,
            ),
          );
        });

        final List<BowlerFigure> bowlers = [];
        final bowlersData = bowlTeamDetails['bowlersData'] as Map? ?? {};
        bowlersData.forEach((key, value) {
          bowlers.add(
            BowlerFigure(
              name: value['bowlName'] ?? 'Unknown',
              overs: (value['overs'] is num)
                  ? (value['overs'] as num).toDouble()
                  : 0.0,
              maidens: value['maidens'] ?? 0,
              runs: value['runs'] ?? 0,
              wickets: value['wickets'] ?? 0,
              economy: (value['economy'] is num)
                  ? (value['economy'] as num).toDouble()
                  : 0.0,
            ),
          );
        });

        inningsList.add(
          Innings(
            teamName: batTeamDetails['batTeamName'] ?? 'Team',
            teamShortName: batTeamDetails['batTeamShortName'] ?? 'T',
            runs: scoreDetails['runs'] ?? 0,
            wickets: scoreDetails['wickets'] ?? 0,
            overs: (scoreDetails['overs'] is num)
                ? (scoreDetails['overs'] as num).toDouble()
                : 0.0,
            runRate: (scoreDetails['runRate'] is num)
                ? (scoreDetails['runRate'] as num).toDouble()
                : 0.0,
            batsmen: batsmen,
            bowlers: bowlers,
          ),
        );
      }

      // Parse Commentary
      final List<BallCommentary> commentary = [];
      final commMap = commJson['matchCommentary'] as Map? ?? {};
      final sortedKeys = commMap.keys.toList()..sort((a, b) => b.compareTo(a));

      for (final key in sortedKeys) {
        final item = commMap[key];
        if (item['commType'] != 'commentary') continue;

        final overMetric = (item['ballMetric'] is num)
            ? (item['ballMetric'] as num).toDouble()
            : 0.0;
        final over = overMetric.floor().toDouble();
        final ball = ((overMetric - over) * 10).round();

        final descText = item['commText'] ?? '';
        final isWicket = (item['event'] as List?)?.contains('wicket') ?? false;
        final isFour = (item['event'] as List?)?.contains('four') ?? false;
        final isSix = (item['event'] as List?)?.contains('six') ?? false;

        commentary.add(
          BallCommentary(
            overNumber: over,
            ballNumber: ball,
            runs: isSix ? 6 : (isFour ? 4 : 0),
            commentary: descText.replaceAll(RegExp(r'<[^>]*>'), ''),
            isWicket: isWicket,
            isFour: isFour,
            isSix: isSix,
            batsman: item['batsmanDetails']?['playerName'] ?? 'Unknown',
            bowler: item['bowlerDetails']?['playerName'] ?? 'Unknown',
          ),
        );
      }

      // Playing XI extraction
      final List<String> pXI1 = [];
      final List<String> pXI2 = [];
      final team1Id = team1['id'];
      final team2Id = team2['id'];

      for (final inningsJson in scoreCardArr) {
        final batTeamDetails = inningsJson['batTeamDetails'] ?? {};
        final currentTeamId = batTeamDetails['batTeamId'];
        final batsmenData = batTeamDetails['batsmenData'] as Map? ?? {};

        final players = batsmenData.values
            .map((v) => v['batName']?.toString() ?? 'Unknown')
            .toList();

        if (currentTeamId == team1Id) {
          if (pXI1.isEmpty) pXI1.addAll(players);
        } else if (currentTeamId == team2Id) {
          if (pXI2.isEmpty) pXI2.addAll(players);
        }
      }

      // If we only have one team's squad because only one innings happened,
      // we might need to check bowlTeamDetails for the other squad
      if (pXI1.isEmpty || pXI2.isEmpty) {
        for (final inningsJson in scoreCardArr) {
          final bowlTeamDetails = inningsJson['bowlTeamDetails'] ?? {};
          final currentTeamId = bowlTeamDetails['bowlTeamId'];
          final bowlersData = bowlTeamDetails['bowlersData'] as Map? ?? {};
          final players = bowlersData.values
              .map((v) => v['bowlName']?.toString() ?? 'Unknown')
              .toList();

          if (currentTeamId == team1Id && pXI1.isEmpty) {
            pXI1.addAll(players);
          } else if (currentTeamId == team2Id && pXI2.isEmpty) {
            pXI2.addAll(players);
          }
        }
      }

      final statusText =
          scorecardJson['status'] ??
          matchHeader['status'] ??
          'Match in progress';
      final result = matchHeader['result']?['resultType'] != null
          ? matchHeader['status']
          : null;

      // Fetch team flag URLs from the squads page (JSON API doesn't include them)
      String t1FlagUrl = '';
      String t2FlagUrl = '';
      final t1ShortRaw = (team1['shortName'] ?? '').toString().toUpperCase();
      final t2ShortRaw = (team2['shortName'] ?? '').toString().toUpperCase();
      try {
        final squadsResponse = await client.get(
          Uri.parse('$_mBaseUrl/cricket-match-squads/$matchId'),
          headers: _headers,
        );
        if (squadsResponse.statusCode == 200) {
          final squadsDoc = parse(squadsResponse.body);
          final flagImgs = squadsDoc.querySelectorAll('img').where((img) {
            final src = img.attributes['src'] ?? '';
            return src.contains('static.cricbuzz.com') &&
                !src.contains('gthumb') &&
                src.contains('/i1/c');
          }).toList();

          // Collect unique flag URLs in DOM order
          final uniqueFlags = <String>[];
          for (final img in flagImgs) {
            final src = img.attributes['src'] ?? '';
            if (src.isNotEmpty && !uniqueFlags.contains(src)) {
              uniqueFlags.add(src);
            }
          }

          // Try to match flags to teams by alt/title text first (most reliable)
          for (final img in flagImgs) {
            final src = img.attributes['src'] ?? '';
            if (src.isEmpty) continue;
            final alt = (img.attributes['alt'] ?? img.attributes['title'] ?? '')
                .toUpperCase();
            if (t1FlagUrl.isEmpty &&
                alt.isNotEmpty &&
                t1ShortRaw.isNotEmpty &&
                alt.contains(t1ShortRaw)) {
              t1FlagUrl = src;
            } else if (t2FlagUrl.isEmpty &&
                alt.isNotEmpty &&
                t2ShortRaw.isNotEmpty &&
                alt.contains(t2ShortRaw)) {
              t2FlagUrl = src;
            }
          }

          // Fallback: assign by position (first unique = team1, second = team2)
          if (t1FlagUrl.isEmpty && uniqueFlags.isNotEmpty) {
            t1FlagUrl = uniqueFlags[0];
          }
          if (t2FlagUrl.isEmpty && uniqueFlags.length >= 2) {
            t2FlagUrl = uniqueFlags[1];
          }
        }
      } catch (_) {
        // Non-critical: flags will just show fallback icon
      }

      Team t1 = Team(
        id: team1['id']?.toString() ?? '1',
        name: team1['name'] ?? 'Team 1',
        shortName: team1['shortName'] ?? 'T1',
        flagUrl: t1FlagUrl,
      );
      Team t2 = Team(
        id: team2['id']?.toString() ?? '2',
        name: team2['name'] ?? 'Team 2',
        shortName: team2['shortName'] ?? 'T2',
        flagUrl: t2FlagUrl,
      );

      // Check if we need to fetch better names/flags (if defaults returned)
      if (t1.name == 'Team 1' ||
          t2.name == 'Team 2' ||
          t1.shortName == 'T1' ||
          t2.shortName == 'T2') {
        try {
          final matchPageResponse = await client.get(
            Uri.parse('$_mBaseUrl/cricket-scores/$matchId'),
            headers: _headers,
          );
          if (matchPageResponse.statusCode == 200) {
            final doc = parse(matchPageResponse.body);

            // Try to find team names in likely places
            // Usually in a header or score block
            // Generic fallback: check match description or title
            final title = doc.querySelector('title')?.text ?? '';
            // Title format: "IND vs PAK Live Score..."
            if (title.contains(' vs ')) {
              final parts = title.split(' vs ');
              if (parts.length >= 2) {
                final t1Raw = parts[0].trim();
                final t2Raw = parts[1]
                    .split(' Live')
                    .first
                    .split(' Score')
                    .first
                    .trim();

                if (t1.name == 'Team 1') {
                  t1 = t1.copyWith(
                    name: t1Raw,
                    shortName: t1Raw.replaceAll(RegExp(r'[^A-Z]'), ''),
                  );
                }
                if (t2.name == 'Team 2') {
                  t2 = t2.copyWith(
                    name: t2Raw,
                    shortName: t2Raw.replaceAll(RegExp(r'[^A-Z]'), ''),
                  );
                }
              }
            }
          }
        } catch (e) {
          print('Error fetching fallback teams: $e');
        }
      }

      // Use miniscore from commentary JSON for the most live score synchronized with ball-by-ball
      final miniScore = commJson['miniscore'] as Map? ?? {};
      final miniBatTeam = miniScore['batTeam'] as Map? ?? {};
      final miniBowlTeam = miniScore['bowlTeam'] as Map? ?? {};

      // Match IDs might be strings or ints, handle consistently
      final miniBatId = miniBatTeam['teamId']?.toString();
      final miniBowlId = miniBowlTeam['teamId']?.toString();
      final t1Id = t1.id;
      final t2Id = t2.id;

      if (t1Id == miniBatId) {
        t1 = t1.copyWith(
          score: miniBatTeam['score']?.toString(),
          overs: miniBatTeam['overs']?.toString(),
        );
      } else if (t1Id == miniBowlId) {
        t1 = t1.copyWith(
          score: miniBowlTeam['score']?.toString(),
          overs: miniBowlTeam['overs']?.toString(),
        );
      }

      if (t2Id == miniBatId) {
        t2 = t2.copyWith(
          score: miniBatTeam['score']?.toString(),
          overs: miniBatTeam['overs']?.toString(),
        );
      } else if (t2Id == miniBowlId) {
        t2 = t2.copyWith(
          score: miniBowlTeam['score']?.toString(),
          overs: miniBowlTeam['overs']?.toString(),
        );
      }

      // Fallback: If miniscore is missing, find latest scores from inningsList
      if (t1.score == null || t2.score == null) {
        for (final inn in inningsList) {
          // Fuzzy match names/IDs
          if (inn.teamName == t1.name || inn.teamShortName == t1.shortName) {
            t1 = t1.copyWith(score: inn.scoreText, overs: inn.overs.toString());
          } else if (inn.teamName == t2.name ||
              inn.teamShortName == t2.shortName) {
            t2 = t2.copyWith(score: inn.scoreText, overs: inn.overs.toString());
          }
        }
      }

      return MatchDetail(
        match: CricketMatch(
          id: matchId,
          title: matchHeader['matchDescription'] ?? 'Match',
          seriesName: matchHeader['seriesName'] ?? 'International Cricket',
          venue: '${venueData['name'] ?? 'TBD'}, ${venueData['city'] ?? ''}',
          status: result != null ? MatchStatus.completed : MatchStatus.live,
          format: _guessFormat(matchHeader['matchFormat'] ?? ''),
          startTime: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(
                  matchHeader['matchStartTimestamp']?.toString() ??
                      '$timestamp',
                ) ??
                timestamp,
          ),
          team1: t1,
          team2: t2,
          statusText: statusText,
          result: result,
        ),
        innings: inningsList,
        commentary: commentary,
        playingXI1: pXI1,
        playingXI2: pXI2,
      );
    } catch (e) {
      print('❌ Error in getMatchDetail (JSON API): $e');
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
    final detail = await getMatchDetail(matchId);
    return detail.commentary;
  }

  @override
  Future<List<CricketTeam>> getTeams() async {
    return CricketTeam.internationalTeams;
  }

  @override
  Future<Player> getPlayerDetail(String id, String slug) async {
    try {
      final response = await client.get(
        Uri.parse('$_mBaseUrl/profiles/$id/$slug'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load player profile');
      }

      final document = parse(response.body);

      // 1. Basic Info (Name, Image, Country)
      String name = slug
          .split('-')
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
      String country = '';
      String role = '';
      String imageUrl = '';
      String bio = '';
      String born = '';
      String height = '';
      String battingStyle = '';
      String bowlingStyle = '';

      // Try basic extraction from Title
      final pageTitle = document.querySelector('title')?.text ?? '';
      if (pageTitle.contains(' Profile')) {
        name = pageTitle.split(' Profile')[0].trim();
      }

      // Image
      final img = document.querySelector('img[src*="/a/img/v1/i1/c"]');
      if (img != null) {
        imageUrl = img.attributes['src'] ?? '';
      }

      // Personal Info Section
      // Look for divs containing keys
      final allDivs = document.querySelectorAll('div');
      for (final div in allDivs) {
        final text = div.text.trim();
        // Check for specific labels
        // Format often: "Label Value" concatenated
        if (text.startsWith('Born')) {
          born = text.replaceFirst('Born', '').trim();
        } else if (text.startsWith('Height')) {
          height = text.replaceFirst('Height', '').trim();
        } else if (text.startsWith('Role')) {
          role = text.replaceFirst('Role', '').trim();
        } else if (text.startsWith('Batting Style')) {
          battingStyle = text.replaceFirst('Batting Style', '').trim();
        } else if (text.startsWith('Bowling Style')) {
          bowlingStyle = text.replaceFirst('Bowling Style', '').trim();
        } else if (text.startsWith('Country') || text.startsWith('Team')) {
          // Sometimes Country is not explicitly labeled "Country", but "Teams"
          // We can try to infer country from teams usually
        }
      }

      // Bio
      // Look for "Profile" header then content
      /*
        Structure variants:
        1. <div ...>Profile</div> <div ...>Content</div>
        2. <h3>Profile</h3> <p>Content</p>
      */
      final profileHeader = allDivs.firstWhere(
        (e) => e.text.trim() == 'Profile',
        orElse: () => document.createElement('div'),
      );
      if (profileHeader.parent != null) {
        // Try next sibling
        var sibling = profileHeader.nextElementSibling;
        if (sibling != null) {
          bio = sibling.text.trim();
        } else {
          // Try parent's next sibling
          sibling = profileHeader.parent?.nextElementSibling;
          if (sibling != null) {
            bio = sibling.text.trim();
          }
        }
      }

      // Stats
      final battingStats = <String, PlayerStats>{};
      final bowlingStats = <String, PlayerStats>{};

      final tables = document.querySelectorAll('table');

      for (int tableIdx = 0; tableIdx < tables.length; tableIdx++) {
        final table = tables[tableIdx];
        final headers = table
            .querySelectorAll('th')
            .map((e) => e.text.trim())
            .toList();
        final rows = table.querySelectorAll('tr');

        // Skip ranking tables (Format / Current Rank / Best Rank)
        if (headers.any((h) => h.contains('Rank') || h.contains('Format'))) {
          continue;
        }

        // Must have format headers like [empty, Test, ODI, T20, IPL]
        if (headers.length < 2) continue;
        final formats = headers.sublist(1);
        if (formats.isEmpty) continue;

        // Determine batting vs bowling by looking at the preceding
        // sibling text (e.g. "Batting Career Summary" / "Bowling Career Summary")
        // or by checking for unique bowling-only labels (Wickets, Eco, BBI, BBM, Maidens)
        final rowLabels = rows
            .map((r) => r.querySelector('td')?.text.trim() ?? '')
            .toSet();

        // Use unique labels to distinguish:
        // Bowling tables have: Wickets, Eco, BBI, BBM, Maidens
        // Batting tables have: Highest, Fours, Sixes, 50s, 100s, Ducks
        final bool isBowling =
            rowLabels.contains('Wickets') ||
            rowLabels.contains('Wkts') ||
            rowLabels.contains('Eco') ||
            rowLabels.contains('BBI') ||
            rowLabels.contains('BBM') ||
            rowLabels.contains('Maidens');
        final bool isBatting =
            rowLabels.contains('Highest') ||
            rowLabels.contains('Fours') ||
            rowLabels.contains('Sixes') ||
            rowLabels.contains('50s') ||
            rowLabels.contains('100s') ||
            rowLabels.contains('Ducks');

        if (!isBatting && !isBowling) continue;

        // Initialize stats map for these formats
        final Map<String, Map<String, dynamic>> tempStats = {};
        for (final fmt in formats) {
          tempStats[fmt] = {};
        }

        for (final row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length < formats.length + 1) continue;

          final label = cells[0].text.trim();
          final values = cells.sublist(1).map((e) => e.text.trim()).toList();

          for (int i = 0; i < formats.length && i < values.length; i++) {
            final fmt = formats[i];
            final val = values[i];

            if (val == '-' || val.isEmpty) continue;

            if (isBatting && !isBowling) {
              _parseBattingStat(tempStats[fmt]!, label, val);
            } else {
              _parseBowlingStat(tempStats[fmt]!, label, val);
            }
          }
        }

        // Convert tempStats to PlayerStats
        tempStats.forEach((fmt, data) {
          final stats = PlayerStats(
            matches: int.tryParse(data['matches']?.toString() ?? '0') ?? 0,
            innings: int.tryParse(data['innings']?.toString() ?? '0') ?? 0,
            runs: int.tryParse(data['runs']?.toString() ?? '0') ?? 0,
            notOuts: int.tryParse(data['notOuts']?.toString() ?? '0') ?? 0,
            highestScore:
                int.tryParse(data['highestScore']?.toString() ?? '0') ?? 0,
            average:
                double.tryParse(data['average']?.toString() ?? '0.0') ?? 0.0,
            strikeRate:
                double.tryParse(data['strikeRate']?.toString() ?? '0.0') ?? 0.0,
            hundreds: int.tryParse(data['hundreds']?.toString() ?? '0') ?? 0,
            fifties: int.tryParse(data['fifties']?.toString() ?? '0') ?? 0,
            fours: int.tryParse(data['fours']?.toString() ?? '0') ?? 0,
            sixes: int.tryParse(data['sixes']?.toString() ?? '0') ?? 0,
            wickets: int.tryParse(data['wickets']?.toString() ?? '0') ?? 0,
            bowlingAverage:
                double.tryParse(data['bowlingAverage']?.toString() ?? '0.0') ??
                0.0,
            economy:
                double.tryParse(data['economy']?.toString() ?? '0.0') ?? 0.0,
            bestBowling: data['bestBowling']?.toString() ?? '',
            fiveWickets:
                int.tryParse(data['fiveWickets']?.toString() ?? '0') ?? 0,
          );

          if (isBatting) {
            battingStats[fmt] = stats;
          } else {
            // Merge if exists (rare for transposed tables to separate like this but possible)
            // Usually separate tables.
            bowlingStats[fmt] = stats;
          }
        });
      }

      return Player(
        id: id,
        name: name,
        slug: slug,
        country: country, // Might remain empty if not found
        imageUrl: imageUrl,
        role: role,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        bio: bio,
        born: born,
        height: height,
        battingStats: battingStats,
        bowlingStats: bowlingStats,
      );
    } catch (e) {
      print('❌ Error fetching player detail: $e');
      rethrow;
    }
  }

  void _parseBattingStat(Map<String, dynamic> map, String label, String val) {
    // Labels: Matches, Innings, Runs, Average, SR, 100s, 50s, 4s, 6s
    if (label.contains('Matches')) {
      map['matches'] = val;
    } else if (label.contains('Innings'))
      map['innings'] = val;
    else if (label.contains('Runs'))
      map['runs'] = val;
    else if (label.contains('Average') || label == 'Avg')
      map['average'] = val;
    else if (label.contains('SR') || label.contains('Strike'))
      map['strikeRate'] = val;
    else if (label.contains('100s') || label == '100')
      map['hundreds'] = val;
    else if (label.contains('50s') || label == '50')
      map['fifties'] = val;
    else if (label.contains('4s'))
      map['fours'] = val;
    else if (label.contains('6s'))
      map['sixes'] = val;
    else if (label.contains('Not Out') || label == 'NO')
      map['notOuts'] = val;
    else if (label.contains('Highest') || label == 'HS')
      map['highestScore'] = val.replaceAll('*', '');
  }

  void _parseBowlingStat(Map<String, dynamic> map, String label, String val) {
    // Labels: Matches, Innings, Balls, Runs, Wickets, BBM, Econ/Eco, Avg, SR, BBI, 5w, 10w
    if (label.contains('Matches')) {
      map['matches'] = val;
    } else if (label.contains('Innings'))
      map['innings'] = val;
    else if (label.contains('Wickets') || label == 'Wkts')
      map['wickets'] = val;
    else if (label.contains('Econ') || label == 'Eco')
      map['economy'] = val;
    else if (label == 'Avg' || label == 'Average')
      map['bowlingAverage'] = val;
    else if (label == 'BBI' || label == 'BBM' || label.contains('Best'))
      map['bestBowling'] = val;
    else if (label.contains('5w') || label == '5W')
      map['fiveWickets'] = val;
  }

  @override
  Future<List<Player>> getTeamPlayers(String teamSlug, String teamId) async {
    try {
      // Try primary URL first
      final primaryUrl = '$_mBaseUrl/cricket-team/$teamSlug/$teamId/players';
      // Fallback URL used for associate/ICC member teams (different slug format)
      final fallbackUrl =
          '$_mBaseUrl/cricket-team/$teamSlug-cricket/$teamId/players';

      List<Player> players = await _scrapePlayersFromUrl(primaryUrl, teamSlug);

      // If no players found, try the fallback URL (e.g. namibia-cricket, canada-cricket)
      if (players.isEmpty) {
        players = await _scrapePlayersFromUrl(fallbackUrl, teamSlug);
      }

      // If still empty, try without the teamId path component (some older team pages)
      if (players.isEmpty) {
        final altUrl = '$_mBaseUrl/cricket-team/$teamSlug/players';
        players = await _scrapePlayersFromUrl(altUrl, teamSlug);
      }

      return players;
    } catch (e) {
      print('❌ Error fetching team players: $e');
      return [];
    }
  }

  Future<List<Player>> _scrapePlayersFromUrl(
    String url,
    String teamSlug,
  ) async {
    try {
      final response = await client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Player> players = [];
      String currentRole = 'Player';

      // Role category headings
      final allElements = document.querySelectorAll(
        'a[href*="/profiles/"], a[href*="/cricket-team/"]',
      );

      for (final element in allElements) {
        final href = element.attributes['href'] ?? '';
        final text = element.text.trim().toUpperCase();

        // Check if this is a role category heading
        if (href.contains('/cricket-team/') &&
            (text == 'BATSMEN' ||
                text == 'ALL ROUNDER' ||
                text == 'WICKET KEEPER' ||
                text == 'BOWLER')) {
          if (text == 'BATSMEN') {
            currentRole = 'Batsman';
          } else if (text == 'ALL ROUNDER')
            currentRole = 'All-Rounder';
          else if (text == 'WICKET KEEPER')
            currentRole = 'Wicket-Keeper';
          else if (text == 'BOWLER')
            currentRole = 'Bowler';
          continue;
        }

        // Process player links
        if (href.contains('/profiles/')) {
          final parts = href.split('/');
          final playerId = parts.length >= 3 ? parts[parts.length - 2] : '';
          final playerSlug = parts.isNotEmpty ? parts.last : '';
          final playerName = element.text.trim();

          if (playerName.isEmpty || playerId.isEmpty) continue;

          // Extract player image from img tag within the link
          final img = element.querySelector('img');
          String imageUrl = '';
          if (img != null) {
            imageUrl = img.attributes['src'] ?? '';
            if (imageUrl.isEmpty) {
              final srcSet = img.attributes['srcSet'] ?? '';
              if (srcSet.isNotEmpty) {
                imageUrl = srcSet.split(' ').first;
              }
            }
          }

          // Construct image URL from slug as fallback
          if (imageUrl.isEmpty && playerSlug.isNotEmpty) {
            imageUrl =
                'https://static.cricbuzz.com/a/img/v1/i1/c1/$playerSlug.jpg?d=low&p=gthumb';
          }

          players.add(
            Player(
              id: playerId,
              name: playerName,
              country: teamSlug
                  .replaceAll('-cricket', '')
                  .replaceAll('-', ' ')
                  .split(' ')
                  .map(
                    (w) => w.isNotEmpty
                        ? '${w[0].toUpperCase()}${w.substring(1)}'
                        : '',
                  )
                  .join(' '),
              role: currentRole,
              imageUrl: imageUrl,
            ),
          );
        }
      }

      return players;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<CricketTeam>> getSeriesSquads(String seriesId) async {
    try {
      final response = await client.get(
        Uri.parse('$_mBaseUrl/cricket-series/$seriesId/s/squads'),
        headers: _headers,
      );
      if (response.statusCode != 200) return [];

      final scriptRegex = RegExp(r'self\.__next_f\.push\(\[1,"(.*?)"\]\)');
      final matches = scriptRegex.allMatches(response.body);

      for (final match in matches) {
        String jsonStr = match.group(1) ?? '';
        jsonStr = jsonStr.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');

        if (jsonStr.contains('"squads":[')) {
          final startIdx = jsonStr.indexOf('"squads":[');
          if (startIdx != -1) {
            final endIdx = jsonStr.indexOf('],"appIndex"', startIdx);
            if (endIdx != -1) {
              final squadsData = jsonStr.substring(
                startIdx + '"squads":'.length,
                endIdx + 1,
              );

              final List<dynamic> squadsList = json.decode(squadsData);
              final List<CricketTeam> teams = [];

              for (final squad in squadsList) {
                if (squad['isHeader'] == true) continue;
                
                final String teamName = squad['squadType'] ?? '';
                final int teamId = squad['teamId'] ?? 0;
                final int imageId = squad['imageId'] ?? 0;
                
                if (teamName.isNotEmpty && teamId > 0) {
                  final String slug = teamName.toLowerCase().replaceAll(' ', '-');
                  final String flagUrl = imageId > 0
                      ? 'https://static.cricbuzz.com/a/img/v1/72x54/i1/c$imageId/$slug.jpg'
                      : '';
                      
                  teams.add(
                    CricketTeam(
                      id: teamId.toString(),
                      name: teamName,
                      slug: slug,
                      flagUrl: flagUrl,
                    ),
                  );
                }
              }

              if (teams.isNotEmpty) return teams;
            }
          }
        }
      }
      return [];
    } catch (e) {
      print('Error parsing squads data: $e');
      return [];
    }
  }

  @override
  Future<List<Series>> getSeries() async {
    try {
      final response = await client.get(
        Uri.parse('$_mBaseUrl/cricket-schedule/series/all'),
        headers: _headers,
      );
      if (response.statusCode != 200) return _getFallbackSeries();

      // Try to parse from embedded JSON first (Next.js data)
      try {
        final scriptRegex = RegExp(r'self\.__next_f\.push\(\[1,"(.*?)"\]\)');
        final matches = scriptRegex.allMatches(response.body);

        for (final match in matches) {
          String jsonStr = match.group(1) ?? '';
          // Unescape JSON string
          jsonStr = jsonStr.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');

          if (jsonStr.contains('seriesScheduleData')) {
            // Find the array part
            final startIdx = jsonStr.indexOf('"seriesScheduleData":[');
            if (startIdx != -1) {
              final endIdx = jsonStr.indexOf('],"contentFilters"', startIdx);
              if (endIdx != -1) {
                final seriesData = jsonStr.substring(
                  startIdx + '"seriesScheduleData":'.length,
                  endIdx + 1,
                );

                // Parse the array of month objects
                final List<dynamic> months = json.decode(seriesData);
                final List<Series> allSeries = [];

                for (final month in months) {
                  final List<dynamic> seriesList = month['series'] ?? [];
                  for (final s in seriesList) {
                    final startMs = int.tryParse(s['startDt']);
                    final endMs = int.tryParse(s['endDt']);

                    if (startMs != null && endMs != null) {
                      final start = DateTime.fromMillisecondsSinceEpoch(
                        startMs,
                      );
                      final end = DateTime.fromMillisecondsSinceEpoch(endMs);

                      allSeries.add(
                        Series(
                          id: s['id'].toString(),
                          name: s['name'] ?? '',
                          startDate: _formatDate(start),
                          endDate: _formatDate(end),
                          startDateTime: start,
                          endDateTime: end,
                          type: _determineSeriesType(s['name'] ?? ''),
                        ),
                      );
                    }
                  }
                }

                if (allSeries.isNotEmpty) return allSeries;
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ JSON parsing failed for series, falling back to HTML: $e');
      }

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
            final parts = href.split('/');
            // URL is usually /cricket-series/11253/name
            final id = parts.length > 2 ? parts[2] : parts.last;

            if (name.isEmpty) return null;
            return Series(
              id: id,
              name: name,
              startDate: dates.split('-').first.trim(),
              endDate: dates.contains('-') ? dates.split('-').last.trim() : '',
              type: _determineSeriesType(name),
            );
          })
          .whereType<Series>()
          .toList();

      return results.isEmpty ? _getFallbackSeries() : results;
    } catch (e) {
      return _getFallbackSeries();
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  SeriesType _determineSeriesType(String name) {
    final lower = name.toLowerCase();

    // 0. Women's series (check first before other categories)
    if (lower.contains('women') || lower.contains('women\'s')) {
      return SeriesType.women;
    }

    // 1. Explicit Leagues
    if (lower.contains('ipl') || lower.contains('indian premier league')) {
      return SeriesType.ipl;
    }
    if (lower.contains('league') || // Big Bash League, Premier League
        lower.contains('t20 blast') ||
        lower.contains('the hundred') ||
        lower.contains('sa20') ||
        lower.contains('msl') ||
        lower.contains('mlc')) {
      return SeriesType.t20League;
    }

    // 2. Domestic Tournaments
    if (lower.contains('trophy') || // Ranji, Vijay Hazare, Deodhar
        lower.contains('shield') || // Sheffield Shield
        lower.contains('cup') &&
            !lower.contains('world') &&
            !lower.contains('asia') && // World Cup, Asia Cup are Int'l
            !lower.contains('t20i') ||
        lower.contains('county') || // County Championship
        lower.contains('one-day cup') ||
        lower.contains('division')) {
      return SeriesType.domestic;
    }

    // 3. Default to International (Tours, World cups, etc.)
    return SeriesType.international;
  }

  @override
  Future<Series> getSeriesDetail(String seriesId) async {
    try {
      final response = await client.get(
        Uri.parse('$_mBaseUrl/cricket-series/$seriesId/s/matches'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        return Series(id: seriesId, name: 'Series $seriesId');
      }

      final body = response.body;

      // --- Extract series name from <h1> in HTML ---
      String seriesName = 'Series $seriesId';
      final document = parse(body);
      final h1 = document.querySelector('h1');
      if (h1 != null && h1.text.trim().isNotEmpty) {
        seriesName = h1.text.trim();
      }

      // --- Extract match data from Next.js RSC payload ---
      // Cricbuzz uses Next.js RSC; data is in self.__next_f.push([1,"..."]) scripts.
      // The content is double-escaped JSON: \" -> " and \\ -> \
      final rscPattern = RegExp(
        r'self\.__next_f\.push\(\[1,"(.*?)"\]\)',
        dotAll: true,
      );
      final rscMatches = rscPattern.allMatches(body);

      // Concatenate all RSC chunks and unescape
      final rscBuffer = StringBuffer();
      for (final m in rscMatches) {
        rscBuffer.write(m.group(1) ?? '');
      }
      // Unescape the RSC data: \" -> " and \\ -> \
      String rscData = rscBuffer.toString();
      rscData = rscData.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');

      // Now find all matchInfo blocks for this series
      final List<CricketMatch> matches = [];
      final Set<String> seenIds = {};

      // Scan for "matchId": patterns in the unescaped data
      int searchFrom = 0;
      while (true) {
        final idx = rscData.indexOf('"matchId":', searchFrom);
        if (idx == -1) break;
        searchFrom = idx + 10;

        // Extract matchId value
        final idMatch = RegExp(r'"matchId":(\d+)').firstMatch(
          rscData.substring(idx, (idx + 30).clamp(0, rscData.length)),
        );
        if (idMatch == null) continue;
        final matchId = idMatch.group(1)!;
        if (seenIds.contains(matchId)) continue;

        // Check if this match belongs to our series
        final contextStart = (idx - 200).clamp(0, rscData.length);
        final contextEnd = (idx + 50).clamp(0, rscData.length);
        final context = rscData.substring(contextStart, contextEnd);
        if (!context.contains('"seriesId":$seriesId') &&
            !context.contains('"seriesId": $seriesId')) {
          // Check further ahead too
          final aheadEnd = (idx + 200).clamp(0, rscData.length);
          final ahead = rscData.substring(idx, aheadEnd);
          if (!ahead.contains('"seriesId":$seriesId') &&
              !ahead.contains('"seriesId": $seriesId')) {
            continue;
          }
        }
        seenIds.add(matchId);

        // Extract a window of text around this matchInfo for parsing
        final windowStart = (idx - 50).clamp(0, rscData.length);
        final windowEnd = (idx + 1500).clamp(0, rscData.length);
        final window = rscData.substring(windowStart, windowEnd);

        // Extract fields using simple regex on unescaped JSON
        String extract(String key, String data) {
          final m = RegExp('"$key":"(.*?)"').firstMatch(data);
          return m?.group(1) ?? '';
        }

        int extractInt(String key, String data) {
          final m = RegExp('"$key":(\\d+)').firstMatch(data);
          return int.tryParse(m?.group(1) ?? '') ?? 0;
        }

        double extractDouble(String key, String data) {
          final m = RegExp('"$key":([\\d.]+)').firstMatch(data);
          return double.tryParse(m?.group(1) ?? '') ?? 0.0;
        }

        final matchDesc = extract('matchDesc', window);
        final matchFormat = extract('matchFormat', window);
        final state = extract('state', window);
        final status = extract('status', window);
        final startDateStr = extract('startDate', window);

        // Extract team1 info
        String t1Name = 'Team 1';
        String t1Short = 'T1';
        int t1ImageId = 0;
        final t1Idx = window.indexOf('"team1":{');
        if (t1Idx != -1) {
          final t1End = (t1Idx + 300).clamp(0, window.length);
          final t1Data = window.substring(t1Idx, t1End);
          t1Name = extract('teamName', t1Data);
          t1Short = extract('teamSName', t1Data);
          t1ImageId = extractInt('imageId', t1Data);
        }

        // Extract team2 info
        String t2Name = 'Team 2';
        String t2Short = 'T2';
        int t2ImageId = 0;
        final t2Idx = window.indexOf('"team2":{');
        if (t2Idx != -1) {
          final t2End = (t2Idx + 300).clamp(0, window.length);
          final t2Data = window.substring(t2Idx, t2End);
          t2Name = extract('teamName', t2Data);
          t2Short = extract('teamSName', t2Data);
          t2ImageId = extractInt('imageId', t2Data);
        }

        // Extract venue
        String venue = 'TBD';
        final venueIdx = window.indexOf('"venueInfo":{');
        if (venueIdx != -1) {
          final venueEnd = (venueIdx + 200).clamp(0, window.length);
          final venueData = window.substring(venueIdx, venueEnd);
          final ground = extract('ground', venueData);
          final city = extract('city', venueData);
          if (ground.isNotEmpty) {
            venue = city.isNotEmpty ? '$ground, $city' : ground;
          }
        }

        // Extract scores
        String t1Score = '';
        String t2Score = '';
        final scoreIdx = window.indexOf('"matchScore":{');
        if (scoreIdx != -1) {
          final scoreEnd = (scoreIdx + 500).clamp(0, window.length);
          final scoreData = window.substring(scoreIdx, scoreEnd);

          final t1sIdx = scoreData.indexOf('"team1Score":{');
          if (t1sIdx != -1) {
            final innEnd = (t1sIdx + 200).clamp(0, scoreData.length);
            final innData = scoreData.substring(t1sIdx, innEnd);
            final runs = extractInt('runs', innData);
            final wickets = extractInt('wickets', innData);
            final overs = extractDouble('overs', innData);
            if (runs > 0 || wickets > 0) {
              t1Score = '$runs/$wickets ($overs)';
            }
          }
          final t2sIdx = scoreData.indexOf('"team2Score":{');
          if (t2sIdx != -1) {
            final innEnd = (t2sIdx + 200).clamp(0, scoreData.length);
            final innData = scoreData.substring(t2sIdx, innEnd);
            final runs = extractInt('runs', innData);
            final wickets = extractInt('wickets', innData);
            final overs = extractDouble('overs', innData);
            if (runs > 0 || wickets > 0) {
              t2Score = '$runs/$wickets ($overs)';
            }
          }
        }

        // Determine match status
        MatchStatus matchStatus;
        if (state == 'In Progress' || state == 'Innings Break') {
          matchStatus = MatchStatus.live;
        } else if (state == 'Complete') {
          matchStatus = MatchStatus.completed;
        } else {
          matchStatus = MatchStatus.upcoming;
        }

        // Determine match format
        MatchFormat format;
        switch (matchFormat.toUpperCase()) {
          case 'TEST':
            format = MatchFormat.test;
            break;
          case 'ODI':
            format = MatchFormat.odi;
            break;
          case 'T20':
          case 'T20I':
            format = MatchFormat.t20;
            break;
          default:
            format = MatchFormat.other;
        }

        // Parse start time
        DateTime startTime = DateTime.now();
        if (startDateStr.isNotEmpty) {
          try {
            startTime = DateTime.fromMillisecondsSinceEpoch(
              int.parse(startDateStr),
            );
          } catch (_) {}
        }

        // Build team flag URLs
        final t1Flag = t1ImageId > 0
            ? 'https://static.cricbuzz.com/a/img/v1/72x72/i1/c$t1ImageId/team.jpg'
            : '';
        final t2Flag = t2ImageId > 0
            ? 'https://static.cricbuzz.com/a/img/v1/72x72/i1/c$t2ImageId/team.jpg'
            : '';

        matches.add(
          CricketMatch(
            id: matchId,
            title: matchDesc,
            seriesName: seriesName,
            venue: venue,
            status: matchStatus,
            format: format,
            startTime: startTime,
            team1: Team(
              id: t1Short, // Use short name as ID if real ID missing
              name: t1Name,
              shortName: t1Short,
              flagUrl: t1Flag,
              score: t1Score,
            ),
            team2: Team(
              id: t2Short,
              name: t2Name,
              shortName: t2Short,
              flagUrl: t2Flag,
              score: t2Score,
            ),
            statusText: status,
            result: matchStatus == MatchStatus.completed ? status : null,
          ),
        );
      }

      // Sort matches by start time
      matches.sort((a, b) => a.startTime.compareTo(b.startTime));

      return Series(id: seriesId, name: seriesName, matches: matches);
    } catch (e) {
      print('❌ Error in getSeriesDetail: $e');
      return Series(id: seriesId, name: 'Series $seriesId');
    }
  }

  @override
  @override
  Stream<CricketMatch> getLiveScoreStream(String matchId) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      final detail = await getMatchDetail(matchId);
      yield detail.match;
    }
  }

  Future<List<CricketMatch>> _fetchMatches(
    String path,
    MatchStatus status,
  ) async {
    try {
      // Add timestamp to bypass CDN caching which can cause "back and forth" score flickering
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final separator = path.contains('?') ? '&' : '?';
      final url = '$_baseUrl$path${separator}_ts=$timestamp';

      final response = await client.get(Uri.parse(url), headers: _headers);
      if (response.statusCode != 200) return _getFallbackMatches(status);

      final document = parse(response.body);
      final matchCards = document.querySelectorAll('a.bg-cbWhite');

      final results = matchCards
          .map((card) {
            final link = card.attributes['href'] ?? '';
            if (!link.contains('/live-cricket-scores/') &&
                !link.contains('/cricket-scores/') &&
                !link.contains('/scoreboard/')) {
              return null;
            }

            final spans = card.querySelectorAll('span');
            String? title, team1Name, team2Name;
            String team1Flag = '', team2Flag = '';
            String? score1, score2, statusText;

            // Try extracting team names from title attribute
            final cardTitle = card.attributes['title'] ?? '';
            if (cardTitle.contains(' vs ')) {
              final parts = cardTitle.split(',');
              final teamsPart = parts[0];
              if (teamsPart.contains(' vs ')) {
                final teamNames = teamsPart.split(' vs ');
                team1Name = teamNames[0].trim();
                team2Name = teamNames[1].trim();
              }
            }

            final images = card.querySelectorAll('img');
            if (images.length >= 2) {
              team1Flag = images[0].attributes['src'] ?? '';
              team2Flag = images[1].attributes['src'] ?? '';

              if (team1Name == null || team1Name.isEmpty) {
                final alt1 = images[0].attributes['alt'] ?? '';
                if (alt1.isNotEmpty && !alt1.contains('logo')) {
                  team1Name = alt1.trim();
                }
              }
              if (team2Name == null || team2Name.isEmpty) {
                final alt2 = images[1].attributes['alt'] ?? '';
                if (alt2.isNotEmpty && !alt2.contains('logo')) {
                  team2Name = alt2.trim();
                }
              }

              if (team1Flag.startsWith('/')) team1Flag = _baseUrl + team1Flag;
              if (team2Flag.startsWith('/')) team2Flag = _baseUrl + team2Flag;
            }

            if (spans.isNotEmpty) {
              statusText = spans.last.text.trim();

              String? t1Abbr, t2Abbr;

              // Rewrite extraction using the exact HTML row structure
              // Each team gets its own standard row: <div class="flex items-center gap-4 justify-between">
              final teamRows = card.querySelectorAll(
                '.flex.items-center.gap-4.justify-between',
              );

              if (teamRows.length >= 2) {
                // TEAM 1 ROW
                final t1Row = teamRows[0];
                final t1NameSpans =
                    t1Row.children.isNotEmpty &&
                        t1Row.children[0].children.isNotEmpty
                    ? t1Row.children[0].querySelectorAll('span')
                    : [];
                if (t1NameSpans.length >= 2) {
                  final abbr = t1NameSpans[1].text.trim();
                  if (abbr.isNotEmpty && abbr.length <= 5) t1Abbr = abbr;
                }
                if (t1Row.children.length >= 2) {
                  final s = t1Row.children.last.text.trim();
                  if (s.isNotEmpty) score1 = s;
                }

                // TEAM 2 ROW
                final t2Row = teamRows[1];
                final t2NameSpans =
                    t2Row.children.isNotEmpty &&
                        t2Row.children[0].children.isNotEmpty
                    ? t2Row.children[0].querySelectorAll('span')
                    : [];
                if (t2NameSpans.length >= 2) {
                  final abbr = t2NameSpans[1].text.trim();
                  if (abbr.isNotEmpty && abbr.length <= 5) t2Abbr = abbr;
                }
                if (t2Row.children.length >= 2) {
                  final s = t2Row.children.last.text.trim();
                  if (s.isNotEmpty) score2 = s;
                }
              }

              // Only assign abbreviation if we utterly lack a team name from the image alt text
              if (team1Name == null ||
                  team1Name.isEmpty ||
                  team1Name == 'Team 1') {
                if (t1Abbr != null) team1Name = t1Abbr;
              }
              if (team2Name == null ||
                  team2Name.isEmpty ||
                  team2Name == 'Team 2') {
                if (t2Abbr != null) team2Name = t2Abbr;
              }

              final header = spans.firstWhere(
                (s) => s.text.contains('•'),
                orElse: () => spans.first,
              );
              title = header.text.trim();
            }

            team1Name ??= 'Team 1';
            team2Name ??= 'Team 2';
            title ??= 'Unknown Match';

            final parts = link.split('/').where((s) => s.isNotEmpty).toList();
            if (parts.length < 2) return null;
            final id = parts[1]; // Correct numeric ID
            MatchStatus matchStatus = status;
            final lowerStatusText = statusText?.toLowerCase() ?? '';
            final lowerTitle = (title).toLowerCase();
            final lowerAll = ('$lowerStatusText $lowerTitle').trim();
            bool hasMatch(String pattern) =>
                RegExp('\\b$pattern\\b').hasMatch(lowerAll);

            if (lowerAll.contains('won by') ||
                hasMatch('won') ||
                hasMatch('result') ||
                hasMatch('drawn') ||
                hasMatch('abandoned') ||
                lowerAll.contains('no result')) {
              matchStatus = MatchStatus.completed;
            } else if (hasMatch('live') ||
                lowerAll.contains('runs needed') ||
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
                RegExp(r'\d{1,2}:\d{2}').hasMatch(lowerAll)) {
              matchStatus = MatchStatus.upcoming;
            }

            var format = _guessFormat('$title $link');
            if (format == MatchFormat.t20 &&
                _isInternationalTeam(team1Name) &&
                _isInternationalTeam(team2Name)) {
              format = MatchFormat.t20i;
            }

            return CricketMatch(
              id: id,
              title: title,
              seriesName: 'International',
              venue: 'TBD',
              status: matchStatus,
              format: format,
              startTime: DateTime.now(),
              team1: Team(
                id: team1Name,
                name: team1Name,
                shortName: _getTeamShortName(team1Name),
                flagUrl: team1Flag,
                score: score1,
              ),
              team2: Team(
                id: team2Name,
                name: team2Name,
                shortName: _getTeamShortName(team2Name),
                flagUrl: team2Flag,
                score: score2,
              ),
              statusText: statusText,
            );
          })
          .whereType<CricketMatch>()
          .toList();

      final filtered = results.where((m) => m.status == status).toList();

      // Sort deterministically to prevent UI "shuffling" on 15s refresh
      // Since startTime is not always available without slow individual API calls,
      // the match numerical ID is chronological and ensures perfect stable rendering.
      filtered.sort((a, b) {
        final idA = int.tryParse(a.id) ?? 0;
        final idB = int.tryParse(b.id) ?? 0;
        if (status == MatchStatus.completed) {
          return idB.compareTo(idA); // Descending for recent
        }
        return idA.compareTo(idB); // Ascending for upcoming/live
      });

      return filtered.isEmpty ? _getFallbackMatches(status) : filtered;
    } catch (e) {
      return _getFallbackMatches(status);
    }
  }

  List<CricketMatch> _getFallbackMatches(MatchStatus status) {
    return [];
  }

  List<Series> _getFallbackSeries() {
    return [];
  }

  /// Get proper short name for a team based on common cricket team abbreviations
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
      // Take first letter of each significant word (skip "the", "of", etc.)
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

  MatchFormat _guessFormat(String text) {
    final lower = text.toLowerCase();

    // 1. Explicit International Formats
    if (lower.contains('t20i')) return MatchFormat.t20i;
    if (lower.contains('test')) return MatchFormat.test;
    if (lower.contains('odi')) return MatchFormat.odi;

    // 2. Explicit Domestic Leagues (Override any other detection)
    if (lower.contains('ipl') || lower.contains('indian premier league')) {
      return MatchFormat.ipl;
    }
    if (lower.contains('bbl') ||
        lower.contains('psl') ||
        lower.contains('cpl') ||
        lower.contains('lpl') ||
        lower.contains('sa20') ||
        lower.contains('hundred')) {
      return MatchFormat.t20;
    }

    // 3. International Tournaments (treated as International T20 if 't20' present)
    if (lower.contains('t20') &&
        (lower.contains('world cup') ||
            lower.contains('asia cup') ||
            lower.contains('icc ') ||
            lower.contains('tri-series'))) {
      return MatchFormat.t20i;
    }

    // 4. Default T20 -> Domestic (if not matched above)
    if (lower.contains('t20')) return MatchFormat.t20;

    return MatchFormat.other;
  }

  bool _isInternationalTeam(String teamName) {
    final cleanName = teamName
        .replaceAll(
          RegExp(r'\s+(women|men|u19|u-19)$', caseSensitive: false),
          '',
        )
        .trim()
        .toLowerCase();

    const knownCountries = {
      'india',
      'australia',
      'england',
      'pakistan',
      'south africa',
      'new zealand',
      'sri lanka',
      'west indies',
      'bangladesh',
      'afghanistan',
      'zimbabwe',
      'ireland',
      'netherlands',
      'scotland',
      'uae',
      'united arab emirates',
      'namibia',
      'oman',
      'nepal',
      'usa',
      'united states',
      'united states of america',
      'canada',
      'papua new guinea',
      'hong kong',
      'italy',
      'germany',
      'jersey',
      'guernsey',
      'austria',
      'belgium',
      'spain',
      'portugal',
      'denmark',
      'finland',
      'norway',
      'sweden',
      'uganda',
      'kenya',
      'tanzania',
      'nigeria',
      'rwanda',
      'kuwait',
      'bahrain',
      'saudi arabia',
      'qatar',
      'malaysia',
      'singapore',
      'thailand',
      'japan',
      'indonesia',
    };

    return knownCountries.contains(cleanName);
  }
}
