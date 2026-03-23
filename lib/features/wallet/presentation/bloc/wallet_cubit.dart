import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricketbuzz/features/wallet/data/models/transaction_model.dart';
import 'package:cricketbuzz/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final SharedPreferences prefs;

  static const _coinsKey = 'ir_coins';
  static const _ballsKey = 'wallet_balls';
  static const _batsKey = 'wallet_bats';
  static const _txKey = 'wallet_transactions';
  static const _adsCountKey = 'ads_count';
  static const _adsDateKey = 'ads_date';
  static const _lastSpinKey = 'last_free_spin_date';
  static const _lastVisitKey = 'last_visit_timestamp';

  WalletCubit({required this.prefs}) : super(const WalletState()) {
    _loadWallet();
  }

  void _loadWallet() {
    final isNewUser = prefs.getBool('is_new_user') ?? true;

    final rawCoins = prefs.get(_coinsKey);
    double coins = 10.0;
    if (rawCoins is double) {
      coins = rawCoins;
    } else if (rawCoins is int) {
      coins = rawCoins.toDouble();
    }

    int balls = prefs.getInt(_ballsKey) ?? 2;
    int bats = prefs.getInt(_batsKey) ?? 1;

    final txJsons = prefs.getStringList(_txKey) ?? [];
    List<WalletTransaction> transactions = txJsons
        .map((e) => WalletTransaction.fromJson(jsonDecode(e)))
        .toList();

    // Welcome bonus for brand-new users
    if (isNewUser && transactions.isEmpty) {
      final now = DateTime.now();
      transactions = [
        WalletTransaction(
          id: const Uuid().v4(),
          description: 'Welcome Bonus 🎁',
          amount: 10,
          type: RewardType.coins,
          date: now,
          isCredit: true,
        ),
        WalletTransaction(
          id: const Uuid().v4(),
          description: 'Welcome Bonus 🎁',
          amount: 2,
          type: RewardType.balls,
          date: now,
          isCredit: true,
        ),
        WalletTransaction(
          id: const Uuid().v4(),
          description: 'Welcome Bonus 🎁',
          amount: 1,
          type: RewardType.bats,
          date: now,
          isCredit: true,
        ),
      ];
      prefs.setBool('is_new_user', false);
      _persistAll(coins, balls, bats, transactions);
    }

    final String? savedVisitStr = prefs.getString(_lastVisitKey);
    final now = DateTime.now();

    // Streak logic check
    if (!isNewUser && savedVisitStr != null) {
      final lastVisit = DateTime.parse(savedVisitStr);
      final difference = now.difference(lastVisit);

      // If user hasn't visited in >= 72 hours (3 days), clear wallet and break streak.
      if (difference.inHours >= 200) {
        bool streakBroken = false;

        if (coins > 0) {
          transactions.insert(
            0,
            WalletTransaction(
              id: const Uuid().v4(),
              description: 'Streak break! ⚡',
              amount: coins,
              type: RewardType.coins,
              date: now,
              isCredit: false,
            ),
          );
          coins = 0.0;
          streakBroken = true;
        }

        if (balls > 0) {
          transactions.insert(
            0,
            WalletTransaction(
              id: const Uuid().v4(),
              description: 'Streak break! ⚡',
              amount: balls.toDouble(),
              type: RewardType.balls,
              date: now,
              isCredit: false,
            ),
          );
          balls = 0;
          streakBroken = true;
        }

        if (bats > 0) {
          transactions.insert(
            0,
            WalletTransaction(
              id: const Uuid().v4(),
              description: 'Streak break! ⚡',
              amount: bats.toDouble(),
              type: RewardType.bats,
              date: now,
              isCredit: false,
            ),
          );
          bats = 0;
          streakBroken = true;
        }

        if (streakBroken) {
          _persistAll(coins, balls, bats, transactions);
        }
      }
    }

    // Update last visit timestamp
    prefs.setString(_lastVisitKey, now.toIso8601String());

    // Reset ad count if new day
    final savedDateStr = prefs.getString(_adsDateKey);
    final savedDate = savedDateStr != null
        ? DateTime.parse(savedDateStr)
        : null;
    int adsCount = prefs.getInt(_adsCountKey) ?? 0;
    if (savedDate == null || !_isSameDay(savedDate, DateTime.now())) {
      adsCount = 0;
      prefs.setInt(_adsCountKey, 0);
      prefs.setString(_adsDateKey, DateTime.now().toIso8601String());
    }

    final savedSpinDateStr = prefs.getString(_lastSpinKey);
    final savedSpinDate = savedSpinDateStr != null
        ? DateTime.parse(savedSpinDateStr)
        : null;

    emit(
      state.copyWith(
        irCoins: coins,
        balls: balls,
        bats: bats,
        transactions: transactions,
        adsWatchedToday: adsCount,
        lastAdWatchDate: savedDate,
        lastFreeSpinDate: savedSpinDate,
      ),
    );
  }

  // ── Core reward method ──────────────────────────────────────────
  Future<void> addReward({
    required double amount,
    required RewardType type,
    required String description,
    required bool isCredit,
  }) async {
    double newCoins = state.irCoins;
    int newBalls = state.balls;
    int newBats = state.bats;

    if (isCredit) {
      if (type == RewardType.coins) newCoins += amount;
      if (type == RewardType.balls) newBalls += amount.toInt();
      if (type == RewardType.bats) newBats += amount.toInt();
    } else {
      if (type == RewardType.coins) newCoins -= amount;
      if (type == RewardType.balls) newBalls -= amount.toInt();
      if (type == RewardType.bats) newBats -= amount.toInt();
    }

    final tx = WalletTransaction(
      id: const Uuid().v4(),
      description: description,
      amount: amount.toDouble(),
      type: type,
      date: DateTime.now(),
      isCredit: isCredit,
    );

    final updatedTxs = [tx, ...state.transactions];

    emit(
      state.copyWith(
        irCoins: newCoins,
        balls: newBalls,
        bats: newBats,
        transactions: updatedTxs,
      ),
    );

    await _persistAll(newCoins, newBalls, newBats, updatedTxs);
  }

  // ── Spin reward ────────────────────────────────────────────────
  Future<void> creditSpinReward({
    required double amount,
    required RewardType type,
    bool isFree = true,
  }) async {
    if (isFree) {
      await claimFreeSpin();
    }

    if (amount <= 0) return; // "Try Again" segment
    await addReward(
      amount: amount,
      type: type,
      description: 'Spin & Win 🎰',
      isCredit: true,
    );
  }

  Future<void> claimFreeSpin() async {
    final now = DateTime.now();
    emit(state.copyWith(lastFreeSpinDate: now));
    await prefs.setString(_lastSpinKey, now.toIso8601String());
  }

  // ── Watch & Earn ───────────────────────────────────────────────
  Future<bool> watchAdReward() async {
    if (state.adsWatchedToday >= 5) return false;

    final newCount = state.adsWatchedToday + 1;
    final now = DateTime.now();

    // Randomize reward based on balance
    double reward;
    final random = Random();
    if (state.irCoins < 250) {
      // Reward between 0.10 and 0.30
      final options = [0.10, 0.15, 0.20, 0.25, 0.30];
      reward = options[random.nextInt(options.length)];
    } else {
      // Reward below 0.10
      final options = [0.05, 0.06, 0.07, 0.08, 0.10];
      reward = options[random.nextInt(options.length)];
    }

    await addReward(
      amount: reward,
      type: RewardType.coins,
      description: 'Watch & Earn 📺',
      isCredit: true,
    );

    emit(state.copyWith(adsWatchedToday: newCount, lastAdWatchDate: now));
    await prefs.setInt(_adsCountKey, newCount);
    await prefs.setString(_adsDateKey, now.toIso8601String());
    return true;
  }

  // ── Persist ────────────────────────────────────────────────────
  Future<void> _persistAll(
    double coins,
    int balls,
    int bats,
    List<WalletTransaction> transactions,
  ) async {
    await prefs.setDouble(_coinsKey, coins);
    await prefs.setInt(_ballsKey, balls);
    await prefs.setInt(_batsKey, bats);
    await prefs.setStringList(
      _txKey,
      transactions.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void setSpinning(bool spinning) {
    emit(state.copyWith(isSpinning: spinning));
  }
}
