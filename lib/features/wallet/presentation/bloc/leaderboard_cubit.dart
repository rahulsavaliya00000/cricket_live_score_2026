import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_live_score/features/wallet/presentation/bloc/leaderboard_state.dart';
import 'package:uuid/uuid.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final SharedPreferences prefs;
  static const String _playersKey = 'leaderboard_players';
  static const String _lastUpdateKey = 'leaderboard_last_update';

  LeaderboardCubit({required this.prefs}) : super(const LeaderboardState()) {
    _init();
  }

  void _init() {
    final playersJson = prefs.getStringList(_playersKey);
    final lastUpdateStr = prefs.getString(_lastUpdateKey);

    if (playersJson == null || playersJson.isEmpty) {
      _generateInitialPlayers();
    } else {
      final players = playersJson
          .map((e) => LeaderboardPlayer.fromJson(jsonDecode(e)))
          .toList();
      final lastUpdate = lastUpdateStr != null
          ? DateTime.parse(lastUpdateStr)
          : DateTime.now();

      emit(state.copyWith(players: players, lastGrowthUpdate: lastUpdate));
      _applyGrowth();
    }
  }

  void _generateInitialPlayers() {
    final random = Random();
    final List<LeaderboardPlayer> players = [];

    // Demographic Name Lists
    final indianMale = [
      'Arjun',
      'Rahul',
      'Vivek',
      'Aditya',
      'Sohan',
      'Amit',
      'Vikram',
      'Deepak',
      'Sanjay',
      'Rohan',
      'Karan',
      'Ishan',
      'Yash',
      'Varun',
      'Ankit',
      'Abhishek',
      'Manish',
      'Suresh',
      'Ramesh',
      'Kartik',
      'Ayush',
      'Harsh',
      'Mohit',
      'Sahil',
    ];
    final nigerianMale = [
      'Chidi',
      'Olumide',
      'Emeka',
      'Tunde',
      'Ikenna',
      'Bamidele',
      'Kelechi',
      'Uche',
      'Ayo',
      'Obinna',
      'Segun',
      'Festus',
      'Kwame',
      'Jide',
      'Seyi',
      'Kayode',
      'Femi',
      'Leke',
      'Sola',
      'Yemi',
      'Damilola',
      'Wale',
      'Kunle',
    ];
    final femaleNames = [
      'Ananya',
      'Priya',
      'Chinyere',
      'Ifeoma',
      'Zara',
      'Sana',
      'Isha',
      'Ngozi',
      'Amina',
      'Meera',
      'Riya',
      'Amara',
      'Sneha',
      'Kavya',
      'Aditi',
      'Diya',
      'Chioma',
      'Adaora',
      'Funke',
      'Abiola',
      'Sade',
      'Bisi',
      'Eniola',
    ];
    final seniorNames = [
      'Dada',
      'Babaji',
      'Nana',
      'Appa',
      'GrandPa',
      'Senior',
      'Chief',
      'Elder',
      'Guru',
      'Pandit',
      'Sardar',
      'Mazi',
      'Alhaji',
      'Otunba',
      'Oga',
    ];

    // Combine and shuffle for a random distribution
    final List<String> allPool = [
      ...indianMale,
      ...nigerianMale,
      ...femaleNames,
      ...seniorNames,
    ];
    allPool.shuffle(random);
    final Set<String> usedNames = {};

    for (int i = 0; i < 100; i++) {
      String name;
      // Try to get a name from the shuffled pool
      if (i < allPool.length) {
        name = allPool[i];
      } else {
        // Fallback if pool is exhausted (unlikely with expanded lists)
        final raw = allPool[random.nextInt(allPool.length)];
        name = '$raw ${String.fromCharCode(65 + random.nextInt(26))}';
      }

      // Ensure global uniqueness even with fallbacks
      int suffix = 1;
      final baseName = name;
      while (usedNames.contains(name)) {
        name = '$baseName ${suffix++}';
      }
      usedNames.add(name);

      final isGirl = femaleNames.contains(baseName);
      final isSenior = seniorNames.contains(baseName);

      // 70% show DP
      final hasAvatar = random.nextInt(10) < 7;
      String? avatarUrl;
      if (hasAvatar) {
        final id = random.nextInt(70);
        if (isGirl) {
          avatarUrl = 'https://i.pravatar.cc/150?u=female_$id';
        } else if (isSenior) {
          avatarUrl = 'https://i.pravatar.cc/150?u=senior_$id';
        } else {
          avatarUrl = 'https://i.pravatar.cc/150?u=male_$id';
        }
      }

      players.add(
        LeaderboardPlayer(
          id: const Uuid().v4(),
          name: name,
          coins: (random.nextDouble() * 1000).toDouble(), // 0 to 1000
          balls: random.nextInt(200),
          bats: random.nextInt(100),
          hasAvatar: hasAvatar,
          avatarUrl: avatarUrl,
          isUser: false,
        ),
      );
    }

    emit(state.copyWith(players: players, lastGrowthUpdate: DateTime.now()));
    _persist();
  }

  void _applyGrowth() {
    if (state.lastGrowthUpdate == null) return;

    final now = DateTime.now();
    final lastUpdate = state.lastGrowthUpdate ?? now;

    // Check if day has changed
    if (now.day != lastUpdate.day ||
        now.month != lastUpdate.month ||
        now.year != lastUpdate.year) {
      // Use the current date as a seed for consistent growth throughout the day
      final random = Random(now.year * 1000 + now.month * 100 + now.day);

      final updatedPlayers = state.players.map((p) {
        if (p.isUser) return p;
        // Daily significant growth simulation
        return p.copyWith(
          coins: p.coins + (random.nextDouble() * 50),
          balls: p.balls + random.nextInt(20),
          bats: p.bats + random.nextInt(10),
        );
      }).toList();

      emit(state.copyWith(players: updatedPlayers, lastGrowthUpdate: now));
      _persist();
    }
  }

  void updateUserData({
    required double coins,
    required int balls,
    required int bats,
    String? name,
    String? avatarUrl,
  }) {
    final players = List<LeaderboardPlayer>.from(state.players);
    final userIndex = players.indexWhere((p) => p.isUser);

    final updatedUser = LeaderboardPlayer(
      id: 'current_user',
      name: name ?? 'Guest',
      coins: coins,
      balls: balls,
      bats: bats,
      isUser: true,
      hasAvatar: avatarUrl != null,
      avatarUrl: avatarUrl,
    );

    if (userIndex != -1) {
      players[userIndex] = updatedUser;
    } else {
      players.add(updatedUser);
    }

    emit(state.copyWith(players: players));
    _persist();
  }

  void setFilter(LeaderboardFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  List<LeaderboardPlayer> getSortedPlayers() {
    final players = List<LeaderboardPlayer>.from(state.players);
    players.sort((a, b) {
      switch (state.filter) {
        case LeaderboardFilter.coins:
          return b.coins.compareTo(a.coins);
        case LeaderboardFilter.balls:
          return b.balls.compareTo(a.balls);
        case LeaderboardFilter.bats:
          return b.bats.compareTo(a.bats);
      }
    });
    return players;
  }

  int getUserRank() {
    final sorted = getSortedPlayers();
    return sorted.indexWhere((p) => p.isUser) + 1;
  }

  Future<void> _persist() async {
    final playersJson = state.players
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await prefs.setStringList(_playersKey, playersJson);
    if (state.lastGrowthUpdate != null) {
      await prefs.setString(
        _lastUpdateKey,
        state.lastGrowthUpdate!.toIso8601String(),
      );
    }
  }
}
