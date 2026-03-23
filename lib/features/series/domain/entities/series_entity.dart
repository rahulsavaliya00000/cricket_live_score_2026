import 'package:equatable/equatable.dart';
import 'package:cricketbuzz/features/matches/domain/entities/match_entity.dart';

class Series extends Equatable {
  final String id;
  final String name;
  final String season;
  final String startDate;
  final String endDate;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final SeriesType type;
  final List<CricketMatch> matches;
  final List<String> teams;
  final bool isFeatured;
  const Series({
    required this.id,
    required this.name,
    this.season = '',
    this.startDate = '',
    this.endDate = '',
    this.startDateTime,
    this.endDateTime,
    this.type = SeriesType.international,
    this.matches = const [],
    this.teams = const [],
    this.isFeatured = false,
  });

  @override
  List<Object?> get props => [id, startDateTime, endDateTime];
}

enum SeriesType { international, ipl, t20League, domestic, bilateral, women }
