import 'dart:async';

import 'package:cricketbuzz/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/player_entity.dart';
import 'package:cricketbuzz/features/players/domain/entities/team_entity.dart';
import 'package:cricketbuzz/features/series/domain/entities/series_entity.dart';

/// Mock implementation of CricketDataSource with realistic Indian cricket data.
/// Replace with real API when available.
class MockCricketDataSource implements CricketDataSource {
  // ─── Live Matches ────────────────────────────────────────
  @override
  Future<List<CricketMatch>> getLiveMatches() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      CricketMatch(
        id: 'live_1',
        title: '1st Test',
        seriesName: 'India Tour of Australia, 2026',
        venue: 'Melbourne Cricket Ground',
        status: MatchStatus.live,
        format: MatchFormat.test,
        startTime: DateTime.now().subtract(const Duration(hours: 5)),
        team1: const Team(
          id: 't_ind',
          name: 'India',
          shortName: 'IND',
          flagUrl: '🇮🇳',
          score: '287/4',
          overs: '72.3',
        ),
        team2: const Team(
          id: 't_aus',
          name: 'Australia',
          shortName: 'AUS',
          flagUrl: '🇦🇺',
          score: '263',
          overs: '89.2',
        ),
        statusText: 'Day 2 - India lead by 24 runs',
        isFeatured: true,
      ),

