import 'package:equatable/equatable.dart';

enum MatchStatus { live, upcoming, completed }

enum MatchFormat { test, odi, t20i, t20, ipl, other }

class CricketMatch extends Equatable {
  final String id;
  final String title;
  final String seriesName;
  final String venue;
  final MatchStatus status;
  final MatchFormat format;
  final DateTime startTime;
  final Team team1;
  final Team team2;
  final String? result;
  final String? statusText;
  final bool isFeatured;

  const CricketMatch({
    required this.id,
    required this.title,
    required this.seriesName,
    required this.venue,
    required this.status,
    required this.format,
    required this.startTime,
    required this.team1,
    required this.team2,
    this.result,
    this.statusText,
    this.isFeatured = false,
  });

  @override
  List<Object?> get props => [id];
}

class Team extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final String flagUrl;
  final String? score;
  final String? overs;

  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.flagUrl = '',
    this.score,
    this.overs,
  });

  @override
  List<Object?> get props => [id];
}

class Innings extends Equatable {
  final String teamName;
  final String teamShortName;
  final int runs;
  final int wickets;
  final double overs;
  final double runRate;
  final List<BatsmanScore> batsmen;
  final List<BowlerFigure> bowlers;
  final List<FallOfWicket> fallOfWickets;

  const Innings({
    required this.teamName,
    required this.teamShortName,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.runRate,
    this.batsmen = const [],
    this.bowlers = const [],
    this.fallOfWickets = const [],
  });

  String get scoreText => '$runs/$wickets';
  String get oversText => '($overs ov)';

  @override
  List<Object?> get props => [teamName, runs, wickets, overs];
}

class BatsmanScore extends Equatable {
  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final String dismissal;
  final bool isBatting;

  const BatsmanScore({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    this.dismissal = '',
    this.isBatting = false,
  });

  @override
  List<Object?> get props => [name, runs, balls];
}

class BowlerFigure extends Equatable {
  final String name;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;

  const BowlerFigure({
    required this.name,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  @override
  List<Object?> get props => [name, overs, wickets];
}

class FallOfWicket extends Equatable {
  final int wicketNumber;
  final int runs;
  final double overs;
  final String batsman;

  const FallOfWicket({
    required this.wicketNumber,
    required this.runs,
    required this.overs,
    required this.batsman,
  });

  @override
  List<Object?> get props => [wicketNumber];
}

class BallCommentary extends Equatable {
  final double overNumber;
  final int ballNumber;
  final int runs;
  final bool isWicket;
  final bool isFour;
  final bool isSix;
  final String commentary;
  final String batsman;
  final String bowler;

  const BallCommentary({
    required this.overNumber,
    required this.ballNumber,
    required this.runs,
    this.isWicket = false,
    this.isFour = false,
    this.isSix = false,
    required this.commentary,
    required this.batsman,
    required this.bowler,
  });

  @override
  List<Object?> get props => [overNumber, ballNumber];
}

class MatchDetail extends Equatable {
  final CricketMatch match;
  final List<Innings> innings;
  final List<BallCommentary> commentary;
  final MatchStats? stats;

  const MatchDetail({
    required this.match,
    this.innings = const [],
    this.commentary = const [],
    this.stats,
  });

  @override
  List<Object?> get props => [match.id];
}

class MatchStats extends Equatable {
  final int totalFours;
  final int totalSixes;
  final int totalDotBalls;
  final double highestRunRate;
  final String highestScore;
  final String bestBowling;

  const MatchStats({
    this.totalFours = 0,
    this.totalSixes = 0,
    this.totalDotBalls = 0,
    this.highestRunRate = 0,
    this.highestScore = '',
    this.bestBowling = '',
  });

  @override
  List<Object?> get props => [totalFours, totalSixes];
}
