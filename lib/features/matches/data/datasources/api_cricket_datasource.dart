import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:cricketbuzz/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/team_entity.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

class ApiCricketDataSource implements CricketDataSource {
  final http.Client client;
  final String _baseUrl = 'https://www.cricbuzz.com';
  final String _mBaseUrl = 'https://m.cricbuzz.com';

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
          if (flagImgs.isNotEmpty) {
            t1FlagUrl = flagImgs[0].attributes['src'] ?? '';
          }
          if (flagImgs.length >= 2) {
            // Get second unique flag URL (skip duplicates of team1)
            for (int i = 1; i < flagImgs.length; i++) {
              final src = flagImgs[i].attributes['src'] ?? '';
              if (src != t1FlagUrl) {
                t2FlagUrl = src;
                break;
              }
            }
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
      // Usually Table 2 is Batting, Table 3 is Bowling (0 and 1 are rankings)
      // But verify by headers
      for (final table in tables) {
        final headers = table
            .querySelectorAll('th')
            .map((e) => e.text.trim())
            .toList();
        final rows = table.querySelectorAll('tr');

        if (headers.isEmpty && rows.isNotEmpty) {
          // Transposed table logic?
          // Actually header might be the first row locally
        }

        // Check if this is batting or bowling based on row labels
        bool isBatting = false;
        bool isBowling = false;

        final rowLabels = rows
            .map((r) => r.querySelector('td')?.text.trim() ?? '')
            .toSet();
        if (rowLabels.contains('Runs') && rowLabels.contains('Innings')) {
          isBatting = true;
        }
        if (rowLabels.contains('Wickets') || rowLabels.contains('Wkts')) {
          isBowling = true;
        }

        if (!isBatting && !isBowling) continue;

        // Parse Transposed Table
        // Headers (Formats): first row usually has th or td?
        // My script showed keys are in first column, formats in header row
        // Table 2 headers: [, Test, ODI, T20, IPL]

        final formats = headers.sublist(1); // Skip first empty header

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

          for (int i = 0; i < formats.length; i++) {
            final fmt = formats[i];
            final val = values[i];

            if (val == '-' || val.isEmpty) continue;

            if (isBatting) {
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
      throw e;
    }
  }

  void _parseBattingStat(Map<String, dynamic> map, String label, String val) {
    // Labels: Matches, Innings, Runs, Average, SR, 100s, 50s, 4s, 6s
    if (label.contains('Matches'))
      map['matches'] = val;
    else if (label.contains('Innings'))
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
    // Labels: Matches, Innings, Balls, Runs, Wickets, BBM, Econ, Avg, SR, 5w, 10w
    if (label.contains('Matches'))
      map['matches'] = val;
    else if (label.contains('Innings'))
      map['innings'] = val;
    else if (label.contains('Wickets') || label == 'Wkts')
      map['wickets'] = val;
    else if (label.contains('Econ'))
      map['economy'] = val;
    else if (label.contains('Avg'))
      map['bowlingAverage'] = val;
    else if (label.contains('BBM') || label.contains('Best'))
      map['bestBowling'] = val;
    else if (label.contains('5w') || label == '5W')
      map['fiveWickets'] = val;
  }

  @override
  Future<List<Player>> getTeamPlayers(String teamSlug, String teamId) async {
    try {
      final response = await client.get(
        Uri.parse('$_mBaseUrl/cricket-team/$teamSlug/$teamId/players'),
        headers: _headers,
      );
      if (response.statusCode != 200) return [];

      final document = parse(response.body);
      final List<Player> players = [];
      String currentRole = 'Player';

      // Also find role category headings
      // The page structure has role headings (BATSMEN, ALL ROUNDER, WICKET KEEPER, BOWLER)
      // followed by player links
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
          if (text == 'BATSMEN')
            currentRole = 'Batsman';
          else if (text == 'ALL ROUNDER')
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
              // Try srcSet
              final srcSet = img.attributes['srcSet'] ?? '';
              if (srcSet.isNotEmpty) {
                imageUrl = srcSet.split(' ').first;
              }
            }
          }

          // If no img found in link, try to construct from slug
          if (imageUrl.isEmpty && playerSlug.isNotEmpty) {
            imageUrl =
                'https://static.cricbuzz.com/a/img/v1/i1/c1/$playerSlug.jpg?d=low&p=gthumb';
          }

          players.add(
            Player(
              id: playerId,
              name: playerName,
              country: teamSlug
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
    } catch (e) {
      print('❌ Error fetching team players: $e');
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
        String _extract(String key, String data) {
          final m = RegExp('"$key":"(.*?)"').firstMatch(data);
          return m?.group(1) ?? '';
        }

        int _extractInt(String key, String data) {
          final m = RegExp('"$key":(\\d+)').firstMatch(data);
          return int.tryParse(m?.group(1) ?? '') ?? 0;
        }

        double _extractDouble(String key, String data) {
          final m = RegExp('"$key":([\\d.]+)').firstMatch(data);
          return double.tryParse(m?.group(1) ?? '') ?? 0.0;
        }

        final matchDesc = _extract('matchDesc', window);
        final matchFormat = _extract('matchFormat', window);
        final state = _extract('state', window);
        final status = _extract('status', window);
        final startDateStr = _extract('startDate', window);

        // Extract team1 info
        String t1Name = 'Team 1';
        String t1Short = 'T1';
        int t1ImageId = 0;
        final t1Idx = window.indexOf('"team1":{');
        if (t1Idx != -1) {
          final t1End = (t1Idx + 300).clamp(0, window.length);
          final t1Data = window.substring(t1Idx, t1End);
          t1Name = _extract('teamName', t1Data);
          t1Short = _extract('teamSName', t1Data);
          t1ImageId = _extractInt('imageId', t1Data);
        }

        // Extract team2 info
        String t2Name = 'Team 2';
        String t2Short = 'T2';
        int t2ImageId = 0;
        final t2Idx = window.indexOf('"team2":{');
        if (t2Idx != -1) {
          final t2End = (t2Idx + 300).clamp(0, window.length);
          final t2Data = window.substring(t2Idx, t2End);
          t2Name = _extract('teamName', t2Data);
          t2Short = _extract('teamSName', t2Data);
          t2ImageId = _extractInt('imageId', t2Data);
        }

        // Extract venue
        String venue = 'TBD';
        final venueIdx = window.indexOf('"venueInfo":{');
        if (venueIdx != -1) {
          final venueEnd = (venueIdx + 200).clamp(0, window.length);
          final venueData = window.substring(venueIdx, venueEnd);
          final ground = _extract('ground', venueData);
          final city = _extract('city', venueData);
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
            final runs = _extractInt('runs', innData);
            final wickets = _extractInt('wickets', innData);
            final overs = _extractDouble('overs', innData);
            if (runs > 0 || wickets > 0) {
              t1Score = '$runs/$wickets ($overs)';
            }
          }
          final t2sIdx = scoreData.indexOf('"team2Score":{');
          if (t2sIdx != -1) {
            final innEnd = (t2sIdx + 200).clamp(0, scoreData.length);
            final innData = scoreData.substring(t2sIdx, innEnd);
            final runs = _extractInt('runs', innData);
            final wickets = _extractInt('wickets', innData);
            final overs = _extractDouble('overs', innData);
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
                if (alt1.isNotEmpty && !alt1.contains('logo'))
                  team1Name = alt1.trim();
              }
              if (team2Name == null || team2Name.isEmpty) {
                final alt2 = images[1].attributes['alt'] ?? '';
                if (alt2.isNotEmpty && !alt2.contains('logo'))
                  team2Name = alt2.trim();
              }

              if (team1Flag.startsWith('/')) team1Flag = _baseUrl + team1Flag;
              if (team2Flag.startsWith('/')) team2Flag = _baseUrl + team2Flag;
            }

            if (spans.isNotEmpty) {
              statusText = spans.last.text.trim();
              final teamCandidates = spans.where((s) {
                final t = s.text.trim().toLowerCase();
                if (t.isEmpty || t.length < 2) return false;
                if (t.contains('•') || t.contains('/')) return false;
                if (RegExp(r'^\d+[-–—]\d+$|^\d+/\d+$').hasMatch(t))
                  return false;
                if (RegExp(r'^\(\d+\.?\d*\s*(ov|overs)\)$').hasMatch(t))
                  return false;
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
                  'match',
                  'vs',
                ];
                return !statusKeywords.any((kw) => t.contains(kw));
              }).toList();

              if (team1Name == null && teamCandidates.isNotEmpty)
                team1Name = teamCandidates[0].text.trim();
              if (team2Name == null && teamCandidates.length >= 2)
                team2Name = teamCandidates[1].text.trim();

              final scoreCandidates = spans
                  .where((s) => RegExp(r'\d+[-–—]\d+|\d+/\d+').hasMatch(s.text))
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

            team1Name ??= 'Team 1';
            team2Name ??= 'Team 2';
            title ??= 'Unknown Match';

            final parts = link.split('/').where((s) => s.isNotEmpty).toList();
            if (parts.length < 2) return null;
            final id = parts[1]; // Correct numeric ID
            MatchStatus matchStatus = status;
            final lowerStatusText = statusText?.toLowerCase() ?? '';
            final lowerTitle = (title).toLowerCase();
            final lowerAll = (lowerStatusText + ' ' + lowerTitle).trim();
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
      return filtered.isEmpty ? _getFallbackMatches(status) : filtered;
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
