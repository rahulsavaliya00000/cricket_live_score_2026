import 'package:equatable/equatable.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';

class Series extends Equatable {
  final String id;
  final String name;
  final String season;
  final String startDate;
  final String endDate;
  final SeriesType type;
  final List<CricketMatch> matches;
  final List<PointsTableEntry> pointsTable;
  final List<String> teams;
  final bool isFeatured;

  const Series({
    required this.id,
    required this.name,
    this.season = '',
    this.startDate = '',
    this.endDate = '',
    this.type = SeriesType.international,
    this.matches = const [],
    this.pointsTable = const [],
    this.teams = const [],
    this.isFeatured = false,
  });

  @override
  List<Object?> get props => [id];
}

enum SeriesType { international, ipl, t20League, domestic, bilateral }

class PointsTableEntry extends Equatable {
  final String teamName;
  final String teamShortName;
  final int matches;
  final int won;
  final int lost;
  final int drawn;
  final int noResult;
  final int points;
  final double netRunRate;

  const PointsTableEntry({
    required this.teamName,
    required this.teamShortName,
    required this.matches,
    required this.won,
    required this.lost,
    this.drawn = 0,
    this.noResult = 0,
    required this.points,
    required this.netRunRate,
  });

  @override
  List<Object?> get props => [teamName, points];
}
