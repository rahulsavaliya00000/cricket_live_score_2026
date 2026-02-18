import 'package:equatable/equatable.dart';

enum MatchStatus { live, upcoming, completed }

enum MatchFormat { test, odi, t20i, t20, ipl, other }

enum MatchCategory { all, international, domestic }

extension MatchCategoryX on MatchCategory {
  String get label {
    switch (this) {
      case MatchCategory.all:
        return 'All';
      case MatchCategory.international:
        return 'International';
      case MatchCategory.domestic:
        return 'Domestic';
    }
  }

  bool matches(CricketMatch match) {
    if (this == MatchCategory.all) return true;
    final isInternational =
        match.format == MatchFormat.test ||
        match.format == MatchFormat.odi ||
        match.format == MatchFormat.t20i;
    return this == MatchCategory.international
        ? isInternational
        : !isInternational;
  }
}

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

  CricketMatch copyWith({
    String? id,
    String? title,
    String? seriesName,
    String? venue,
    MatchStatus? status,
    MatchFormat? format,
    DateTime? startTime,
    Team? team1,
    Team? team2,
    String? result,
    String? statusText,
    bool? isFeatured,
  }) {
    return CricketMatch(
      id: id ?? this.id,
      title: title ?? this.title,
      seriesName: seriesName ?? this.seriesName,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      format: format ?? this.format,
      startTime: startTime ?? this.startTime,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      result: result ?? this.result,
      statusText: statusText ?? this.statusText,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  @override
  List<Object?> get props => [id, team1.score, team2.score, statusText, result];
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

  Team copyWith({
    String? id,
    String? name,
    String? shortName,
    String? flagUrl,
    String? score,
    String? overs,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      flagUrl: flagUrl ?? this.flagUrl,
      score: score ?? this.score,
      overs: overs ?? this.overs,
    );
  }

  @override
  List<Object?> get props => [id, score, overs];
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
  final List<String> playingXI; // Legacy/Combined
  final List<String> playingXI1;
  final List<String> playingXI2;
  final MatchStats? stats;

  const MatchDetail({
    required this.match,
    this.innings = const [],
    this.commentary = const [],
    this.playingXI = const [],
    this.playingXI1 = const [],
    this.playingXI2 = const [],
    this.stats,
  });

  MatchDetail copyWith({
    CricketMatch? match,
    List<Innings>? innings,
    List<BallCommentary>? commentary,
    List<String>? playingXI,
    List<String>? playingXI1,
    List<String>? playingXI2,
    MatchStats? stats,
  }) {
    return MatchDetail(
      match: match ?? this.match,
      innings: innings ?? this.innings,
      commentary: commentary ?? this.commentary,
      playingXI: playingXI ?? this.playingXI,
      playingXI1: playingXI1 ?? this.playingXI1,
      playingXI2: playingXI2 ?? this.playingXI2,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
    match.id,
    match,
    commentary.length,
    innings.length,
  ];
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
