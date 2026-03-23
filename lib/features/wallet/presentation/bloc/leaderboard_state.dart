import 'package:equatable/equatable.dart';

enum LeaderboardFilter { coins, balls, bats }

class LeaderboardPlayer extends Equatable {
  final String id;
  final String name;
  final double coins; // Changed to double
  final int balls;
  final int bats;
  final bool hasAvatar;
  final String? avatarUrl;
  final bool isUser;

  const LeaderboardPlayer({
    required this.id,
    required this.name,
    required this.coins,
    required this.balls,
    required this.bats,
    this.hasAvatar = true,
    this.avatarUrl,
    this.isUser = false,
  });

  LeaderboardPlayer copyWith({double? coins, int? balls, int? bats}) {
    return LeaderboardPlayer(
      id: id,
      name: name,
      coins: coins ?? this.coins,
      balls: balls ?? this.balls,
      bats: bats ?? this.bats,
      hasAvatar: hasAvatar,
      avatarUrl: avatarUrl,
      isUser: isUser,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'coins': coins,
    'balls': balls,
    'bats': bats,
    'hasAvatar': hasAvatar,
    'avatarUrl': avatarUrl,
    'isUser': isUser,
  };

  factory LeaderboardPlayer.fromJson(Map<String, dynamic> json) =>
      LeaderboardPlayer(
        id: json['id'],
        name: json['name'],
        coins: (json['coins'] as num).toDouble(),
        balls: json['balls'],
        bats: json['bats'],
        hasAvatar: json['hasAvatar'] ?? true,
        avatarUrl: json['avatarUrl'],
        isUser: json['isUser'] ?? false,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    coins,
    balls,
    bats,
    hasAvatar,
    avatarUrl,
    isUser,
  ];
}

class LeaderboardState extends Equatable {
  final List<LeaderboardPlayer> players;
  final LeaderboardFilter filter;
  final bool isLoading;
  final DateTime? lastGrowthUpdate;

  const LeaderboardState({
    this.players = const [],
    this.filter = LeaderboardFilter.coins,
    this.isLoading = false,
    this.lastGrowthUpdate,
  });

  LeaderboardState copyWith({
    List<LeaderboardPlayer>? players,
    LeaderboardFilter? filter,
    bool? isLoading,
    DateTime? lastGrowthUpdate,
  }) {
    return LeaderboardState(
      players: players ?? this.players,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      lastGrowthUpdate: lastGrowthUpdate ?? this.lastGrowthUpdate,
    );
  }

  @override
  List<Object?> get props => [players, filter, isLoading, lastGrowthUpdate];
}
