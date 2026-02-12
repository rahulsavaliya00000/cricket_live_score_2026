import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final String country;
  final String imageUrl;
  final String role; // Batsman, Bowler, All-rounder, Wicket-keeper
  final String battingStyle;
  final String bowlingStyle;
  final DateTime? dateOfBirth;
  final PlayerStats? battingStats;
  final PlayerStats? bowlingStats;
  final List<RecentPerformance> recentPerformances;
  final List<String> teams;

  const Player({
    required this.id,
    required this.name,
    required this.country,
    this.imageUrl = '',
    required this.role,
    this.battingStyle = '',
    this.bowlingStyle = '',
    this.dateOfBirth,
    this.battingStats,
    this.bowlingStats,
    this.recentPerformances = const [],
    this.teams = const [],
  });

  @override
  List<Object?> get props => [id];
}

class PlayerStats extends Equatable {
  final int matches;
  final int innings;
  final int runs;
  final int notOuts;
  final int highestScore;
  final double average;
  final double strikeRate;
  final int hundreds;
  final int fifties;
  final int fours;
  final int sixes;
  // Bowling
  final int wickets;
  final double bowlingAverage;
  final double economy;
  final String bestBowling;
  final int fiveWickets;

  const PlayerStats({
    this.matches = 0,
    this.innings = 0,
    this.runs = 0,
    this.notOuts = 0,
    this.highestScore = 0,
    this.average = 0,
    this.strikeRate = 0,
    this.hundreds = 0,
    this.fifties = 0,
    this.fours = 0,
    this.sixes = 0,
    this.wickets = 0,
    this.bowlingAverage = 0,
    this.economy = 0,
    this.bestBowling = '',
    this.fiveWickets = 0,
  });

  @override
  List<Object?> get props => [matches, runs, wickets];
}

class RecentPerformance extends Equatable {
  final String matchTitle;
  final String against;
  final String runs;
  final String wickets;
  final String date;

  const RecentPerformance({
    required this.matchTitle,
    required this.against,
    required this.runs,
    required this.wickets,
    required this.date,
  });

  @override
  List<Object?> get props => [matchTitle, against];
}