      CricketMatch(
        id: 'live_3',
        title: '2nd ODI',
        seriesName: 'England Tour of India, 2026',
        venue: 'Eden Gardens, Kolkata',
        status: MatchStatus.live,
        format: MatchFormat.odi,
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        team1: const Team(
          id: 't_ind2',
          name: 'India',
          shortName: 'IND',
          flagUrl: '🇮🇳',
          score: '312/7',
          overs: '50.0',
        ),
        team2: const Team(
          id: 't_eng',
          name: 'England',
          shortName: 'ENG',
          flagUrl: '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
          score: '198/4',
          overs: '32.1',
        ),
        statusText: 'England need 115 runs from 107 balls',
      ),
    ];
  }

  // ─── Upcoming Matches ────────────────────────────────────
  @override
  Future<List<CricketMatch>> getUpcomingMatches() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      CricketMatch(
        id: 'up_1',
        title: '3rd T20I',
        seriesName: 'India Tour of Australia, 2026',
        venue: 'Sydney Cricket Ground',
        status: MatchStatus.upcoming,
        format: MatchFormat.t20i,
        startTime: DateTime.now().add(const Duration(hours: 8)),
        team1: const Team(
          id: 't_ind',
          name: 'India',
          shortName: 'IND',
          flagUrl: '🇮🇳',
        ),
        team2: const Team(
          id: 't_aus',
          name: 'Australia',
          shortName: 'AUS',
          flagUrl: '🇦🇺',
        ),
      ),
      CricketMatch(
        id: 'up_2',
        title: 'Match 46 - RCB vs KKR',
        seriesName: 'Indian Premier League 2026',
        venue: 'M. Chinnaswamy Stadium, Bengaluru',
        status: MatchStatus.upcoming,
        format: MatchFormat.ipl,
        startTime: DateTime.now().add(const Duration(hours: 26)),
        team1: const Team(
          id: 't_rcb',
          name: 'Royal Challengers Bengaluru',
          shortName: 'RCB',
          flagUrl: 'https://static.cricketlineguru.com/rcb.png',
        ),
        team2: const Team(
          id: 't_kkr',
          name: 'Kolkata Knight Riders',
          shortName: 'KKR',
          flagUrl: 'https://static.cricketlineguru.com/kkr.png',
        ),
      ),
      CricketMatch(
        id: 'up_3',
        title: '1st Test',
        seriesName: 'Pakistan Tour of South Africa, 2026',
        venue: 'Wanderers Stadium, Johannesburg',
        status: MatchStatus.upcoming,
        format: MatchFormat.test,
        startTime: DateTime.now().add(const Duration(days: 3)),
        team1: const Team(
          id: 't_sa',
          name: 'South Africa',
          shortName: 'SA',
          flagUrl: '🇿🇦',
        ),
        team2: const Team(
          id: 't_pak',
          name: 'Pakistan',
          shortName: 'PAK',
          flagUrl: '🇵🇰',
        ),
      ),
      CricketMatch(
        id: 'up_4',
        title: 'Match 47 - DC vs SRH',
        seriesName: 'Indian Premier League 2026',
        venue: 'Arun Jaitley Stadium, Delhi',
        status: MatchStatus.upcoming,
        format: MatchFormat.ipl,
        startTime: DateTime.now().add(const Duration(hours: 50)),
        team1: const Team(
          id: 't_dc',
          name: 'Delhi Capitals',
          shortName: 'DC',
          flagUrl: 'https://static.cricketlineguru.com/dc.png',
        ),
        team2: const Team(
          id: 't_srh',
          name: 'Sunrisers Hyderabad',
          shortName: 'SRH',
          flagUrl: 'https://static.cricketlineguru.com/srh.png',
        ),
      ),
    ];
  }

  // ─── Recent Matches ──────────────────────────────────────
  @override
  Future<List<CricketMatch>> getRecentMatches() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      CricketMatch(
        id: 'rec_1',
        title: '1st T20I',
        seriesName: 'India Tour of Australia, 2026',
        venue: 'Adelaide Oval',
        status: MatchStatus.completed,
        format: MatchFormat.t20i,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        team1: const Team(
          id: 't_ind',
          name: 'India',
          shortName: 'IND',
          flagUrl: '🇮🇳',
          score: '212/3',
          overs: '20.0',
        ),
        team2: const Team(
          id: 't_aus',
          name: 'Australia',
          shortName: 'AUS',
          flagUrl: '🇦🇺',
          score: '195/8',
          overs: '20.0',
        ),
        result: 'India won by 17 runs',
      ),
      CricketMatch(
        id: 'rec_2',
        title: 'Match 44 - GT vs LSG',
        seriesName: 'Indian Premier League 2026',
        venue: 'Narendra Modi Stadium, Ahmedabad',
        status: MatchStatus.completed,
        format: MatchFormat.ipl,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        team1: const Team(
          id: 't_gt',
          name: 'Gujarat Titans',
          shortName: 'GT',
          flagUrl: 'https://static.cricketlineguru.com/gt.png',
          score: '186/5',
          overs: '20.0',
        ),
        team2: const Team(
          id: 't_lsg',
          name: 'Lucknow Super Giants',
          shortName: 'LSG',
          flagUrl: 'https://static.cricketlineguru.com/lsg.png',
          score: '171/9',
          overs: '20.0',
        ),
        result: 'GT won by 15 runs',
      ),
      CricketMatch(
        id: 'rec_3',
        title: '2nd T20I',
        seriesName: 'India Tour of Australia, 2026',
        venue: 'Brisbane Cricket Ground',
        status: MatchStatus.completed,
        format: MatchFormat.t20i,
        startTime: DateTime.now().subtract(const Duration(days: 3)),
        team1: const Team(
          id: 't_aus',
          name: 'Australia',
          shortName: 'AUS',
          flagUrl: '🇦🇺',
          score: '189/7',
          overs: '20.0',
        ),
        team2: const Team(
          id: 't_ind',
          name: 'India',
          shortName: 'IND',
          flagUrl: '🇮🇳',
          score: '190/4',
          overs: '19.2',
        ),
        result: 'India won by 6 wickets',
      ),
    ];
  }

  // ─── Match Detail ────────────────────────────────────────
  @override
  Future<MatchDetail> getMatchDetail(String matchId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final matches = [
      ...await getLiveMatches(),
      ...await getUpcomingMatches(),
      ...await getRecentMatches(),
    ];
    final match = matches.firstWhere(
      (m) => m.id == matchId,
      orElse: () => matches.first,
    );

    return MatchDetail(
      match: match,
      innings: [
        Innings(
          teamName: match.team1.name,
          teamShortName: match.team1.shortName,
          runs: 287,
          wickets: 4,
          overs: 72.3,
          runRate: 3.96,
          batsmen: const [
            BatsmanScore(
              name: 'Rohit Sharma',
              runs: 78,
              balls: 115,
              fours: 9,
              sixes: 2,
              strikeRate: 67.8,
              dismissal: 'c Smith b Starc',
            ),
            BatsmanScore(
              name: 'Shubman Gill',
              runs: 62,
              balls: 98,
              fours: 7,
              sixes: 1,
              strikeRate: 63.2,
              dismissal: 'lbw b Cummins',
            ),
            BatsmanScore(
              name: 'Virat Kohli',
              runs: 89,
              balls: 142,
              fours: 10,
              sixes: 1,
              strikeRate: 62.6,
              isBatting: true,
            ),
            BatsmanScore(
              name: 'KL Rahul',
              runs: 34,
              balls: 67,
              fours: 4,
              sixes: 0,
              strikeRate: 50.7,
              dismissal: 'c Carey b Hazlewood',
            ),
            BatsmanScore(
              name: 'Rishabh Pant',
              runs: 12,
              balls: 18,
              fours: 2,
              sixes: 0,
              strikeRate: 66.6,
              isBatting: true,
            ),
          ],
          bowlers: const [
            BowlerFigure(
              name: 'Pat Cummins',
              overs: 18,
              maidens: 4,
              runs: 52,
              wickets: 1,
              economy: 2.88,
            ),
            BowlerFigure(
              name: 'Mitchell Starc',
              overs: 16,
              maidens: 2,
              runs: 68,
              wickets: 1,
              economy: 4.25,
            ),
            BowlerFigure(
              name: 'Josh Hazlewood',
              overs: 15,
              maidens: 3,
              runs: 48,
              wickets: 1,
              economy: 3.20,
            ),
            BowlerFigure(
              name: 'Nathan Lyon',
              overs: 20.3,
              maidens: 5,
              runs: 78,
              wickets: 1,
              economy: 3.80,
            ),
          ],
        ),
        const Innings(
          teamName: 'Australia',
          teamShortName: 'AUS',
          runs: 263,
          wickets: 10,
          overs: 89.2,
          runRate: 2.94,
          batsmen: [
            BatsmanScore(
              name: 'Usman Khawaja',
              runs: 47,
              balls: 112,
              fours: 5,
              sixes: 0,
              strikeRate: 41.9,
              dismissal: 'c Pant b Bumrah',
            ),
            BatsmanScore(
              name: 'Steve Smith',
              runs: 91,
              balls: 186,
              fours: 11,
              sixes: 0,
              strikeRate: 48.9,
              dismissal: 'c Gill b Ashwin',
            ),
            BatsmanScore(
              name: 'Marnus Labuschagne',
              runs: 38,
              balls: 89,
              fours: 4,
              sixes: 0,
              strikeRate: 42.6,
              dismissal: 'lbw b Jadeja',
            ),
            BatsmanScore(
              name: 'Travis Head',
              runs: 42,
              balls: 61,
              fours: 6,
              sixes: 1,
              strikeRate: 68.8,
              dismissal: 'c Kohli b Bumrah',
            ),
          ],
          bowlers: [
            BowlerFigure(
              name: 'Jasprit Bumrah',
              overs: 24,
              maidens: 8,
              runs: 48,
              wickets: 4,
              economy: 2.0,
            ),
            BowlerFigure(
              name: 'Mohammed Siraj',
              overs: 20,
              maidens: 3,
              runs: 72,
              wickets: 2,
              economy: 3.6,
            ),
            BowlerFigure(
              name: 'R Ashwin',
              overs: 28,
              maidens: 7,
              runs: 82,
              wickets: 2,
              economy: 2.92,
            ),
            BowlerFigure(
              name: 'Ravindra Jadeja',
              overs: 17.2,
              maidens: 4,
              runs: 51,
              wickets: 2,
              economy: 2.94,
            ),
          ],
        ),
      ],
      commentary: _generateCommentary(),
      stats: const MatchStats(
        totalFours: 48,
        totalSixes: 4,
        totalDotBalls: 256,
        highestRunRate: 4.25,
        highestScore: '91 - Steve Smith',
        bestBowling: '4/48 - Jasprit Bumrah',
      ),
    );
  }

  List<BallCommentary> _generateCommentary() {
    return const [
      BallCommentary(
        overNumber: 72,
        ballNumber: 3,
        runs: 0,
        commentary:
            'Bumrah to Kohli, no run, defended back to the bowler. Solid defense.',
        batsman: 'Virat Kohli',
        bowler: 'Jasprit Bumrah',
      ),
      BallCommentary(
        overNumber: 72,
        ballNumber: 2,
        runs: 4,
        isFour: true,
        commentary:
            'Lyon to Kohli, FOUR! Brilliant cover drive, races to the boundary. Classic Kohli!',
        batsman: 'Virat Kohli',
        bowler: 'Nathan Lyon',
      ),
      BallCommentary(
        overNumber: 72,
        ballNumber: 1,
        runs: 1,
        commentary: 'Lyon to Pant, single to mid-on. Pant gets off strike.',
        batsman: 'Rishabh Pant',
        bowler: 'Nathan Lyon',
      ),
      BallCommentary(
        overNumber: 71,
        ballNumber: 6,
        runs: 0,
        commentary:
            'Cummins to Kohli, no run, outside off, left alone. Good judgment.',
        batsman: 'Virat Kohli',
        bowler: 'Pat Cummins',
      ),
      BallCommentary(
        overNumber: 71,
        ballNumber: 5,
        runs: 6,
        isSix: true,
        commentary:
            'Cummins to Pant, SIX! Scooped over fine leg! Audacious shot from Pant!',
        batsman: 'Rishabh Pant',
        bowler: 'Pat Cummins',
      ),
      BallCommentary(
        overNumber: 71,
        ballNumber: 4,
        runs: 0,
        commentary:
            'Cummins to Pant, dot, bouncer, ducked under. Great battle here.',
        batsman: 'Rishabh Pant',
        bowler: 'Pat Cummins',
      ),
      BallCommentary(
        overNumber: 71,
        ballNumber: 3,
        runs: 1,
        commentary: 'Cummins to Kohli, pushed to mid-off for a single.',
        batsman: 'Virat Kohli',
        bowler: 'Pat Cummins',
      ),
      BallCommentary(
        overNumber: 71,
        ballNumber: 2,
        runs: 0,
        commentary:
            'Cummins to Kohli, dot, good length outside off. Left alone.',
        batsman: 'Virat Kohli',
        bowler: 'Pat Cummins',
      ),
      BallCommentary(
        overNumber: 71,
        ballNumber: 1,
        runs: 4,
        isFour: true,
        commentary:
            'Cummins to Kohli, FOUR! Punched through covers, beautiful timing!',
        batsman: 'Virat Kohli',
        bowler: 'Pat Cummins',
      ),
      BallCommentary(
        overNumber: 70,
        ballNumber: 6,
        runs: 1,
        commentary: 'Lyon to Pant, driven to long-on for a single.',
        batsman: 'Rishabh Pant',
        bowler: 'Nathan Lyon',
      ),
    ];
  }

  @override
  Future<List<BallCommentary>> getCommentary(String matchId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateCommentary();
  }

  // ─── Live Score Stream ───────────────────────────────────

  @override
  Stream<CricketMatch> getLiveScoreStream(String matchId) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 15));
      final matches = await getLiveMatches();
      try {
        yield matches.firstWhere((m) => m.id == matchId);
      } catch (_) {
        yield matches.first;
      }
    }
  }

  // ─── Teams & Players ────────────────────────────────────
  @override
  Future<List<CricketTeam>> getTeams() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return CricketTeam.internationalTeams;
  }

  @override
  Future<List<Player>> getTeamPlayers(String teamSlug, String teamId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockPlayers;
  }

  // ─── Series ──────────────────────────────────────────────
  @override
  Future<List<Series>> getSeries() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockSeries;
  }

  @override
  Future<Series> getSeriesDetail(String seriesId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockSeries.firstWhere(
      (s) => s.id == seriesId,
      orElse: () => _mockSeries.first,
    );
  }

  @override
  Future<Player> getPlayerDetail(String id, String slug) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockPlayers.firstWhere(
      (p) => p.id == id,
      orElse: () => _mockPlayers.first,
    );
  }

  // ─── Mock Data ──────────────────────────────────────────
  static final List<Player> _mockPlayers = [
    Player(
      id: 'p_virat',
      name: 'Virat Kohli',
      slug: 'virat-kohli',
      country: 'India',
      imageUrl:
          'https://img1.hscicdn.com/image/upload/f_auto,t_ds_square_w_320/lsci/db/PICTURES/CMS/316600/316605.png',
      role: 'Batsman',
      battingStyle: 'Right Handed Bat',
      bowlingStyle: 'Right Arm Medium',
      bio:
          'Virat Kohli is an Indian international cricketer and former captain of the Indian national team. He is widely regarded as one of the greatest batsmen of all time.',
      born: 'Nov 05, 1988 (37 years)',
      height: '5 ft 9 in',
      dateOfBirth: DateTime(1988, 11, 5),
      teams: const ['India', 'Royal Challengers Bengaluru', 'Delhi'],
      battingStats: {
        'ODI': const PlayerStats(
          matches: 292,
          innings: 283,
          runs: 13848,
          notOuts: 42,
          highestScore: 183,
          average: 57.45,
          strikeRate: 93.25,
          hundreds: 50,
          fifties: 72,
          fours: 1245,
          sixes: 258,
        ),
      },
      bowlingStats: {
        'ODI': const PlayerStats(
          wickets: 4,
          bowlingAverage: 166.25,
          economy: 5.35,
          bestBowling: '1/15',
        ),
      },
      recentPerformances: const [
        RecentPerformance(
          matchTitle: '1st Test vs AUS',
          against: 'Australia',
          runs: '89*',
          wickets: '-',
          date: 'Today',
        ),
        RecentPerformance(
          matchTitle: '1st T20I vs AUS',
          against: 'Australia',
          runs: '72',
          wickets: '-',
          date: 'Yesterday',
        ),
        RecentPerformance(
          matchTitle: '3rd ODI vs ENG',
          against: 'England',
          runs: '116',
          wickets: '-',
          date: '5 days ago',
        ),
      ],
    ),
    Player(
      id: 'p_rohit',
      name: 'Rohit Sharma',
      slug: 'rohit-sharma',
      country: 'India',
      imageUrl:
          'https://img1.hscicdn.com/image/upload/f_auto,t_ds_square_w_320/lsci/db/PICTURES/CMS/316500/316584.png',
      role: 'Batsman',
      battingStyle: 'Right Handed Bat',
      bowlingStyle: 'Right Arm Off Break',
      bio:
          'Rohit Gurunath Sharma is an Indian international cricketer and the current captain of the Indian national cricket team in all formats.',
      born: 'Apr 30, 1987 (38 years)',
      height: '5 ft 8 in',
      dateOfBirth: DateTime(1987, 4, 30),
      teams: const ['India', 'Mumbai Indians'],
      battingStats: {
        'ODI': const PlayerStats(
          matches: 264,
          innings: 256,
          runs: 10709,
          notOuts: 18,
          highestScore: 264,
          average: 43.26,
          strikeRate: 90.55,
          hundreds: 31,
          fifties: 55,
          fours: 1048,
          sixes: 312,
        ),
      },
      recentPerformances: const [
        RecentPerformance(
          matchTitle: '1st Test vs AUS',
          against: 'Australia',
          runs: '78',
          wickets: '-',
          date: 'Today',
        ),
        RecentPerformance(
          matchTitle: '1st T20I vs AUS',
          against: 'Australia',
          runs: '45',
          wickets: '-',
          date: 'Yesterday',
        ),
      ],
    ),
    Player(
      id: 'p_bumrah',
      name: 'Jasprit Bumrah',
      slug: 'jasprit-bumrah',
      country: 'India',
      imageUrl:
          'https://img1.hscicdn.com/image/upload/f_auto,t_ds_square_w_320/lsci/db/PICTURES/CMS/316400/316484.png',
      role: 'Bowler',
      battingStyle: 'Right Handed Bat',
      bowlingStyle: 'Right Arm Fast',
      bio:
          'Jasprit Jasbirsingh Bumrah is an Indian international cricketer who plays for the Indian cricket team in all formats of the game.',
      born: 'Dec 06, 1993 (32 years)',
      height: '5 ft 10 in',
      dateOfBirth: DateTime(1993, 12, 6),
      teams: const ['India', 'Mumbai Indians'],
      bowlingStats: {
        'Test': const PlayerStats(
          matches: 36,
          innings: 69,
          wickets: 159,
          bowlingAverage: 20.69,
          economy: 2.74,
          bestBowling: '6/27',
          fiveWickets: 10,
        ),
      },
      battingStats: {
        'Test': const PlayerStats(
          matches: 36,
          runs: 212,
          highestScore: 34,
          average: 6.42,
        ),
      },
      recentPerformances: const [
        RecentPerformance(
          matchTitle: '1st Test vs AUS',
          against: 'Australia',
          runs: '12',
          wickets: '4/48',
          date: 'Today',
        ),
      ],
    ),
    Player(
      id: 'p_gill',
      name: 'Shubman Gill',
      slug: 'shubman-gill',
      country: 'India',
      imageUrl:
          'https://img1.hscicdn.com/image/upload/f_auto,t_ds_square_w_320/lsci/db/PICTURES/CMS/322600/322611.png',
      role: 'Batsman',
      battingStyle: 'Right Handed Bat',
      bowlingStyle: 'Right Arm Off Break',
      bio:
          'Shubman Gill is an Indian international cricketer who plays for the Indian cricket team in all formats of the game.',
      born: 'Sep 08, 1999 (26 years)',
      height: '5 ft 10 in',
      dateOfBirth: DateTime(1999, 9, 8),
      teams: const ['India', 'Gujarat Titans'],
      battingStats: {
        'ODI': const PlayerStats(
          matches: 68,
          innings: 65,
          runs: 3124,
          notOuts: 5,
          highestScore: 128,
          average: 52.06,
          strikeRate: 88.74,
          hundreds: 8,
          fifties: 17,
          fours: 342,
          sixes: 58,
        ),
      },
    ),
    Player(
      id: 'p_pant',
      name: 'Rishabh Pant',
      slug: 'rishabh-pant',
      country: 'India',
      imageUrl:
          'https://img1.hscicdn.com/image/upload/f_auto,t_ds_square_w_320/lsci/db/PICTURES/CMS/322600/322613.png',
      role: 'Wicket-keeper',
      battingStyle: 'Left Handed Bat',
      bowlingStyle: '',
      bio:
          'Rishabh Rajendra Pant is an Indian international cricketer who plays for the Indian cricket team as a wicket-keeper batsman.',
      born: 'Oct 04, 1997 (28 years)',
      height: '5 ft 7 in',
      dateOfBirth: DateTime(1997, 10, 4),
      teams: const ['India', 'Delhi Capitals'],
      battingStats: {
        'Test': const PlayerStats(
          matches: 33,
          innings: 56,
          runs: 2271,
          notOuts: 4,
          highestScore: 159,
          average: 43.67,
          strikeRate: 73.63,
          hundreds: 5,
          fifties: 11,
          fours: 254,
          sixes: 55,
        ),
      },
    ),
    Player(
      id: 'p_smith',
      name: 'Steve Smith',
      slug: 'steve-smith',
      country: 'Australia',
      imageUrl: '',
      role: 'Batsman',
      battingStyle: 'Right Handed Bat',
      bowlingStyle: 'Right Arm Leg Break',
      bio:
          'Steven Peter Devereux Smith is an Australian international cricketer and former captain of the Australian national team.',
      born: 'Jun 02, 1989 (36 years)',
      height: '5 ft 9 in',
      dateOfBirth: DateTime(1989, 6, 2),
      teams: const ['Australia', 'New South Wales'],
      battingStats: {
        'Test': const PlayerStats(
          matches: 102,
          innings: 181,
          runs: 9320,
          notOuts: 22,
          highestScore: 239,
          average: 58.61,
          strikeRate: 53.94,
          hundreds: 32,
          fifties: 39,
        ),
      },
    ),
    Player(
      id: 'p_cummins',
      name: 'Pat Cummins',
      slug: 'pat-cummins',
      country: 'Australia',
      imageUrl: '',
      role: 'Bowler',
      battingStyle: 'Right Handed Bat',
      bowlingStyle: 'Right Arm Fast',
      bio:
          'Patrick James Cummins is an Australian international cricketer who is the current captain of the Australian Test and ODI teams.',
      born: 'May 08, 1993 (32 years)',
      height: '6 ft 3 in',
      dateOfBirth: DateTime(1993, 5, 8),
      teams: const ['Australia', 'Kolkata Knight Riders'],
      bowlingStats: {
        'Test': const PlayerStats(
          matches: 55,
          innings: 102,
          wickets: 242,
          bowlingAverage: 22.25,
          economy: 2.76,
          bestBowling: '6/23',
          fiveWickets: 9,
        ),
      },
    ),
    Player(
      id: 'p_dhoni',
      name: 'MS Dhoni',
      slug: 'ms-dhoni',
      country: 'India',
      imageUrl: '',
      role: 'Wicket-keeper',
      battingStyle: 'Right Handed Bat',
      bowlingStyle: '',
      bio:
          'Mahendra Singh Dhoni is an Indian professional cricketer who was the captain of the Indian national cricket team.',
      born: 'Jul 07, 1981 (44 years)',
      height: '5 ft 9 in',
      dateOfBirth: DateTime(1981, 7, 7),
      teams: const ['India', 'Chennai Super Kings', 'Jharkhand'],
      battingStats: {
        'ODI': const PlayerStats(
          matches: 350,
          innings: 297,
          runs: 10773,
          notOuts: 84,
          highestScore: 183,
          average: 50.57,
          strikeRate: 87.56,
          hundreds: 10,
          fifties: 73,
          fours: 826,
          sixes: 229,
        ),
      },
    ),
  ];

  static final List<Series> _mockSeries = [
    Series(
      id: 's_ipl',
      name: 'Indian Premier League 2026',
      season: '2026',
      startDate: 'Mar 22, 2026',
      endDate: 'May 28, 2026',
      type: SeriesType.ipl,
      isFeatured: true,
      teams: const [
        'MI',
        'CSK',
        'RCB',
        'KKR',
        'DC',
        'SRH',
        'GT',
        'LSG',
        'RR',
        'PBKS',
      ],
    ),
    Series(
      id: 's_indaus',
      name: 'India Tour of Australia, 2026',
      season: '2026',
      startDate: 'Jan 15, 2026',
      endDate: 'Mar 10, 2026',
      type: SeriesType.bilateral,
      isFeatured: true,
      teams: const ['IND', 'AUS'],
    ),
    Series(
      id: 's_wc',
      name: 'ICC Champions Trophy 2026',
      season: '2026',
      startDate: 'Jun 1, 2026',
      endDate: 'Jun 25, 2026',
      type: SeriesType.international,
      isFeatured: true,
      teams: const ['IND', 'AUS', 'ENG', 'PAK', 'SA', 'NZ', 'BAN', 'SL'],
    ),
    Series(
      id: 's_engind',
      name: 'England Tour of India, 2026',
      season: '2026',
      startDate: 'Feb 1, 2026',
      endDate: 'Mar 5, 2026',
      type: SeriesType.bilateral,
      teams: const ['IND', 'ENG'],
    ),
  ];
}
